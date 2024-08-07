// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStargate, SendParam, MessagingFee, OFTReceipt } from "lib/interfaces/IStargate.sol";

// This is a library to help us interact with the Stargate contract
library StargateUtil {

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