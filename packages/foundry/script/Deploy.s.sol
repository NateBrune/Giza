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
    StargateProxy yourContract = new StargateProxy(IERC20(address(mock)), "Giza WETH", "gzETH");
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
