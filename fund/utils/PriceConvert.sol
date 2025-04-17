pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceConverter
 * @notice 此库用于处理 ETH 与 USD 之间的价格转换
 * @dev 依赖于 Chainlink 的 AggregatorV3Interface 来获取价格数据
 */
library PriceConverter {
    /**
     * @notice 获取当前 ETH/USD 的价格
     * @param priceFeed AggregatorV3Interface 类型的价格预言机实例，用于获取最新的价格数据
     * @return uint256 当前 ETH/USD 的价格，以 18 位小数表示
     */
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // 调用价格预言机的 latestRoundData 方法获取最新一轮的价格数据
        // 该方法返回一个包含多个值的元组，这里只使用第二个值（即价格）
        (, int256 answer,,,) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    /**
     * @notice 将指定数量的 ETH 转换为对应的 USD 金额
     * @param ethAmount 要转换的 ETH 数量，单位为 wei
     * @param priceFeed AggregatorV3Interface 类型的价格预言机实例，用于获取最新的价格数据
     * @return uint256 转换后的 USD 金额，单位为 wei
     * @dev 此函数假设价格预言机返回的价格具有特定的小数位数，并非适用于所有的价格预言机
     */
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 计算指定数量的 ETH 对应的 USD 金额
        // 先将 ETH 价格乘以 ETH 数量，然后除以 10 的 18 次方（因为 ethAmount 单位是 wei）
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // 返回转换后的 USD 金额
        return ethAmountInUsd;
    }
}