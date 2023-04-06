// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWillBase } from "./interfaces/IWillBase.sol";

contract WillBase is IWillBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct Allocation {
        address[] beneficiaries;  // 受益人地址
        uint256[] percentages;  // 分配比例
    }

    // user address => asset address => allocation
    mapping (address => mapping (address => Allocation)) allocations;
    mapping (address => EnumerableSet.AddressSet) userAssets;

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