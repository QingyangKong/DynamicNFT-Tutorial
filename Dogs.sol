// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Dogs is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    uint256 public MAX_AMOUNT = 3;
    string uri = "";
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public whiteList;
    bool public preMintWindow = false;
    bool public mintWindow = false;

    constructor() ERC721("Dogs", "DGS") {}

    function preMint() public payable {
        require(preMintWindow, "Premint is not open yet!");
        require(msg.value == 0.001 ether, "The price of dog nft is 0.005 ether");
        require(whiteList[msg.sender], "You are not in the white list");
        require(balanceOf(msg.sender) < 1, "Max amount of NFT minted by an addresss is 1");
        require(totalSupply() < MAX_AMOUNT, "Dog NFT is sold out!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    } 

    function mint() public payable {
        require(mintWindow, "Mint is not open yet!");
        require(msg.value == 0.005 ether, "The price of dog nft is 0.005 ether");
        require(totalSupply() < MAX_AMOUNT, "Dog NFT is sold out!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function addToWhiteList(address[] calldata addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whiteList[addrs[i]] = true;
        }
    }

    function setWindow(bool _preMintOpen, bool mintOpen) public onlyOwner {
        preMintWindow = _preMintOpen;
        mintWindow = mintOpen;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}