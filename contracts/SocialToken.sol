// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Interfaces
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./LMNToken.sol";

// debug
// import "hardhat/console.sol";

contract SocialToken is ERC721, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    mapping(bytes4 => bool) internal supportedInterfaces;

    function supportsInterface(bytes4 interfaceID) public view override(ERC721, AccessControl) returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    // for the divident tracking
    address public creator;
    uint256 newUsersCount;
    uint256 currentDivident;
    uint256 currentValueDeposited;
    uint256 dividentPercentage = 20;
    uint256 pointMultiplier = 10e18;
    mapping(uint256 => uint256) public dividentReceived; // tokenID => dividentReceived
    mapping(uint256 => uint256) public dividents;

    // social token  tracker
    uint256 public price = 100;
    uint256 public _totalSupply = 0;
    Counters.Counter public _nftId;
    LMNToken public lmnToken;

    //Mapping between Enepti Token ids and their NFT DNA sequence
    mapping(uint256 => uint256[]) public dnaSequences;

    constructor(
        LMNToken _lmnToken,
        string memory _name,
        string memory _symbol,
        address _creator
    ) ERC721(_name, _symbol) {
        lmnToken = _lmnToken;
        creator = _creator;
        _setupRole(DEFAULT_ADMIN_ROLE, _creator);

        supportedInterfaces[type(IERC721).interfaceId] = true;
        supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        supportedInterfaces[type(IAccessControl).interfaceId] = true;
    }

    event SocialTokensMinted(uint256 indexed socialTokens);

    // update the divident tracker creator provides dividents
    modifier updateDividentTracker() {
        _;
        currentDivident = currentDivident.add(1);
        newUsersCount = 0;
        currentValueDeposited = 0;
    }

    /**
     * @dev User can mint the Creator's {SocialToken} by deposting the {LMNToken}
     * Token price is based on the Creator stats on the social network
     */
    function buySocialToken(uint256 _amount) public {
        require(_amount >= price, "price is too low");
        price = (price * 1010) / 1000; // increases by 1% each time
        lmnToken.transferFrom(msg.sender, address(this), price);
        _safeMint(msg.sender, _nftId.current());

        // add token to receive next dividents
        dividentReceived[_nftId.current()] = currentDivident.add(1);
        currentValueDeposited = currentValueDeposited.add(price);

        _nftId.increment();
        newUsersCount = newUsersCount.add(1);
        _totalSupply = _totalSupply.add(1);

        // emit SocialTokensMinted(socialTokensAmount);
        // return socialTokensAmount;
    }

    function updateDna(uint256 tokenId, uint256[] memory dna) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dnaSequences[tokenId] = dna;
    }

    function getDna(uint256 tokenId) external view returns (uint256[] memory) {
        return dnaSequences[tokenId];
    }

    /**
     * @dev Divident amt is calculated based on the creators {dividentPercentage}
     * and recorded for the tokenHolders based on collected {LMNToken} token.
     * Remaning {LMNToken} is burned and creator is awarded with Governace Token
     */
    function retrieveLMN() public onlyRole(DEFAULT_ADMIN_ROLE) updateDividentTracker {
        // TODO: make the function timelocked
        if (_nftId.current() == newUsersCount) {
            // Creators withdraws for the first time and no users to receivers to get dividents
            lmnToken.transfer(creator, currentValueDeposited);
            // TODO: Give the creator Governance Token
            //  1) Burn token
            //  lmnToken.burn(address(this), currentValueDeposited);
            //  2) Give the creator ENP token
            return;
        }
        // give the lmn tokes as dividents
        uint256 receivers = _nftId.current().sub(newUsersCount);
        uint256 receiveableAmt = currentValueDeposited.mul(dividentPercentage).div(100);

        uint256 dividentAmt = receiveableAmt.div(receivers);
        uint256 creatorAmt = currentValueDeposited.sub(receiveableAmt);

        // add dividents to record
        dividents[currentDivident] = dividentAmt;

        // give the creator LMN
        lmnToken.transfer(creator, creatorAmt);
        // TODO: Give the creator Governance Token
        //  1) Burn token
        //  lmnToken.burn(address(this), currentValueDeposited);
        //  2) Give the creator ENP token
    }

    /**
     * @dev Grants all the dividents held by the token to the tokenOwner as LMN Tokens.
     */
    function withdrawDividents(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Only token owner can request for the token divident request");

        uint256 tokenCurDiv = dividentReceived[_tokenId];
        for (uint256 i = tokenCurDiv; i < currentDivident; i++) {
            uint256 dividentAmt = dividents[i];
            // debug
            // console.log("paying divident", i);
            // console.log(dividentAmt, "LMN Tokens");

            lmnToken.transfer(msg.sender, dividentAmt);
        }

        // update the received record
        dividentReceived[_tokenId] = currentDivident;
    }
}
