// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWETH is ERC20{
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);


    constructor (string memory _name, string memory _symbol) ERC20 (_name,_symbol){
    }

    function mint(address to, uint256 amount) public virtual {
        _mint(to,amount);
    }

    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }
    
    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit(); // This function is executed when a contract receives plain Ether (without data)
    }

    function deposit() public payable {
        mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}