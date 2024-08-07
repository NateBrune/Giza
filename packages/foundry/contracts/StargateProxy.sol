//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "interfaces/IStargatePool.sol";
import "interfaces/IStargateStaking.sol";
import "interfaces/IStargate.sol";
import "interfaces/IWeth.sol";

contract StargateProxy is ERC4626{
  // using IERC20Metadata for IERC20;
  IStargatePool public stargatePool;
  IStargateStaking public stargateStaking;
  IERC20 public lpToken;
  IERC20 public rewardToken;
  IStargate public stargate;
  constructor(
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _stargate,
    address _stargatePool,
    address _stargateStaking,
    address _lpToken,
    address _rewardToken
  ) ERC20(_name, _symbol) ERC4626(_asset) {
    stargate = IStargate(_stargate);
    stargatePool = IStargatePool(_stargatePool);
    stargateStaking = IStargateStaking(_stargateStaking);
    lpToken = IERC20(_lpToken);
    lpToken.approve(address(stargateStaking), type(uint256).max);
    rewardToken = IERC20(_rewardToken);
    
    rewardToken.approve(address(stargate), type(uint256).max);
  }
      
  fallback() external payable {
    deposit(msg.value, msg.sender);
  }

  receive() external payable {
    deposit(msg.value, msg.sender);
  }

  // Deposit into Vault
  function deposit(uint256 _amount, address _receiver) public override returns (uint256) {
    // Mint Shares
    uint256 shares = super.deposit(_amount, _receiver);
    console.log("%s minted %s shares", _receiver, shares, this.symbol());

    // Get Native Eth
    IWeth weth = IWeth(address(asset()));
    weth.withdraw(_amount);

    // Deposit into Stargate
    uint256 amountLD = stargatePool.deposit{ value: _amount }(address(this), _amount);
    console.log("Amount of LP Given from Stargate: %s", amountLD);

    // Stake LP
    stargateStaking.deposit(lpToken, amountLD);
    return shares;
  }

  // Withdraw from Vault
  function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256){ 
    // Burn Stargate staking shares
    stargateStaking.withdraw(lpToken, assets);

    // Redeem LP
    stargatePool.redeem(assets, address(this));

    // Get Native Eth
    IWeth weth = IWeth(address(asset()));
    weth.deposit{value: assets}();

    // Burn this vault's shares
    return super.withdraw(assets, receiver, owner);
  }

  // Harvest rewards from Stargate and them to 
  function harvest() public {
    stargateStaking.claim([lpToken]);

  }

  // UTILITY FUNCTIONS
  function prepareRideBus(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver
    ) external view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {
    sendParam = SendParam({
        dstEid: _dstEid,
        to: addressToBytes32(_receiver),
        amountLD: _amount,
        minAmountLD: _amount,
        extraOptions: new bytes(0),
        composeMsg: new bytes(0),
        oftCmd: new bytes(1)
    });

    IStargate stargate = IStargate(_stargate);

    (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
    sendParam.minAmountLD = receipt.amountReceivedLD;

    messagingFee = stargate.quoteSend(sendParam, false);
    valueToSend = messagingFee.nativeFee;

    if (stargate.token() == address(0x0)) {
        valueToSend += sendParam.amountLD;
    }
  }

  function prepareTakeTaxi(
      address _stargate,
      uint32 _dstEid,
      uint256 _amount,
      address _receiver
  ) external view returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) {
      sendParam = SendParam({
          dstEid: _dstEid,
          to: addressToBytes32(_receiver),
          amountLD: _amount,
          minAmountLD: _amount,
          extraOptions: new bytes(0),
          composeMsg: new bytes(0),
          oftCmd: ""
      });

      IStargate stargate = IStargate(_stargate);

      (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
      sendParam.minAmountLD = receipt.amountReceivedLD;

      messagingFee = stargate.quoteSend(sendParam, false);
      valueToSend = messagingFee.nativeFee;

      if (stargate.token() == address(0x0)) {
          valueToSend += sendParam.amountLD;
      }
  }

  function addressToBytes32(address _addr) internal pure returns (bytes32) {
      return bytes32(uint256(uint160(_addr)));
  }
}
