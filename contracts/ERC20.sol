// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    uint256 public constant MAX_SUPPLY = 1000000000000000000000000;
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, MAX_SUPPLY);
    }
}