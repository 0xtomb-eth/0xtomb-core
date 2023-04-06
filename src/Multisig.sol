// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IWillBase } from "./interfaces/IWillBase.sol";


contract Multisig  {

    event Execute();
    event Confirm(address indexed owner);
    event Revoke(address indexed owner);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction public transactions;
    uint public immutable numConfirmationsRequired;


    address[] public owners;    
    mapping(address => bool) public isOwner;
    mapping(address => bool) public hasConfirmed;

    constructor(address[] memory _owners, address _willBase, uint _numConfirmationsRequired){
        //**Checks */
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && 
            _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

        //**Effects */
        uint256 length = _owners.length;
        for(uint i = 0; i < length; ){
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            owners.push(owner);
            isOwner[owner] = true;
            unchecked {
                i++;
            }
        }

        transactions.to = _willBase;
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function confirm() external {
        //**Checks */
        require(isOwner[msg.sender], "not owner");
        require(!hasConfirmed[msg.sender], "owner has already confirmed");

        //**Effects */
        hasConfirmed[msg.sender] = true;
        transactions.numConfirmations += 1;
        emit Confirm(msg.sender);
    }

    function revoke() external {
        //**Checks */
        require(isOwner[msg.sender], "not owner");
        require(hasConfirmed[msg.sender], "owner has not confirmed");

        //**Effects */
        hasConfirmed[msg.sender] = false;
        transactions.numConfirmations -= 1;
        emit Revoke(msg.sender);

    }

    function executeWill() external {
        //**Checks */
        require(transactions.executed == false, "transaction already executed");
        require(transactions.numConfirmations >= numConfirmationsRequired, "cannot execute transaction");

        //**Effects */
        transactions.executed = true;
        
        //**Interactions */
        bytes memory _data = abi.encodeWithSignature("executeWill()");
        (bool success, ) = transactions.to.call{value: transactions.value}(_data);
        require(success, "transaction failed");
        emit Execute();
    }
 
}