// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@kleros/vea-contracts/interfaces/IFastBridgeReceiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/IERC20TransferGateway.sol";

contract ERC20TransferToArbitrumGateway is IERC20TransferGateway{

    struct TransferData{
        uint256 amount;
        uint256 maxFee;
        address destination;
        uint32 startTime;
        uint32 feeRampup;
        uint32 nonce;
    }

    struct TransferDataCreator{
        address creator;
        uint32 cancellationRequestTimestamp;
    }

    IERC20 public immutable token;
    IFastBridgeReceiver public immutable bridge;
    address public immutable receiverGateway;
    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant cancellation_buffer = 86400; // 1 day for censorship of calling reward() (add fastbridge epochs to be safe, not included)
    mapping(bytes32 => TransferDataCreator) public transferHashCreators; // if != address(0) then isValidTransferHash
    mapping(bytes32 => address) public cancelTransferHash;

    constructor(IFastBridgeReceiver _bridge, IERC20 _token, address _receiverGateway) payable {
        bridge = _bridge;
        token = _token;
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
        require(transferHashCreators[transferDataHash].creator == address(0), "Nonce already spent.");
        transferHashCreators[transferDataHash].creator = msg.sender;

        uint256 amountPlusFee = (_transferData.maxFee * (BASIS_POINTS + CONTRACT_FEE_BASIS_POINTS)) / BASIS_POINTS;
        bool success = token.transferFrom(msg.sender, address(this), amountPlusFee);
        require(success, "Transfer Failed");
    }

    function cancelTransferRequest(bytes32 transferDataHash) external{
        require(msg.sender == transferHashCreators[transferDataHash].creator, "Unauthorized.");
        transferHashCreators[transferDataHash].cancellationRequestTimestamp = uint32(block.timestamp);
    }

    function executeCancelTransferRequest(bytes32 transferDataHash) external{
        TransferDataCreator storage transferHashCreator = transferHashCreators[transferDataHash];
        
        uint32 cancellationRequestTimestamp = transferHashCreator.cancellationRequestTimestamp;

        require(cancellationRequestTimestamp != 0, "Invalid transfer request.");
        require(cancellationRequestTimestamp > cancellation_buffer, "Too soon.");

        transferHashCreator.creator = address(0);
        transferHashCreator.cancellationRequestTimestamp = uint32(0);
        
    }

    function _rewardLP(bytes32 transferDataHash, address claimer, uint256 _claimerReward) internal onlyFromBridge {
        if(transferHashCreators[transferDataHash].creator != address(0)){
            bool success = token.transferFrom(address(this), claimer,_claimerReward);
            require(success, "Reward transfer failed.");
        }
    }

    function rewardLP(address _receiverGateway, bytes32 _transferDataHash, address _claimer, uint256 _fee) external{
        require(_receiverGateway == receiverGateway, "Unauthorized.");
        _rewardLP(_transferDataHash, _claimer, _fee);
    }
}
