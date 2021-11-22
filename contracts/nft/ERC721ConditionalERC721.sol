//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Erc721ConditionalErc721 is ERC165, ERC721 {
    // Points toward the NFT contract to coniditionally mint from
    address public conditionNFT;

    mapping(uint256 => address) public owner;
    mapping(address => mapping(address => bool)) public operatorList;
    mapping(uint256 => address) public approved;
    mapping(address => uint256) public balances;
    mapping(uint256 => bool) private hasMinted;

    event Minted(uint256 tokenID, address owner);

    constructor(
        address _conditionNFT,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        conditionNFT = _conditionNFT;
    }

    function hasMintedNFT(uint256 _tokenId) public view returns (bool) {
        return hasMinted[_tokenId];
    }

    function mintNFT(uint256 _tokenId) public {
        require(ERC721(conditionNFT).ownerOf(_tokenId) == msg.sender, "Msg.sender not owner of NFT!");
        require(ERC721(conditionNFT).ownerOf(_tokenId) != address(0), "Invalid tokenId");
        require(hasMinted[_tokenId] == false, "NFT already minted for this ID!");
        emit Transfer(address(0), msg.sender, _tokenId);
        emit Minted(_tokenId, msg.sender);
        owner[_tokenId] = msg.sender;
        balances[msg.sender]++;
        hasMinted[_tokenId] = true;
    }

    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://res.cloudinary.com/enepti/image/upload/v1637461832/enepti/",
                    Strings.toString(_tokenId)
                )
            );
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return owner[_tokenId];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );

        require(_from == owner[_tokenId] && _from != address(0), "safeTransferFrom with invalid from address");

        if (isContract(_to)) {
            if (IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) == 0x150b7a02) {
                emit Transfer(_from, _to, _tokenId);
                balances[_from]--;
                balances[_to]++;
                approved[_tokenId] = address(0);
                owner[_tokenId] = _to;
            } else {
                revert("receiving address unable to hold ERC721!");
            }
        } else {
            emit Transfer(_from, _to, _tokenId);
            balances[_from]--;
            balances[_to]++;
            approved[_tokenId] = address(0);
            owner[_tokenId] = _to;
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );

        require(_from == owner[_tokenId] && _from != address(0), "safeTransferFrom with invalid from address");

        if (isContract(_to)) {
            if (IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") == 0x150b7a02) {
                emit Transfer(_from, _to, _tokenId);
                balances[_from]--;
                balances[_to]++;
                approved[_tokenId] = address(0);
                owner[_tokenId] = _to;
            } else {
                revert("receiving address unable to hold ERC721!");
            }
        } else {
            emit Transfer(_from, _to, _tokenId);
            balances[_from]--;
            balances[_to]++;
            approved[_tokenId] = address(0);
            owner[_tokenId] = _to;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );

        require(_from == owner[_tokenId] && _from != address(0), "safeTransferFrom with invalid from address");

        emit Transfer(_from, _to, _tokenId);
        balances[_from]--;
        balances[_to]++;
        approved[_tokenId] = address(0);
        owner[_tokenId] = _to;
    }

    function approve(address _approved, uint256 _tokenId) public override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to approve this NFT!"
        );
        emit Approval(owner[_tokenId], _approved, _tokenId);
        approved[_tokenId] = _approved;
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        emit ApprovalForAll(msg.sender, _operator, _approved);
        operatorList[msg.sender][_operator] = _approved;
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return approved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return operatorList[_owner][_operator];
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC165, ERC721) returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }
}
