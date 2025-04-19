pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Fund} from "../src/Fund.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/**
 * @title FundFund
 * @notice 此合约用于向最近部署的 Fund 合约发送资金
 */
contract FundFund is Script {
    uint256 SEND_VALUE = 0.1 ether;

    /**
     * @dev 向指定地址的 Fund 合约发送资金
     * @param mostRecentlyDeployed 最近部署的 Fund 合约地址
     */
    function fundFund(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Fund(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded Fund with %s", SEND_VALUE);
    }

    /**
     * @dev 脚本的入口函数，获取最近部署的 Fund 合约地址并调用 fundFund 函数
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Fund", block.chainid);
        fundFund(mostRecentlyDeployed);
    }
}

/**
 * @title WithdrawFund
 * @notice 此合约用于从最近部署的 Fund 合约中提取资金
 */
contract WithdrawFund is Script {

    /**
     * @dev 从指定地址的 Fund 合约中提取资金
     * @param mostRecentlyDeployed 最近部署的 Fund 合约地址
     */
    function withdrawFund(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Fund(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw Fund balance!");
    }

    /**
     * @dev 脚本的入口函数，获取最近部署的 Fund 合约地址并调用 withdrawFund 函数
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Fund", block.chainid);
        withdrawFund(mostRecentlyDeployed);
    }
}