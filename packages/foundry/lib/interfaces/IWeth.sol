// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address form, uint amount) external;
    function deposit() external payable;
    function withdraw(uint wad) external;
}