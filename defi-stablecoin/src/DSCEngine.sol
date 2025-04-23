pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * @title DSCEngine
 * @author Milchstrasse
 *
 * 该系统设计得尽可能简洁，旨在让代币始终保持 1 代币 == 1 美元的锚定汇率。
 * 这是一种具备以下特性的稳定币：
 * - 外部抵押：依靠外部资产进行抵押。
 * - 美元锚定：与美元价值挂钩。
 * - 算法稳定：通过算法来维持稳定性。
 *
 * 它类似于 DAI，但没有治理机制、不收取费用，并且仅以 WETH 和 WBTC 作为抵押。
 *
 * 我们的 DSC（去中心化稳定币）系统应始终保持“超额抵押”状态。任何时候，
 * 所有抵押品的价值都不应低于所有 DSC 所代表的美元价值。
 *
 * @notice 此合约是去中心化稳定币系统的核心。它处理铸造和赎回 DSC 以及存入和提取抵押品的所有逻辑。
 * @notice 此合约基于 MakerDAO 的 DSS 系统构建。
 */
contract DSCEngine is ReentrancyGuard {
    // Errors
    error DSCEngine__NotOwner();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMismatch();
    error DSCEngine__NotAllowToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    // modifiers
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowToken();
        }
        _;
    }

    // State Variables
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DscMinted;
    DecentralizedStableCoin private immutable i_dsc;
    address[] private s_collateralTokens;

    // events
    event DepositCollateral(address indexed user, address indexed token, uint256 amount);
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount);  // if
        // redeemFrom != redeemedTo, then it was liquidated

    // functions
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMismatch();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // external functions

    /**
     * @param tokenCollateralAddress 存入的抵押品的 ERC20 代币地址
     * @param amountCollateral 存入的抵押品数量
     * @param amountDscToMint 要铸造的 DSC 数量
     * @notice 此函数将在一个交易中存入抵押品并铸造 DSC
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit DepositCollateral(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @param tokenCollateralAddress 要提取的抵押品的 ERC20 代币地址
     * @param amountCollateral 要提取的抵押品数量
     * @param amountDscToBurn 要销毁的 DSC 数量
     * @notice 此函数将在一个交易中提取抵押品并销毁 DSC
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DscMinted[msg.sender] += amountDscToMint;
        // 检查抵押保证金是否健康
        _revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCEngine__MintFailed();
        }
    }

    /**
     * @notice 注意！你将在这里销毁你的 DSC！请确保你确实想这么做...
     * @dev 如果你担心自己可能会被清算，并且只想销毁 DSC 而保留抵押品，可以使用此函数。
     */
    function burnDsc(uint256 amountDscToBurn) public {
        _burnDsc(amountDscToBurn, msg.sender, msg.sender);   
        _revertIfHealthFactorIsBroken(msg.sender); // todo 删除代币应该不会触发到这个，可以审查是否删除用于节省代币
    }

    /**
     * @param collateral 用于使协议恢复偿付能力的抵押品的 ERC20 代币地址。这是你将从无力偿还债务的用户那里获取的抵押品。
     * @param user 无力偿还债务的用户。他们的健康因子必须低于 MIN_HEALTH_FACTOR。
     * @param debtToCover 你要销毁的 DSC 数量，以偿还用户的债务。
     *
     * @notice 你可以部分清算用户。
     * @notice 你将获得 10% 的清算奖励，以获取用户的资金。
     * @notice 此函数的正常工作假设协议大约有 150% 的超额抵押。
     * @notice 已知的一个问题是，如果协议只有 100% 的抵押，我们将无法清算任何人。例如，如果抵押品价格在任何人被清算之前暴跌。
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        isAllowedToken(collateral)
        moreThanZero(debtToCover)
        nonReentrant
    {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
       // 计算覆盖债务所需的抵押品数量
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // 给予清算者 10% 的奖励
        // 因此我们用 100 DSC 兑换价值 110 美元的 WETH 给清算者
        // 我们需要在协议资不抵债时启动清算功能
        // 并将超额资产划转到资金库
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        // 赎回抵押品
        _redeemCollateral(collateral, tokenAmountFromDebtCovered + bonusCollateral, user, msg.sender);
        // 销毁 DSC
        _burnDsc(debtToCover, user, msg.sender);

        // 获取用户的最终健康因子
        uint256 endingUserHealthFactor = _healthFactor(user);
        // 如果最终健康因子小于或等于初始健康因子，抛出错误
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        // 检查清算者的健康因子是否被破坏
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        return _getAccountInformation(user);
    }

    function getHealthFactor() external view returns (uint256) {}

    // private && internal functions
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // Add logic to check if health factor is below a certain threshold
        // and revert if necessary
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_DscMinted[onBehalfOf] -= amountDscToBurn;

        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        // This conditional is hypothetically unreachable
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    )
        private
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    // public functions
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    // 将指定数量的代币（amount）转换为对应的美元价值（以 Wei 为单位）
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // 1 ETH = 1000 USD
        // The returned value from Chainlink will be 1000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        // We want to have everything in terms of WEI, so we add 10 zeros at the end
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    // 将指定的美元金额（usdAmountInWei）转换为可购买的代币数量
    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }
}
