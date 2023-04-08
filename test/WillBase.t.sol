// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { WillBase } from "../src/WillBase.sol";

contract WillBaseTest is Test {
    WillBase willbase;
    address owner = address(0x111111);
    address beneficiary1 = address(0x222222);
    address beneficiary2 = address(0x333333);
    address beneficiary3 = address(0x444444);

    address[] public beneficiaries = [beneficiary1, beneficiary2, beneficiary3];
    uint256[] public percentages = [10, 30, 60];

    function setUp() public {
        willbase = new WillBase();
    }

    function testSetAllocation() public{
        willbase.setAllocation(address(0x111), beneficiaries, percentages);
    }
}