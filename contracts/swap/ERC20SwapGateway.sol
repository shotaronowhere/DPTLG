// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@kleros/vea-contracts/interfaces/IFastBridgeReceiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IERC20SwapGateway.sol";

contract ERC20SwapGateway is IERC20SwapGateway{

    struct TransferData{
        IERC20 token;
        uint256 amount;
        uint256 maxFee;
        address destination;
        uint32 startTime;
        uint32 feeRampup;
        uint32 nonce;
    }

    IFastBridgeReceiver public immutable bridge;
    address public immutable receiverGateway;
    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;
    uint256 public constant BASIS_POINTS = 10000;
    mapping(bytes32 => bool) public validTransferHashes;

    constructor(IFastBridgeReceiver _bridge, address _receiverGateway) payable {
        bridge = _bridge;
        receiverGateway = _receiverGateway;
    }

    modifier onlyFromBridge() {
        require(address(bridge) == msg.sender, "Fast Bridge only.");
        _;
    }

    function transferRequest(TransferData calldata _transferData) public {
        bytes32 transferDataHash = keccak256(abi.encodePacked(
            _transferData.token,
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
        bool success = _transferData.token.transferFrom(msg.sender, address(this), amountPlusFee);
        require(success, "Transfer Failed");
    }

    function _rewardLP(bytes32 transferDataHash, address token, address claimer, uint256 _claimerReward) internal onlyFromBridge {
        if(validTransferHashes[transferDataHash]){
            bool success = IERC20(token).transferFrom(address(this), claimer,_claimerReward);
            require(success, "Reward transfer failed.");
        }
    }

    function rewardLP(address _receiverGateway, bytes32 transferDataHash, address token, address claimer, uint256 fee) external{
        require(_receiverGateway == receiverGateway, "Unauthorized.");
        _rewardLP(transferDataHash, token, claimer, fee);
    }
}
