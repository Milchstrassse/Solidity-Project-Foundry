pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
// import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is CodeConstants, Script {
    function run() external {
        createNewSubscriptionUsingConfig();
    }

    function createNewSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, address coordinator) = createNewSubscription(vrfcoordinator);
        return (subId, coordinator);
    }

    function createNewSubscription(address vrfcoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chain id %s", block.chainid);

        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfcoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with ID %s", subId);
        return (subId, vrfcoordinator);
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        // HelperConfig helperConfig = new HelperConfig();
        // (uint256 subId, address vrfcoordinator) = helperConfig.getConfig().subscriptionId;
        // fundSubscription(subId, vrfcoordinator);
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = (helperConfig.getConfig().subscriptionId);
        address link = helperConfig.getConfig().link;
        fundSubscription(subscriptionId, vrfcoordinator, link);
    }

    function fundSubscription(uint256 subId, address vrfcoordinator, address linkToken) public {
        console.log("Funding subscription %s", subId);
        console.log("Using vrfcoordinator %s", vrfcoordinator);
        console.log("Using linkToken %s", linkToken);
        console.log("On chain id %s", block.chainid);

        // if (block.chainid == CodeConstants.ETH_LOCAL_CHAIN_ID) {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfcoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfcoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        address mostRecentlyDeploy = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeploy);
    }

    function addConsumerUsingConfig(address mostRecentlyDeploy) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = (helperConfig.getConfig().subscriptionId);
        addConsumer(mostRecentlyDeploy, vrfcoordinator, subscriptionId);
    }

    function addConsumer(address contractToAddVrf, address vrfcoordinator, uint256 subId) public {
        console.log("Adding consumer %s", contractToAddVrf);
        console.log("Using vrfcoordinator %s", vrfcoordinator);
        console.log("On chain id %s", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfcoordinator).addConsumer(subId, contractToAddVrf);
        vm.stopBroadcast();
    }
}
