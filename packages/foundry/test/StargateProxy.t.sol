// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/StargateProxy.sol";
import "../contracts/MockWETH.sol";

contract StargateProxyTest is Test {
  StargateProxy public stargateProxy;
  MockWETH public mockWETH;
  address user = vm.addr(1);
  uint256 startAmount = 10 ether;

  function setUp() public {
    
    mockWETH = new MockWETH("Mock Weth", "WETH");
    console.log("MockWeth: %s", address(mockWETH));
    address stargatePool = 0xa5A8481790BB57CF3FA0a4f24Dc28121A491447f; // Arbitrum Sepolia Native Pool
    address stargateStaking = 0xF39a1dC4018a8106b21547C84133Ea122FE2b1DB; // Arbitrum Sepolia Stargate Staking
    address lpToken = 0x211c9c0bE2abaf38EcDcf626D15660C9D3AE34c6; // Arbitrum Sepolia Stargate ETH LP Token
    address rewardToken = 0x0790be41d2f58fb8FE23eE03B33AE25E7B9436bc; // Arbitrum Sepolia Stargate Reward Token
    stargateProxy = new StargateProxy(IERC20(address(mockWETH)), "Giza WETH1", "gzETH", stargatePool, stargateStaking, lpToken, rewardToken);
    // bool sent = payable(user).send(startAmount);
    // require(sent, "Failed to send Ether");
    
    mockWETH.deposit{value: startAmount}();
    assertEq(address(mockWETH).balance, startAmount, "Setup of Weth failed.");
    mockWETH.transfer(user, startAmount);
    assertEq(mockWETH.balanceOf(user), startAmount, "Setup of Weth failed.");
    
    // //mockWETH.mint(user, startAmount);
    vm.startPrank(user);
    mockWETH.approve(address(stargateProxy), startAmount);

  }

  function test_deposit() public {
    //vm.startPrank(user);
    //mockWETH.approve(address(stargateProxy), startAmount);
    uint256 shares = stargateProxy.deposit(1 ether, user);
    assertEq(shares, 1 ether, "Share price incorrectly calculated.");
    assertEq(stargateProxy.balanceOf(user), shares, "Deposit receipt not minted.");
    //assertEq(mockWETH.balanceOf(address(stargateProxy)), 1 ether, "Deposit not in vault.");
  }

  function test_withdraw() public {
    uint256 shares = stargateProxy.deposit(1 ether, user);

    stargateProxy.withdraw(shares, user, user);
    assertEq(mockWETH.balanceOf(address(stargateProxy)), 0 ether, "Full deposit not withdrawn from contract.");
    assertEq(mockWETH.balanceOf(user), startAmount, "Full deposit not in user's wallet.");
  }
}
