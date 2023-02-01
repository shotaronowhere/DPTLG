// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@kleros/vea-contracts/interfaces/IFastBridgeSender.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IERC20TransferGateway.sol";

contract ERC20LPGateway {

    struct TransferData{
        uint256 amount;
        uint256 maxFee;
        address destination;
        uint32 startTime;
        uint32 feeRampup;
        uint32 nonce;
    }

    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;
    uint256 public constant BASIS_POINTS = 10000;

    IERC20 public immutable token;
    IFastBridgeSender public immutable bridge;
    IERC20TransferGateway public immutable gateway;

    mapping(bytes32 => bool) public claimedTransferHashes;

    constructor(IFastBridgeSender _bridge, IERC20 _token, IERC20TransferGateway _gateway) {
        bridge = _bridge;
        token = _token;
        gateway = _gateway;
    }

    function claim(TransferData calldata _transferData) public{
        bytes32 transferDataHash = keccak256(abi.encodePacked(
            _transferData.amount,
            _transferData.maxFee,
            _transferData.destination,
            _transferData.startTime,
            _transferData.feeRampup,
            _transferData.nonce
        ));
        require(!claimedTransferHashes[transferDataHash], "Already claimed.");
        claimedTransferHashes[transferDataHash] = true;

        uint256 fee = getLPFee(_transferData, block.timestamp);
        uint256 total = _transferData.amount + _transferData.maxFee;
        uint256 amountPaid = total - fee;
        bool success = token.transferFrom(msg.sender, _transferData.destination, amountPaid);
        require(success, "Transfer Failed");

        bytes memory _calldata = abi.encodeWithSelector(IERC20TransferGateway.rewardLP.selector, transferDataHash, msg.sender, total);
        bridge.sendFast(address(gateway), _calldata);
    }

    function getLPFee(TransferData calldata _transferData, uint256 _currentTime) public pure returns (uint256 fee){
        if (_currentTime < _transferData.startTime)
            return 0;
        else if (_currentTime >= _transferData.startTime + _transferData.feeRampup)
            return _transferData.maxFee;
        else
            return _transferData.maxFee * (_currentTime - _transferData.startTime) / _transferData.feeRampup;
    }
}
