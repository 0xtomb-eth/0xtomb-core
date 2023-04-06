// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IWillBase {
    function setAllocation(address asset, address[] calldata beneficiaries, uint256[] calldata percentages) external;

    function executeWill() external;

}