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

    // for the dividend tracking
    address public creator;
    uint256 newUsersCount;
    uint256 currentDividend;
    uint256 currentValueDeposited;
    uint256 dividendPercentage = 20;
    uint256 pointMultiplier = 10e18;
    mapping(uint256 => uint256) public dividendReceived; // tokenID => dividendReceived
    mapping(uint256 => uint256) public dividends;

    // social token  tracker
    uint256 public price = 100;
    uint256 public _totalSupply = 0;
    Counters.Counter public _nftId;
    LMNToken public lmnToken;

    struct GenArtInfo {
        uint256[] dnaSequence;
        string script;
        string ipfsHash;
        bool useIpfs;
    }

    //Mapping between Enepti Token ids and their Generative Art info
    mapping(uint256 => GenArtInfo) public genArtInfos;

    //URIs used for pointing to the Generative Art image
    string internal baseURI;
    string internal baseIpfsURI;

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

    // update the dividend tracker creator provides dividends
    modifier updateDividendTracker() {
        _;
        currentDividend = currentDividend.add(1);
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

        // add token to receive next dividends
        dividendReceived[_nftId.current()] = currentDividend.add(1);
        currentValueDeposited = currentValueDeposited.add(price);

        emit SocialTokensMinted(_nftId.current());

        _nftId.increment();
        newUsersCount = newUsersCount.add(1);
        _totalSupply = _totalSupply.add(1);
    }

    function updateDna(uint256 tokenId, uint256[] memory dna) external onlyRole(DEFAULT_ADMIN_ROLE) {
        genArtInfos[tokenId].dnaSequence = dna;
    }

    function getDna(uint256 tokenId) external view returns (uint256[] memory) {
        return genArtInfos[tokenId].dnaSequence;
    }

    function updateScript(uint256 tokenId, string memory _script) public onlyRole(DEFAULT_ADMIN_ROLE) {
        genArtInfos[tokenId].script = _script;
    }

    function getScript(uint256 tokenId) public view returns (string memory) {
        return genArtInfos[tokenId].script;
    }

    function toggleUseIpfs(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        genArtInfos[tokenId].useIpfs = !genArtInfos[tokenId].useIpfs;
    }

    function isUsingIpfs(uint256 tokenId) public view returns (bool) {
        return genArtInfos[tokenId].useIpfs;
    }

    function updateBaseURI(string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function updateBaseIpfsURI(string memory _baseIpfsURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseIpfsURI = _baseIpfsURI;
    }

    function genArtTokenURI(uint256 tokenId) public view returns (string memory) {
        if (genArtInfos[tokenId].useIpfs) {
            return string(abi.encodePacked(baseIpfsURI, tokenId));
        }
        return string(abi.encodePacked(baseURI, tokenId));
    }

    /**
     * @dev Dividend amt is calculated based on the creators {dividendPercentage}
     * and recorded for the tokenHolders based on collected {LMNToken} token.
     * Remaning {LMNToken} is burned and creator is awarded with Governace Token
     */
    function retrieveLMN() public onlyRole(DEFAULT_ADMIN_ROLE) updateDividendTracker {
        // TODO: make the function timelocked
        if (_nftId.current() == newUsersCount) {
            // Creators withdraws for the first time and no users to receivers to get dividends
            lmnToken.transfer(creator, currentValueDeposited);
            // TODO: Give the creator Governance Token
            //  1) Burn token
            //  lmnToken.burn(address(this), currentValueDeposited);
            //  2) Give the creator ENP token
            return;
        }
        // give the lmn tokes as dividends
        uint256 receivers = _nftId.current().sub(newUsersCount);
        uint256 receiveableAmt = currentValueDeposited.mul(dividendPercentage).div(100);

        uint256 dividendAmt = receiveableAmt.div(receivers);
        uint256 creatorAmt = currentValueDeposited.sub(receiveableAmt);

        // add dividends to record
        dividends[currentDividend] = dividendAmt;

        // give the creator LMN
        lmnToken.transfer(creator, creatorAmt);
        // TODO: Give the creator Governance Token
        //  1) Burn token
        //  lmnToken.burn(address(this), currentValueDeposited);
        //  2) Give the creator ENP token
    }

    /**
     * @dev Grants all the dividends held by the token to the tokenOwner as LMN Tokens.
     */
    function withdrawDividends(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Only token owner can request for the token dividend request");

        uint256 tokenCurDiv = dividendReceived[_tokenId];
        for (uint256 i = tokenCurDiv; i < currentDividend; i++) {
            uint256 dividendAmt = dividends[i];
            // debug
            // console.log("paying dividend", i);
            // console.log(dividendAmt, "LMN Tokens");

            lmnToken.transfer(msg.sender, dividendAmt);
        }

        // update the received record
        dividendReceived[_tokenId] = currentDividend;
    }
}
