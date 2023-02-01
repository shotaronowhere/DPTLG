// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@kleros/vea-contracts/interfaces/IFastBridgeReceiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IERC20TransferGateway.sol";

contract ERC20TransferGateway is IERC20TransferGateway{

    struct TransferData{
        uint256 amount;
        uint256 maxFee;
        address destination;
        uint32 startTime;
        uint32 feeRampup;
        uint32 nonce;
    }

    IERC20 public immutable token;
    IFastBridgeReceiver public immutable bridge;
    address public receiverGateway;
    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;
    uint256 public constant BASIS_POINTS = 10000;
    mapping(bytes32 => bool) public validTransferHashes;

    constructor(IFastBridgeReceiver _bridge, IERC20 _token) {
        bridge = _bridge;
        token = _token;
        // TODO deterministic deployment for receiver gateway
        //receiverGateway = _receiverGateway;
    }

    function setReceiverGateway(address _receiverGateway) public{
        if (receiverGateway != address(0))
            receiverGateway = _receiverGateway;
    }

    modifier onlyFromBridge() {
        require(address(bridge) == msg.sender, "Fast Bridge only.");
        _;
    }

    function transferRequest(TransferData calldata _transferData) public {
        bytes32 transferDataHash = keccak256(abi.encodePacked(
            _transferData.amount,
            _transferData.maxFee,
            _transferData.startTime,
            _transferData.destination,
            _transferData.feeRampup,
            _transferData.nonce
        ));
        require(!validTransferHashes[transferDataHash], "Nonce already spent.");
        validTransferHashes[transferDataHash] = true;

        uint256 amountPlusFee = (_transferData.maxFee * (BASIS_POINTS + CONTRACT_FEE_BASIS_POINTS)) / BASIS_POINTS;
        bool success = token.transferFrom(msg.sender, address(this), amountPlusFee);
        require(success, "Transfer Failed");
    }

    function _rewardLP(bytes32 transferDataHash, address claimer, uint256 _claimerReward) internal onlyFromBridge {
        if(validTransferHashes[transferDataHash]){
            bool success = token.transferFrom(address(this), claimer,_claimerReward);
            require(success, "Reward transfer failed.");
        }
    }

    function rewardLP(address _receiverGateway, bytes32 transferDataHash, address claimer, uint256 fee) external{
        require(_receiverGateway == receiverGateway, "Unauthorized.");
        _rewardLP(transferDataHash, claimer, fee);
    }
}
