//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract StargateProxy is ERC4626{
  constructor(
    IERC20 _asset,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) ERC4626(_asset) {}
  // ERC20(_name, _symbol, IERC20Metadata(address(_asset)).decimals()) {
      
  

  function deposit(uint256 _amount, address _receiver) public override returns (uint256) {
    uint256 shares = super.deposit(_amount, _receiver);
    console.log("%s minted %s shares", _receiver, shares, this.symbol());
    return shares;
  }
}
