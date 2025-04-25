// pragma solidity ^0.8.19;

// import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
// import {Test, console} from "forge-std/Test.sol";
// import { StdInvariant } from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract InvariantsTest is StdInvariant, Test {
//     DecentralizedStableCoin dsc;
//     DSCEngine dsce;
//     DeployDSC deployer;
//     HelperConfig helperConfig;
//     address weth;
//     address wbtc;

//     address public user = makeAddr("Milchstrasse");
//     uint256 public constant STARTING_USER_BALANCE = 10 ether;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dsce, helperConfig) = deployer.run();
//         (, , weth, wbtc, ) =
//             helperConfig.activeNetworkConfig();
//         targetContract(address(dsce));
//     }
//     function invariant_protocolMustHaveMoreValueThatTotalSupplyDollars() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 wethDeposted = IERC20(weth).balanceOf(address(dsce));
//         uint256 wbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

//         uint256 wethValue = dsce.getUsdValue(weth, wethDeposted);
//         uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcDeposited);

//         console.log("wethValue: %s", wethValue);
//         console.log("wbtcValue: %s", wbtcValue);

//         assert(wethValue + wbtcValue >= totalSupply);
//     }
// }
