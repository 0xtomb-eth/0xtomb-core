

import "./interfaces/IAuction.sol";
import "./interfaces/IWillBase.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


contract Auction is IAuction, Ownable2Step {

    IWillBase public immutable willBase;
    uint256 public constant interval = 24 hours;
    uint256 public constant extension = 15 minutes;

    constructor(IWillBase _will){
        willBase = _will;
    }

    struct Auction721{
        uint256 highestBid;
        uint256 startTimestamp;
        uint256[] bids;
        address[] bidders;
    }

    mapping(address => mapping(uint256 => Auction721)) public auction721s;

    // mapping
    // address => tokenid 
    // address => tokenid 

    // struct Auction1155{

    // }

    function create(address _contract, uint256 _tokenId) external{
        if(msg.sender != address(willBase)){
            revert InvalidAccess();
        }
    }

    function bid(address _NFTcontract, uint256 _tokenId) external payable {


    }

    function create(address _contract, uint256 _tokenId, uint256 _amount) external{

        
    }

    // function bid(address _NFTcontract, uint256 _tokenId, uint256 _amount) external{
        
    // }
}