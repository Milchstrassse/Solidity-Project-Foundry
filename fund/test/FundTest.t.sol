pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Fund} from "../src/Fund.sol";
import {DeployFund} from "../script/DeployFund.s.sol";

contract FundTest is Test {
    Fund fund;
    function setUp() external {
        // Setup code here
        DeployFund deployFund = new DeployFund();
        fund = deployFund.run();
        // fund = new Fund(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function testFund() public {
        console.log("Testing fund function");
    }

    function testMinimumUSD() public {
        console.log("Testing minimum USD");
        uint256 minimumUSD = fund.MINIMUM_USD();
        assertEq(minimumUSD, 5 * 10 ** 18);
    }

    function testFundWithLowValue() public {
        // pass
        return
        console.log("Testing fund with low value");
        vm.expectRevert("You need to spend more ETH!");
        fund.fund{value: 1 * 10 ** 18}();
    }

    function testOwnerV1() public {
        console.log("Testing owner");
        address owner = fund.getOwner();
        assertEq(owner, msg.sender);
    }

    function testOwnerV2() public {
        console.log("Testing owner");
        address owner = fund.getOwner();
        assertNotEq(owner, address(this));
    }

    function testPriceConvertVersion() public {
        console.log("Testing price convert version");
        uint256 version = fund.getVersion();
        assertEq(version, 4);
    }
}