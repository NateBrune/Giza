//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/StargateProxy.sol";
import "../contracts/MockWETH.sol";
import "./DeployHelpers.s.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This was coded with the Arbitrum address for WETH

contract DeployScript is ScaffoldETHDeploy {
  error InvalidPrivateKey(string);

  function run() external {
    uint256 deployerPrivateKey = setupLocalhostEnv();
    if (deployerPrivateKey == 0) {
      revert InvalidPrivateKey(
        "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
      );
    }
    vm.startBroadcast(deployerPrivateKey);
    MockWETH mock = new MockWETH("Mock Weth", "WETH");
    address stargatePool = 0xa5A8481790BB57CF3FA0a4f24Dc28121A491447f; // Arbitrum Sepolia Native Pool
    address stargateStaking = 0xF39a1dC4018a8106b21547C84133Ea122FE2b1DB; // Arbitrum Sepolia Stargate Staking
    address lpToken = 0x211c9c0bE2abaf38EcDcf626D15660C9D3AE34c6; // Arbitrum Sepolia Stargate ETH LP Token
    address rewardToken = 0x0790be41d2f58fb8FE23eE03B33AE25E7B9436bc; // Arbitrum Sepolia Stargate Reward Token
    StargateProxy yourContract = new StargateProxy(IERC20(address(mock)), "Giza WETH", "gzETH", stargatePool, stargateStaking, lpToken, rewardToken);
    console.logString(
      string.concat(
        "StargateProxy deployed at: ", vm.toString(address(yourContract))
      )
    );

    vm.stopBroadcast();

    /**
     * This function generates the file containing the contracts Abi definitions.
     * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
     * This function should be called last.
     */
    exportDeployments();
  }

  function test() public { }
}
