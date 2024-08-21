// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDiscreteStakingRewardsStargateEth {
    function stakingToken() external view returns (IERC20);
    function rewardToken() external view returns (IERC20);
    function isWrapped() external view returns (bool);
    function stargatePool() external view returns (address);
    function stargateStaking() external view returns (address);
    function lpToken() external view returns (IERC20);
    function reciever() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function updateRewardIndex(uint256 reward) external;
    function calculateRewardsEarned(address account) external view returns (uint256);
    function stake(uint256 amount) external payable;
    function unstake(uint256 amount) external;
    function unstakeFor(uint256 amount, address user) external;
    function claim() external returns (uint256);
}