pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
// import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    // VRF mock datas
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; // 0.25 LINK per request
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; // 1 GWEI per gas
    int256 public constant MOCK_LINK_ETH_FEED = 2000000000000000000; // 2 LINK per ETH

    uint256 public constant ETH_SEPOLIA_CHIAN_ID = 11155111;
    uint256 public constant ETH_LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    // Errors
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLine;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHIAN_ID] = getSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ETH_LOCAL_CHAIN_ID) {
            return getLocalConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getLocalConfig() internal returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_LINK_ETH_FEED);
        // MOCK_LINK_ETH_FEED
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            gasLine: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 100000,
            link: address(link)
        });
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLine: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 12345,
            callbackGasLimit: 100000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }
}
