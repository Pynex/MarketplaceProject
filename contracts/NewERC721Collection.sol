// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title contract that create new NFR collection.
 * @notice this contract use in MainContract.
 * @dev in the MainContract we use mint function when user buys product(-s).
 */
contract NewERC721Collection is ERC721 {
    uint256 private tokenCounter;
    string private baseURI;
    address public mainContract;
    address private creator;
    address private platformOwner;

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
        tokenCounter;
        mainContract = _mainContract;
    }

    /// @notice modifier for collection's owner and for main contract owner.
    modifier onlyCreator() {
        require(
            msg.sender == platformOwner || msg.sender == creator,
            "Only creator can call this function"
        );
        _;
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
        onlyCreator
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev returns the base URI for the contract.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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