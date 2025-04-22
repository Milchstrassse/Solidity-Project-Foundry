// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * @title DecentralizedStableCoin
 * @author Milchstrasse
 * 抵押资产：外部资产
 * 铸造机制（稳定机制）：去中心化（算法实现）
 * 价值（相对稳定性）：锚定（与美元挂钩）
 * 抵押资产类型：加密货币
 *
 * 此合约旨在由 DSCEngine 拥有。它是一个 ERC20 代币合约，DSCEngine 智能合约可以对其进行铸造和销毁操作。
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    // Errors
    error DSC__MustBeMoreThanZero();
    error DSC__BurnAmountExceedsBalance();
    error DSC__NotZeroAddress();

    constructor() ERC20("Decentralized Stable Coin", "DSC") {
        // constructor code

    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DSC__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DSC__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DSC__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert DSC__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }



}