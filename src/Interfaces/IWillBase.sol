// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { WillBase } from "../WillBase.sol";

interface IWillBase {
    function setAllocation(address asset, address[] calldata beneficiaries, uint256[] calldata percentages) external;

    function setDeathValidators(address[] calldata validators, uint256 votingThreshold) external;

    function ackDeath(address addr, bool ack) external;

    function getAllocationAssets(address addr) external view returns(address[] memory assets);

    function getAllocation(address addr, address asset) external view returns (WillBase.Allocation memory allocation);

    function getValidators(address addr) external view returns (address[] memory validators);

    function getVotingThreshold(address addr) external view returns (uint256);

    function checkDeath(address addr) external view returns(bool);

    function getWillStatus(address addr) external view returns(bool);    

}