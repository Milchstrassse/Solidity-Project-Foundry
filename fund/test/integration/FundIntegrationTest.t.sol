 pragma solidity ^0.8.19;

import {Fund} from "../../src/Fund.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployFund} from "../../script/DeployFund.s.sol";
import {FundFund, WithdrawFund} from "../../script/intereaction.s.sol";

contract FundIntegrationTest is Test {
    Fund fund;

    address USER = makeAddr("Milchstrasse");
    uint256 constant BLANCE = 10 ether;
    uint256 constant SEDING_VALUE = 0.1 ether;
    uint256 GAS_PRICE = 1;

    function setUp() external { 
        DeployFund deployFund = new DeployFund();
        fund = deployFund.run();
        vm.deal(USER, BLANCE);
    }

    function testUserCanFundInteractions() public {
        console.log("Testing fund function");
        FundFund fundfund = new FundFund();
        fundfund.fundFund(address(fund));

        WithdrawFund withdraw = new WithdrawFund();
        withdraw.withdrawFund(address(fund));

        assert(address(fund).balance == 0);
    }


}