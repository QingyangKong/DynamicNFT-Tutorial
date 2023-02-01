// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Dogs is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    
    // Config of NFT
    uint256 public MAX_AMOUNT = 6;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public whiteList;
    bool public preMintWindow = false;
    bool public mintWindow = false;

    // METADATA of NFT(3 for each)
    string constant METADATA_SHIBAINU = "ipfs://QmXw7TEAJWKjKifvLE25Z9yjvowWk2NWY3WgnZPUto9XoA";
    string constant METADATA_HUSKY = "ipfs://QmTFXZBmmnSANGRGhRVoahTTVPJyGaWum8D3YicJQmG97m";
    string constant METADATA_BULLDOG = "ipfs://QmSM5h4WseQWATNhFWeCbqCTAGJCZc11Sa1P5gaXk38ybT";
    string constant METADATA_SHEPHERD = "ipfs://QmRGryH7a1SLyTccZdnatjFpKeaydJcpvQKeQTzQgEp9eK";    

    string constant METADATA_SHIBAINU_cold = "ipfs://QmdjVTLhkLgyDapCdytbrLqhyn35wDqJetcWxj2C2BAFoZ";
    string constant METADATA_HUSKY_cold = "ipfs://Qmc2gR3GK1wnv2eTQePQyRuQqYdZhD4AMv5Kqu9eJHrP9t";
    string constant METADATA_BULLDOG_cold = "ipfs://QmZmHfmcNf3Q1C2x1Da1t2W4jh5PK78g7rJ6N55ontER6k";
    string constant METADATA_SHEPHERD_cold = "ipfs://QmQZMbJGXe79Fjr81GVuwWE8innnFLtAdJ5fdrJoSpqJzT";
    
    string constant METADATA_SHIBAINU_hot = "ipfs://QmUKfjGZHtGVrRBQ1GMpdHX2USV6SW6LjC4veCngTUamca";
    string constant METADATA_HUSKY_hot = "ipfs://QmQ8auA5CfWEpEVxMBab8syZNgtWdeeRUq9Mjwt12PbujA";
    string constant METADATA_BULLDOG_hot = "ipfs://QmSEmJhmAAJGmFAEhbimbawX5bjUqbCyrcu84xifQji9QR";
    string constant METADATA_SHEPHERD_hot = "ipfs://QmWKBLL6yakCWsexbk4wTng7dfQo8UtDqY65bCdTfwex6D";    

    // config of chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    mapping(uint256 => uint256) reqIdToTokenId;

    // for dynamic
    int256 public currentTmp;
    int256 public latestTmp;
    mapping (uint256 => dogBreed) tokenIdToDogBreed;
    enum dogBreed { SHIBAINU, HUSKY, BULLDOG, SHEPHERD }

    constructor(uint64 subId) ERC721("Dogs", "DGS") VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
        s_subscriptionId = subId;
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
    }

    function preMint() public payable {
        require(preMintWindow, "Premint is not open yet!");
        require(msg.value == 0.001 ether, "The price of dog nft is 0.005 ether");
        require(whiteList[msg.sender], "You are not in the white list");
        require(balanceOf(msg.sender) < 1, "Max amount of NFT minted by an addresss is 1");
        require(totalSupply() < MAX_AMOUNT, "Dog NFT is sold out!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        request(tokenId);
    } 

    function mint() public payable {
        require(mintWindow, "Mint is not open yet!");
        require(msg.value == 0.005 ether, "The price of dog nft is 0.005 ether");
        require(totalSupply() < MAX_AMOUNT, "Dog NFT is sold out!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        request(tokenId);
    }

    function updateLatestTmp(int256 temp) public  {
        latestTmp = temp;
    }

    function updateMetadata() public {
        if (latestTmp != currentTmp) {
            //update metadata according to latest tmp
            if(latestTmp < 10 * 10 ** 18) {
                for(uint256 i = 0; i < totalSupply(); i++) {
                    if(tokenIdToDogBreed[i] == dogBreed.BULLDOG) {
                        _setTokenURI(i, METADATA_BULLDOG_cold);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.SHIBAINU) {
                        _setTokenURI(i, METADATA_SHIBAINU_cold);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.HUSKY) {
                        _setTokenURI(i, METADATA_HUSKY_cold);    
                    } else {
                        _setTokenURI(i, METADATA_SHEPHERD_cold);    
                    }
                }
            } else if (latestTmp > 18 * 10 ** 18) {
                //update metadata to hot metadata
                for(uint256 i = 0; i < totalSupply(); i++) {
                    if(tokenIdToDogBreed[i] == dogBreed.BULLDOG) {
                        _setTokenURI(i, METADATA_BULLDOG_hot);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.SHIBAINU) {
                        _setTokenURI(i, METADATA_SHIBAINU_hot);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.HUSKY) {
                        _setTokenURI(i, METADATA_HUSKY_hot);    
                    } else {
                        _setTokenURI(i, METADATA_SHEPHERD_hot);    
                    }
                }
            } else {
                //udpate metadata to average
                for(uint256 i = 0; i < totalSupply(); i++) {
                    if(tokenIdToDogBreed[i] == dogBreed.BULLDOG) {
                        _setTokenURI(i, METADATA_BULLDOG);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.SHIBAINU) {
                        _setTokenURI(i, METADATA_SHIBAINU);    
                    } else if(tokenIdToDogBreed[i] == dogBreed.HUSKY) {
                        _setTokenURI(i, METADATA_HUSKY);    
                    } else {
                        _setTokenURI(i, METADATA_SHEPHERD);    
                    }
                }
            }
            currentTmp = latestTmp;
        }
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

   function request(uint256 _tokenId)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        reqIdToTokenId[requestId] = _tokenId;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomNumber = _randomWords[0] % 4;
        if (randomNumber == 0) {
            _setTokenURI(reqIdToTokenId[_requestId], METADATA_SHIBAINU);
            tokenIdToDogBreed[reqIdToTokenId[_requestId]] = dogBreed.SHIBAINU;
        } else if (randomNumber == 1) {
            _setTokenURI(reqIdToTokenId[_requestId], METADATA_HUSKY);
            tokenIdToDogBreed[reqIdToTokenId[_requestId]] = dogBreed.HUSKY;
        } else if (randomNumber == 2) {
            _setTokenURI(reqIdToTokenId[_requestId], METADATA_SHEPHERD);
            tokenIdToDogBreed[reqIdToTokenId[_requestId]] = dogBreed.SHEPHERD;
        } else {
            _setTokenURI(reqIdToTokenId[_requestId], METADATA_BULLDOG);
            tokenIdToDogBreed[reqIdToTokenId[_requestId]] = dogBreed.BULLDOG;
        }
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