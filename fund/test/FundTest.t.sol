pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Fund} from "../src/Fund.sol";
import {DeployFund} from "../script/DeployFund.s.sol";

contract FundTest is Test {
    Fund fund;
 
    address USER = makeAddr("Milchstrasse");
    uint256 constant BLANCE = 10 ether;
    uint256 constant SEDING_VALUE = 0.1 ether;

    function setUp() external {
        // Setup code here
        DeployFund deployFund = new DeployFund();
        fund = deployFund.run();
        // fund = new Fund(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.deal(USER, BLANCE);
    }

    function testFund() public pure {
        console.log("Testing fund function");
    }

    function testMinimumUSD() public view {
        console.log("Testing minimum USD");
        uint256 minimumUSD = fund.MINIMUM_USD();
        assertEq(minimumUSD, 5 * 10 ** 18);
    }

    function testFundWithLowValue() public {
        console.log("Testing fund with low value");
        vm.expectRevert("You need to spend more ETH!");
        fund.fund();
    }

    function testOwnerV1() public view {
        console.log("Testing owner");
        address owner = fund.getOwner();
        assertEq(owner, msg.sender);
    }

    function testOwnerV2() public view {
        console.log("Testing owner");
        address owner = fund.getOwner();
        assertNotEq(owner, address(this));
    }

    function testPriceConvertVersion() public view {
        console.log("Testing price convert version");
        uint256 version = fund.getVersion();
        assertEq(version, 4);
    }

    function testFundUpdatesFundData() public {
        console.log("Testing fund updates fund data");
        vm.prank(USER);
        fund.fund{value: SEDING_VALUE}();
        uint256 fundAmount = fund.getAddressToAmountFunded(USER);
        assertEq(fundAmount, SEDING_VALUE); 
    }

    function testFundUpdatesFunders() public {
        console.log("Testing fund updates funders");
        vm.prank(USER);
        fund.fund{value: SEDING_VALUE}();
        address funder = fund.getFunder(0);
        assertEq(funder, USER);
    }

    function testFundUpdatesFundersV2() public {
        console.log("Testing fund updates funders");
        vm.prank(USER);
        fund.fund{value: SEDING_VALUE}();
        address funder = fund.getFunder(0);
        assertNotEq(funder, address(this));
    }

    function testOnlyOwnerCanWithdraw() public {
        console.log("Testing only owner can withdraw");
        vm.prank(USER);
        fund.fund{value: SEDING_VALUE}();
        vm.prank(USER);
        vm.expectRevert();
        fund.withdraw();
    }
    function testOnlyOwnerCanWithdrawV2() public {
        console.log("Testing only owner can withdraw");
        vm.prank(USER);
        fund.fund{value: SEDING_VALUE}();
        vm.prank(USER);
        vm.expectRevert();
        fund.cheaperWithdraw();
    }

    // function testWithdraw() public {
    //     console.log("Testing withdraw");
    //     vm.prank(USER);
    //     fund.fund{value: SEDING_VALUE}();
    //     uint256 fundAmount = fund.getAddressToAmountFunded(USER);
    //     assertEq(fundAmount, SEDING_VALUE); 
    //     fund.withdraw();
    //     uint256 fundAmountAfter = fund.getAddressToAmountFunded(USER);
    //     assertEq(fundAmountAfter, 0); 
    // }


}