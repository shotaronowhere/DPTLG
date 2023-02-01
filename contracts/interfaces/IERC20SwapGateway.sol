// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 cross-chain transfer vea gateway
 */
interface IERC20SwapGateway {

    function rewardLP(address receiverGateway, bytes32 transferDataHash, address token, address claimer, uint256 fee) external;

}