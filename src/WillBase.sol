// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StructsLibrary } from "./StructsLibrary.sol";
import { IWillBase } from "./interfaces/IWillBase.sol";

contract WillBase is IWillBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    event AllocationSet(
        address indexed asset,
        address[] beneficiaries,
        uint256[] percentages
    );

    event DeathValidatorsSet(
        address[] validators,
        uint256 votingThreshold
    );

    event WillExecuted(
    );

    event DeathAcknowledged(
        address validator,
        bool acknowledged
    );

    event TransferFailed(
        address indexed assetAddr,
        address indexed beneficiary,
        uint256 percentage
    );

    // asset address => allocation
    mapping (address => StructsLibrary.Allocation) allocations;
    EnumerableSet.AddressSet userAssets;
    bool willStatus;
    
    // death ack
    StructsLibrary.DeathAck deathAck;
    
    function setAllocation(address asset, address[] calldata beneficiaries, uint256[] calldata percentages) external virtual {
        _allocationValidityCheck(beneficiaries, percentages);

        StructsLibrary.Allocation storage allocation = allocations[asset];
        if (allocation.beneficiaries.length == 0) {
            userAssets.add(asset);
        }

        allocation.beneficiaries = beneficiaries;
        allocation.percentages = percentages;

        emit AllocationSet(asset, beneficiaries, percentages);
    }

    function setDeathValidators(address[] calldata validators, uint256 votingThreshold) external {
        // clear
        uint256 length = deathAck.validatorAcks.length();
        EnumerableSet.AddressSet storage _validators = deathAck.validators;
        for (uint256 i=length; i>0; i--) {
            _validators.remove(_validators.at(i));
        }

        // reset
        for (uint256 i=0; i<validators.length; ++i) {
            _validators.add(validators[i]);
        }
        deathAck.VotingThreshold = votingThreshold;
        emit DeathValidatorsSet(validators, votingThreshold);
    }

    function ackDeath(bool ack) external payable {
        require(deathAck.validators.contains(msg.sender), "Not Validator");
        require(!willStatus, "Will already executed");
        if (ack) {
            deathAck.validatorAcks.set(msg.sender, 1);
            emit DeathAcknowledged(msg.sender, true);
            if (_checkDeath()) {
                for (uint256 i=0; i < userAssets.length(); i++) {
                    address assetAddr = userAssets.at(i);
                    address[] memory beneficiaries = allocations[assetAddr].beneficiaries;
                    uint256[] memory percentages = allocations[assetAddr].percentages;
                    uint256 balance = IERC20(assetAddr).balanceOf(msg.sender);
                    for (uint256 j=0; j<beneficiaries.length; j++) {
                        try IERC20(assetAddr).transferFrom(msg.sender, beneficiaries[j], percentages[j] * balance) {
                        } catch {
                            emit TransferFailed(assetAddr, beneficiaries[j], percentages[j] * balance / 100);
                        }
                    }                
                }
                willStatus = true;
                emit WillExecuted();
            }
        } else {
            deathAck.validatorAcks.set(msg.sender, 0);
            emit DeathAcknowledged(msg.sender, false);
        }
    }

    /// view functions below ////

    function getAllocationAssets() external view returns(address[] memory assets) {
        return userAssets.values();
    }

    function getAllocation(address asset) external view returns (StructsLibrary.Allocation memory allocation) {
        return allocations[asset];
    }

    function getValidators() external view returns (address[] memory validators) {
        return deathAck.validators.values();
    }

    function getAckCount() external view returns (uint256) {
        return _getAckCount();
    }

    function getVotingThreshold() external view returns (uint256) {
        return deathAck.VotingThreshold;
    }

    function checkDeath() external view returns(bool) {
        return _checkDeath();
    }

    function getWillStatus() external view returns(bool) {
        return willStatus;
    }

    function _getAckStatus(address validatorAddr) internal view returns(bool) {
        (bool success, uint256 ack) = deathAck.validatorAcks.tryGet(validatorAddr);
        if (success) {
            return(ack > 0);
        } else {
            return false;
        }
    }

    function _checkDeath() internal view returns(bool) {
        uint256 ackCount = _getAckCount();
        return (deathAck.VotingThreshold <= ackCount);
    }

    function _allocationValidityCheck(address[] calldata beneficiaries, uint256[] calldata percentages) internal pure {
        require(beneficiaries.length == percentages.length, "Beneficiaries and percentages length mismatch");   

        uint256 sumPercentages = 0;
        for (uint256 j = 0; j < percentages.length; j++) {
            sumPercentages += percentages[j];
        }
        require(sumPercentages == 100, "Total percentages must equal 100");
    }

    function _getAckCount() internal view returns (uint256) {
        uint256 confirmedValidatorCount = 0;
        for (uint256 i = 0; i < deathAck.validators.length(); i++) {
            if (_getAckStatus(deathAck.validators.at(i))) {
                confirmedValidatorCount++;
            }
        }
        return confirmedValidatorCount;
    }
}