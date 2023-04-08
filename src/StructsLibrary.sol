// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

library StructsLibrary {
    struct Allocation {
        address[] beneficiaries;  // 受益人地址
        uint256[] percentages;  // 分配比例
    } 

    struct DeathAck {
        EnumerableSet.AddressSet validators;
        EnumerableMap.AddressToUintMap validatorAcks;
        uint256 VotingThreshold;
    }   

}
