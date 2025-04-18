pragma solidity ^0.8.19;

// 导入Chainlink的AggregatorV3Interface接口，用于获取价格数据
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "utils/PriceConvert.sol";

error Fund__NotOwner();

/**
 * @title 一个示例众筹合约
 * @author Milchstrasse
 * @notice 本合约用于创建一个示例众筹合约
 * @dev 本合约实现了价格预言机作为库来使用
 */
contract Fund {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // 定义一个修饰器，只有合约所有者才能执行被该修饰器修饰的函数
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert Fund__NotOwner();
        _;
    }

    /**
     * @notice 合约构造函数，在合约部署时调用
     * @param priceFeed 价格预言机的地址，用于初始化s_priceFeed变量
     */
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    /**
     * @notice 根据ETH/USD价格为合约进行众筹
     * @dev 调用者发送的ETH价值必须大于等于MINIMUM_USD，否则交易将被回滚
     */
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // 先清空再调用 避免重入攻击
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice 获取指定地址的众筹金额
     * @param fundingAddress 众筹者的地址
     * @return 该地址的众筹金额
     */
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}