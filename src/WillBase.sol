// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWillBase } from "./interfaces/IWillBase.sol";

contract WillBase is IWillBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    
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
    }

    function executeWill() external {
        require(!willStatuses[msg.sender]);
        for (uint256 i=0; i < userAssets[msg.sender].length(); i++) {
            address assetAddr = userAssets[msg.sender].at(i);
            uint256 balance = IERC20(assetAddr).balanceOf(msg.sender);
            Allocation storage allocation = allocations[msg.sender][assetAddr];

            for (uint256 j = 0; j < allocation.beneficiaries.length; j++) {
                address beneficiary = allocation.beneficiaries[j];
                uint256 percentage = allocation.percentages[j];
                uint256 amountToTransfer = (balance * percentage) / 100;
                
                // Transfer the tokens to beneficiaries
                IERC20(assetAddr).transferFrom(msg.sender, beneficiary, amountToTransfer);
            }
        }

        willStatuses[msg.sender] = true;
    }

    function setDeathValidators(address[] calldata validators, uint256 votingThreshold) public {
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
    }

    function ackDeath(address addr, bool ack) public {
        require(deathAck[addr].validators.contains(msg.sender));
        if (ack) {
            deathAck[addr].validatorAcks.set(msg.sender, 1);
        } else {
            deathAck[addr].validatorAcks.set(msg.sender, 0);
        }
    }

    /// view functions below ////

    function getAllocationAssets(address addr) public view returns(address[] memory assets) {
        return userAssets[addr].values();
    }

    function getAllocation(address addr, address asset) public view returns (Allocation memory allocation) {
        return allocations[addr][asset];
    }

    function getValidators(address addr) public view returns (address[] memory validators) {
        return deathAck[addr].validators.values();
    }

    function getVotingThreshold(address addr) public view returns (uint256) {
        return deathAck[addr].VotingThreshold;
    }

    function checkDeath(address addr) public view returns(bool) {
        return (deathAck[addr].VotingThreshold < deathAck[addr].validatorAcks.length());
    }

    function getWillStatus(address addr) public view returns(bool) {
        return willStatuses[addr];
    }

    function getAckStatus(address addr, address validatorAddr) public view returns(bool) {
        return (deathAck[addr].validatorAcks.get(validatorAddr) > 0);
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