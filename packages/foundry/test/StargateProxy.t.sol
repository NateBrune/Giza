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
    stargateProxy = new StargateProxy(IERC20(address(mockWETH)), "Giza WETH", "gzETH");
    vm.startPrank(user);
    mockWETH.mint(user, startAmount);
    mockWETH.approve(address(stargateProxy), 10 ether);

  }

  function test_deposit() public {
    stargateProxy.deposit(1 ether, vm.addr(1));
    assertEq(stargateProxy.balanceOf(user), 1 ether, "Deposit receipt not minted.");
    assertEq(mockWETH.balanceOf(address(stargateProxy)), 1 ether, "Deposit not in vault.");
  }

  function test_withdraw() public {
    stargateProxy.deposit(1 ether, vm.addr(1));
    stargateProxy.withdraw(1 ether, user, user);
    assertEq(mockWETH.balanceOf(address(stargateProxy)), 0 ether, "Full deposit not withdrawn from contract.");
    assertEq(mockWETH.balanceOf(user), startAmount, "Full deposit not in user's wallet.");
  }
}
