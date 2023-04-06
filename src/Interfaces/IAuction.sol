pragma solidity ^0.8.13;


interface IAuction {


    error InvalidAccess();

    
    function create(address _contract, uint256 _tokenId) external;
    function bid(address _NFTcontract, uint256 _tokenId) external payable;
    function create(address _contract, uint256 _tokenId, uint256 _amount) external;
    // function bid(address _NFTcontract, uint256 _tokenId, uint256 _amount) external payable;
}