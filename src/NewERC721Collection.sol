// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
// import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";


/**
 * @title contract that create new NFR collection.
 * @notice this contract use in MainContract.
 * @dev in the MainContract we use mint function when user buys product(-s).
 */
contract NewERC721Collection is ERC721 {
    uint256 tokenCounter;
    string baseURI;
    address public immutable mainContract;
    address immutable creator;
    address immutable platformOwner;

    /**
    * @dev Constructor for the ERC721NewCollection contract.
    * @param _name The name of the NFT collection.
    * @param _symbol The symbol of the NFT collection.
    * @param _collectionURI The base URI for the NFT metadata.
    * @param _creator The address that created the collection.
    * @param _platformOwner the owner mainContract address.
    * @param _mainContract The address of the main contract that can mint NFTs.
    */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _collectionURI,
        address _creator,
        address _platformOwner,
        address _mainContract
    ) ERC721(_name, _symbol) {
        require(_creator != address(0), "Creator cannot be zero address");
        require(
            _platformOwner != address(0),
            "Marketplace creator cannot be zero address"
        );
        require(
            _mainContract != address(0),
            "Main contract cannot be zero address"
        );

        creator = _creator;
        platformOwner = _platformOwner;
        baseURI = _collectionURI;
        tokenCounter = 1;
        mainContract = _mainContract;
    }

    /// @notice modifier for mainContract address.
    modifier onlyMainContract() {
        require(
            msg.sender == mainContract,
            "Only mainContract can call this function"
        );
        _;
    }

    /// @dev mints NFT to the buyer address, when he reedemed a promo code.
    /// @param _to the buyer address to mint the NFT to.
    function mint(address _to) external onlyMainContract  {
        uint256 newTokenId = tokenCounter;
        _safeMint(_to, newTokenId);
        tokenCounter++;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev returns the base URI for the contract.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns(string memory) {
        string memory URI = _baseURI();return URI;
    }

    /// @dev returns the URI for a given token ID.
    /// @param tokenId the Id of the token
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}
