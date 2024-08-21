// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/DiscreteStakingRewardsStargateEth.sol";
import "../contracts/YieldComposer.sol";
import "../contracts/MockWETH.sol";
import "lib/interfaces/IWeth.sol";

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


contract DiscreteStakingRewardsStargateEthTest is Test {
    IWeth stakingToken;
    MockWETH rewardToken;
    DiscreteStakingRewardsStargateEth stakingRewards;
    YieldComposer composer;
    uint256 startAmount = 1 ether;

    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; //vm.addr(1);
    address rewardDistributor = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; //vm.addr(2);
    address immutable lzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1; // Eth Sepolia LzEndpoint

    function setUp() public {
        stakingToken = IWeth(address(new MockWETH("Mock Weth", "WETH"))); // Arbitrum Sepolia WETH
        rewardToken = new MockWETH("Reward Token", "RWD");
        
        address stargatePool = 0xa5A8481790BB57CF3FA0a4f24Dc28121A491447f; // Eth Sepolia Native Pool
        address stargateStaking = 0xF39a1dC4018a8106b21547C84133Ea122FE2b1DB; // Eth Sepolia Stargate Staking
        address lpToken = 0x211c9c0bE2abaf38EcDcf626D15660C9D3AE34c6; // Eth Sepolia Stargate ETH LP Token
        composer = new YieldComposer(lzEndpoint, lpToken);
        //rewardToken = new MockW(); // Arbitrum Sepolia Stargate Reward Token
        stakingRewards = new DiscreteStakingRewardsStargateEth(address(stakingToken), address(rewardToken), true, stargatePool, stargateStaking, lpToken, address(composer));

        //stakingToken.mint(user, 1000 * 1e18);
        rewardToken.mint(rewardDistributor, startAmount * 100);

        uint256 beforeBalance = address(stakingToken).balance;
        //vm.startPrank(user);
        stakingToken.deposit{value: startAmount}();
        uint256 afterBalance = address(stakingToken).balance;
        assertEq(afterBalance-beforeBalance, startAmount, "Setup of Weth failed.");
        stakingToken.transfer(user, startAmount);
        assertEq(stakingToken.balanceOf(user), startAmount, "Setup of Weth failed.");
        
        // // //stakingToken.mint(user, startAmount);
        vm.startPrank(user);
        stakingToken.approve(address(stakingRewards), type(uint256).max);
    }

    function testInitialization() public {
        assertEq(address(stakingRewards.stakingToken()), address(stakingToken));
        assertEq(address(stakingRewards.rewardToken()), address(rewardToken));
    }

    function testStake() public {
        uint256 _amount = 1 ether;
        vm.startPrank(user);
        stakingRewards.stake(_amount);
        vm.stopPrank();
        assertEq(stakingToken.balanceOf(user), startAmount - _amount);
        assertEq(stakingRewards.balanceOf(user), _amount);
        assertEq(stakingRewards.totalSupply(), _amount);
    }

    function testUnstake() public {
        uint256 _amount = 1 ether;
        vm.startPrank(user);
        stakingRewards.stake(_amount);
        stakingRewards.unstake(_amount/2);
        vm.stopPrank();

        assertEq(stakingRewards.balanceOf(user), _amount/2);
        assertEq(stakingRewards.totalSupply(), _amount/2);
        assertEq(stakingToken.balanceOf(user), _amount/2);
    }

    function testRewardCalculation() public {
        uint256 _amount = 1 ether;
        vm.startPrank(user);
        stakingRewards.stake(startAmount);
        vm.stopPrank();

        vm.startPrank(rewardDistributor);
        rewardToken.approve(address(stakingRewards), startAmount);
        stakingRewards.updateRewardIndex(startAmount);
        vm.stopPrank();

        uint256 rewards = stakingRewards.calculateRewardsEarned(user);
        assertEq(rewards, startAmount);
    }

    function testClaimRewards(uint256 _rewardsAdded) public {
        vm.assume(_rewardsAdded < startAmount * 100);
        vm.assume(_rewardsAdded > startAmount/10000);
        uint256 _amount = 1 ether;
        vm.startPrank(user);
        stakingRewards.stake(_amount);
        vm.stopPrank();

        vm.startPrank(rewardDistributor);
        rewardToken.approve(address(stakingRewards), _rewardsAdded);
        stakingRewards.updateRewardIndex(_rewardsAdded);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 claimed = stakingRewards.claim();
        vm.stopPrank();

        assertEq(claimed, _rewardsAdded);
        assertEq(rewardToken.balanceOf(user), _rewardsAdded);
        assertEq(stakingRewards.calculateRewardsEarned(user), 0);
    }
}