pragma solidity ^0.8.19;


/*
 * @title DSCEngine
 * @author Milchstrasse
 *
 * 该系统设计得尽可能简洁，旨在让代币始终保持 1 代币 == 1 美元的锚定汇率。
 * 这是一种具备以下特性的稳定币：
 * - 外部抵押：依靠外部资产进行抵押。
 * - 美元锚定：与美元价值挂钩。
 * - 算法稳定：通过算法来维持稳定性。
 *
 * 它类似于 DAI，但没有治理机制、不收取费用，并且仅以 WETH 和 WBTC 作为抵押。
 *
 * 我们的 DSC（去中心化稳定币）系统应始终保持“超额抵押”状态。任何时候，
 * 所有抵押品的价值都不应低于所有 DSC 所代表的美元价值。
 *
 * @notice 此合约是去中心化稳定币系统的核心。它处理铸造和赎回 DSC 以及存入和提取抵押品的所有逻辑。
 * @notice 此合约基于 MakerDAO 的 DSS 系统构建。
 */
contract DSCEngine {
    // Errors


    // State Variables


    function depositCollateralAndMintDsc() external {}

    function depositCollateral() external {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view returns (uint256) {}
}