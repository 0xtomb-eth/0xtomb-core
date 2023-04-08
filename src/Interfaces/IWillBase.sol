// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import { StructsLibrary } from "src/StructsLibrary.sol";

interface IWillBase {
    function setAllocation(address asset, address[] calldata beneficiaries, uint256[] calldata percentages) external;

    function setDeathValidators(address[] calldata validators, uint256 votingThreshold) external;

    function ackDeath(bool ack) external payable;

    function getAllocationAssets() external view returns(address[] memory assets);

    function getAllocation(address asset) external view returns (StructsLibrary.Allocation memory);

    function getValidators() external view returns (address[] memory validators);

    function getVotingThreshold() external view returns (uint256);

    function checkDeath() external view returns(bool);

    function getWillStatus() external view returns(bool);    
}