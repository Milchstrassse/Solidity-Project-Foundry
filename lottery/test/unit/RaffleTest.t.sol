pragma solidity ^0.8.19;


import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle private raffle;
    DeployRaffle private deployRaffle;
    HelperConfig private helperconfig;
    address USER = makeAddr("Milchstrasse");
    uint256 private constant STARTING_BALANCE = 10 ether;

    // Raffle variables
    uint256 private entranceFee;
    uint256 private interval;
    address private vrfCoordinator;
    bytes32 private gasLine;
    uint256 private subscriptionId;
    uint32 private callbackGasLimit;


    function setUp() external {
        deployRaffle = new DeployRaffle();
        (raffle, helperconfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLine = config.gasLine;
        subscriptionId = config.subscriptionId;
    }

    function testRaffleInit() external {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}