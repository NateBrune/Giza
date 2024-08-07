// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/DiscreteStakingRewards.sol";

contract MockERC20 is IERC20 {
    string public name = "MockERC20";
    string public symbol = "MERC20";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function mint(address account, uint256 amount) public {
        balanceOf[account] += amount;
        totalSupply += amount;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
}

contract DiscreteStakingRewardsTest is Test {
    MockERC20 stakingToken;
    MockERC20 rewardToken;
    DiscreteStakingRewards stakingRewards;

    address user = address(0x123);
    address rewardDistributor = address(0x456);

    function setUp() public {
        stakingToken = new MockERC20();
        rewardToken = new MockERC20();
        stakingRewards = new DiscreteStakingRewards(address(stakingToken), address(rewardToken));

        stakingToken.mint(user, 1000 * 1e18);
        rewardToken.mint(rewardDistributor, 1000 * 1e18);

        vm.startPrank(user);
        stakingToken.approve(address(stakingRewards), 1000 * 1e18);
        vm.stopPrank();
    }

    function testInitialization() public {
        assertEq(address(stakingRewards.stakingToken()), address(stakingToken));
        assertEq(address(stakingRewards.rewardToken()), address(rewardToken));
    }

    function testStake() public {
        vm.startPrank(user);
        stakingRewards.stake(100 * 1e18);
        vm.stopPrank();

        assertEq(stakingRewards.balanceOf(user), 100 * 1e18);
        assertEq(stakingRewards.totalSupply(), 100 * 1e18);
    }

    function testUnstake() public {
        vm.startPrank(user);
        stakingRewards.stake(100 * 1e18);
        stakingRewards.unstake(50 * 1e18);
        vm.stopPrank();

        assertEq(stakingRewards.balanceOf(user), 50 * 1e18);
        assertEq(stakingRewards.totalSupply(), 50 * 1e18);
    }

    function testRewardCalculation() public {
        vm.startPrank(user);
        stakingRewards.stake(100 * 1e18);
        vm.stopPrank();

        vm.startPrank(rewardDistributor);
        rewardToken.approve(address(stakingRewards), 100 * 1e18);
        stakingRewards.updateRewardIndex(100 * 1e18);
        vm.stopPrank();

        uint256 rewards = stakingRewards.calculateRewardsEarned(user);
        assertEq(rewards, 100 * 1e18);
    }

    function testClaimRewards() public {
        vm.startPrank(user);
        stakingRewards.stake(100 * 1e18);
        vm.stopPrank();

        vm.startPrank(rewardDistributor);
        rewardToken.approve(address(stakingRewards), 100 * 1e18);
        stakingRewards.updateRewardIndex(100 * 1e18);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 claimed = stakingRewards.claim();
        vm.stopPrank();

        assertEq(claimed, 100 * 1e18);
        assertEq(rewardToken.balanceOf(user), 100 * 1e18);
        assertEq(stakingRewards.calculateRewardsEarned(user), 0);
    }
}