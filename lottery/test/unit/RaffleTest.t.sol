pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


contract RaffleTest is Test {
    // Events
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    Raffle private raffle;
    DeployRaffle private deployRaffle;
    HelperConfig private helperconfig;
    address PLAYER = makeAddr("Milchstrasse");
    uint256 private constant STARTING_BALANCE = 10 ether;

    // Raffle variables
    uint256 private raffleEntranceFee;
    uint256 private interval;
    address private vrfCoordinator;
    bytes32 private gasLine;
    uint256 private subscriptionId;
    uint32 private callbackGasLimit;

    function setUp() external {
        deployRaffle = new DeployRaffle();
        (raffle, helperconfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();
        raffleEntranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLine = config.gasLine;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInit() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testRaffleRevertsWHenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: raffleEntranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayers(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    // /*//////////////////////////////////////////////////////////////
    //                           CHECKUPKEEP
    // //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }
    
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        // It doesnt revert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    // function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
    //     // Arrange
    //     vm.prank(PLAYER);
    //     raffle.enterRaffle{value: raffleEntranceFee}();
    //     vm.warp(block.timestamp + interval + 1);
    //     vm.roll(block.number + 1);

    //     // Act
    //     vm.recordLogs();
    //     raffle.performUpkeep(""); // emits requestId
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bytes32 requestId = entries[1].topics[1];

    //     // Assert
    //     Raffle.RaffleState raffleState = raffle.getRaffleState();
    //     requestId = raffle.getLastRequestId();
    //     assert(uint256(requestId) > 0);
    //     assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    // }

    // /*//////////////////////////////////////////////////////////////
    //                        FULFILLRANDOMWORDS
    // //////////////////////////////////////////////////////////////*/
    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // fuzz test
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeepV1(uint256 requestId) public raffleEntered skipFork {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(raffle));
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public raffleEntered skipFork {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // vm.mockCall could be used here...
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));
    }

    // function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
    //     address expectedWinner = address(1);

    //     // Arrange
    //     uint256 additionalEntrances = 3;
    //     uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

    //     for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
    //         address player = address(uint160(i));
    //         hoax(player, 1 ether); // deal 1 eth to the player
    //         raffle.enterRaffle{value: raffleEntranceFee}();
    //     }

    //     uint256 startingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 startingBalance = expectedWinner.balance;

    //     // Act
    //     vm.recordLogs();
    //     raffle.performUpkeep(""); // emits requestId
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     console2.logBytes32(entries[1].topics[1]);
    //     bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

    //     VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(uint256(requestId), address(raffle));

    //     // Assert
    //     address recentWinner = raffle.getRecentWinner();
    //     Raffle.RaffleState raffleState = raffle.getRaffleState();
    //     uint256 winnerBalance = recentWinner.balance;
    //     uint256 endingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 prize = raffleEntranceFee * (additionalEntrances + 1);

    //     assert(recentWinner == expectedWinner);
    //     assert(uint256(raffleState) == 0);
    //     assert(winnerBalance == startingBalance + prize);
    //     assert(endingTimeStamp > startingTimeStamp);
    // }
}
