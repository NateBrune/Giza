// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "lib/interfaces/IStargatePool.sol";
import "lib/interfaces/IStargateStaking.sol";
import "lib/interfaces/IStargate.sol";
import "lib/interfaces/IWeth.sol";

contract DiscreteStakingRewardsStargateEth {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    bool public immutable isWrapped;
    IStargatePool public immutable stargatePool;
    IStargateStaking public immutable stargateStaking;
    IERC20 public immutable lpToken;
    address public immutable reciever;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    uint256 private constant MULTIPLIER = 1e18;
    uint256 private rewardIndex;
    mapping(address => uint256) private rewardIndexOf;
    mapping(address => uint256) private earned;

    constructor(address _stakingToken, 
        address _rewardToken, 
        bool _isWrapped,
        address _stargatePool,
        address _stargateStaking,
        address _lpToken,
        address _reciever
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        isWrapped = _isWrapped;
        stargatePool = IStargatePool(_stargatePool);
        stargateStaking = IStargateStaking(_stargateStaking);
        lpToken = IERC20(_lpToken);
        if(isWrapped) {
            IWeth weth = IWeth(_stakingToken);
            weth.approve(address(weth), type(uint256).max);
        }
        lpToken.approve(address(stargateStaking), type(uint256).max);
        stakingToken.approve(address(stargatePool), type(uint256).max); // REVIEW
        reciever = _reciever; // Used in _unstakeFor
    }

    function updateRewardIndex(uint256 reward) external {
        rewardToken.transferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function _calculateRewards(address account)
        private
        view
        returns (uint256)
    {
        uint256 shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(address account)
        external
        view
        returns (uint256)
    {
        return earned[account] + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    receive() external payable {
        // Recieve ETH from WETH 
        return;
    }

    function _depositIntoPool(uint256 amount) private returns (uint256 amountLD) {
        if(isWrapped) {
            // Get Native Eth
            console.log("withdraw:            %s from contract: %s", amount, address(stakingToken));
            IWeth weth = IWeth(address(stakingToken));
            weth.withdraw(amount);
            require(address(this).balance >= amount, "Not enough balance");
            console.log("Balance of contract: %s", address(this).balance);
            // Deposit into Stargate
            amountLD = stargatePool.deposit{ value: amount }(address(this), amount);
            console.log("Amount of LP Given from Stargate: %s", amountLD);
        } else {
            // REVIEW: Deposit into Stargate with ERC20 (UNTESTED CODE)
            amountLD = stargatePool.deposit(address(this), amount);
        }
    }

    function _ingest(uint256 amount) private returns (uint256 amountLD){
        // Get Tokens from sender
        stakingToken.transferFrom(msg.sender, address(this), amount);

        // Deposit into Stargate
        amountLD = _depositIntoPool(amount);

        // Stake LP
        stargateStaking.deposit(lpToken, amountLD);
    }

    function _stakeFor(uint256 amount, address user) internal {
        _updateRewards(user);

        balanceOf[user] += amount;
        totalSupply += amount;

        _ingest(amount);
    }
    
    function stakeFor(uint256 amount, address user) external payable {
        require(msg.sender == reciever, "Only reciever can call this function");
        _stakeFor(amount, user);
    }

    function stake(uint256 amount) external payable {
        _stakeFor(amount, msg.sender);
    }




    function _eject(uint256 amount) private {
        // Burn Stargate staking shares
        stargateStaking.withdraw(lpToken, amount);

        // Redeem LP
        stargatePool.redeem(amount, address(this));

        if(isWrapped) {
            // Get Weth
            IWeth weth = IWeth(address(stakingToken));
            weth.deposit{value: amount}();
        }

        stakingToken.transfer(msg.sender, amount);
    }

    function _unstakeFor(uint256 amount, address user) internal {
        _updateRewards(user);

        balanceOf[user] -= amount;
        totalSupply -= amount;

        _eject(amount); // This is send to msg.sender not necessarily user
    }

    function unstake(uint256 amount) external {
        _unstakeFor(amount, msg.sender);
    }

    function unstakeFor(uint256 amount, address user) external {
        require(msg.sender == reciever, "Only reciever can call this function");
        _unstakeFor(amount, user);
    }

    /// @notice Claims the rewards from the rewarder, and sends them to the caller.
    // function claim(IERC20[] calldata lpTokens) external;
    function _updateRewardIndexNoTransfer(uint256 reward) private {
        require(totalSupply > 0, "Cannot update reward index with 0 total supply");
        require(reward > 0, "Cannot update reward index with 0 reward");
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function claim() external returns (uint256) {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = lpToken;
        uint256 balanceRewardTokenBefore = rewardToken.balanceOf(address(this));
        stargateStaking.claim(tokens);
        uint256 balanceRewardToken = rewardToken.balanceOf(address(this));
        uint256 balDiff = balanceRewardToken - balanceRewardTokenBefore;
        if(balDiff > 0) {
            _updateRewardIndexNoTransfer(balDiff);
        }
        _updateRewards(msg.sender);

        uint256 reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }

        return reward;
    }
}