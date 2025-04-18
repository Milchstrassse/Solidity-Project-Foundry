pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Fund} from "../src/Fund.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployFund is Script {
    function run() external returns (Fund) {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Fund fund = new Fund(priceFeed);
        vm.stopBroadcast();
        return fund;
    }
}