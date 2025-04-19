pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    //Errors
    error Raffle__NotEnoughETHEntered(uint256 amountEntered, uint256 minimumFee);
    error Raffle__NotEnoughTimePassed(uint256 timePassed, uint256 interval);
    error Raffle__TransferFailed();
    error Raffle_RaffleNotOpen();

    //Type Declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //State 
    uint16 private constant REQUESR_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    //Events
    event RaffleEnter(address indexed player);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLine,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        i_keyHash = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH to enter the raffle");
        //高效调用，减少string带来的gas fee
        if (msg.value >= i_enteranceFee) {
            revert Raffle__NotEnoughETHEntered(msg.value, i_enteranceFee);
        }
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle_RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert Raffle__NotEnoughTimePassed(block.timestamp - s_lastTimeStamp, i_interval);
        }
        
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory RandomWordsRequest = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUESR_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(RandomWordsRequest);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Pick a random winner from the players array
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        // Transfer the entire balance of the contract to the winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        // Reset the players array and last timestamp
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
    }

    //getter
    function getEnteranceFee() public view returns (uint256) {
        return i_enteranceFee;
    }
}
