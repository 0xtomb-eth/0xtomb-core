// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWillBase } from "./interfaces/IWillBase.sol";

contract WillBase is IWillBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    event AllocationSet(
        address indexed owner,
        address indexed asset,
        address[] beneficiaries,
        uint256[] percentages
    );

    event DeathValidatorsSet(
        address indexed owner,
        address[] validators,
        uint256 votingThreshold
    );

    event WillExecuted(
        address indexed owner
    );

    event DeathAcknowledged(
        address deadPeople,
        address validator,
        bool acknowledged
    );
    
    struct Allocation {
        address[] beneficiaries;  // 受益人地址
        uint256[] percentages;  // 分配比例
    } 

    struct DeathAck {
        EnumerableSet.AddressSet validators;
        EnumerableMap.AddressToUintMap validatorAcks;
        uint256 VotingThreshold;
    }

    // user address => asset address => allocation
    mapping (address => mapping (address => Allocation)) allocations;
    mapping (address => EnumerableSet.AddressSet) userAssets;
    mapping (address => bool) willStatuses;
    
    // death ack
    mapping (address => DeathAck) deathAck;

    function setAllocation(address asset, address[] calldata beneficiaries, uint256[] calldata percentages) external {
        _allocationValidityCheck;

        Allocation storage allocation = allocations[msg.sender][asset];
        if (allocation.beneficiaries.length == 0) {
            userAssets[msg.sender].add(asset);
        }

        allocation.beneficiaries = beneficiaries;
        allocation.percentages = percentages;

        emit AllocationSet(msg.sender, asset, beneficiaries, percentages);
    }


    function setDeathValidators(address[] calldata validators, uint256 votingThreshold) external {
        // clear
        uint256 length = deathAck[msg.sender].validatorAcks.length();
        EnumerableSet.AddressSet storage _validators = deathAck[msg.sender].validators;
        for (uint256 i=length; i>0; i--) {
            _validators.remove(_validators.at(i));
        }

        // reset
        for (uint256 i=0; i<validators.length; ++i) {
            _validators.add(validators[i]);
        }
        deathAck[msg.sender].VotingThreshold = votingThreshold;
        emit DeathValidatorsSet(msg.sender, validators, votingThreshold);
    }

    function ackDeath(address addr, bool ack) external {
        require(deathAck[addr].validators.contains(msg.sender));
        if (ack) {
            deathAck[addr].validatorAcks.set(msg.sender, 1);
            emit DeathAcknowledged(addr, msg.sender, true);
        } else {
            deathAck[addr].validatorAcks.set(msg.sender, 0);
            emit DeathAcknowledged(addr, msg.sender, false);
        }

        // 超过阈值
        if (_checkDeath(addr)) {
            for (uint256 i=0; i < userAssets[msg.sender].length(); i++) {
                address assetAddr = userAssets[msg.sender].at(i);
                uint256 balance = IERC20(assetAddr).balanceOf(msg.sender);
    
                IERC20(assetAddr).transferFrom(addr, address(this), balance);
            }
            emit WillExecuted(addr);
        }

    }

    /// view functions below ////

    function getAllocationAssets(address addr) external view returns(address[] memory assets) {
        return userAssets[addr].values();
    }

    function getAllocation(address addr, address asset) external view returns (Allocation memory allocation) {
        return allocations[addr][asset];
    }

    function getValidators(address addr) external view returns (address[] memory validators) {
        return deathAck[addr].validators.values();
    }

    function getVotingThreshold(address addr) external view returns (uint256) {
        return deathAck[addr].VotingThreshold;
    }

    function checkDeath(address addr) external view returns(bool) {
        return _checkDeath(addr);
    }

    function getWillStatus(address addr) external view returns(bool) {
        return willStatuses[addr];
    }

    function _getAckStatus(address addr, address validatorAddr) internal view returns(bool) {
        return (deathAck[addr].validatorAcks.get(validatorAddr) > 0);
    }

    function _checkDeath(address addr) internal view returns(bool) {
        return (deathAck[addr].VotingThreshold < deathAck[addr].validatorAcks.length());
    }

    function _allocationValidityCheck(address[] calldata beneficiaries, uint256[] calldata percentages) internal pure {
        require(beneficiaries.length == percentages.length, "Beneficiaries and percentages length mismatch");   

        uint256 sumPercentages = 0;
        for (uint256 j = 0; j < percentages.length; j++) {
            sumPercentages += percentages[j];
        }
        require(sumPercentages == 100, "Total percentages must equal 100");
    }

}