// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollectionManager} from "./ICollectionManager.sol";
import {NewERC721Collection} from "./NewERC721Collection.sol";
import {Errors} from "./Errors.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


/**
 * @title CollectionManager
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice Manages the creation and retrieval of NFT collections.  This contract implements the
 *         ICollectionManager interface and provides functionality for creating new ERC721 collections,
 *         managing collection information, and generating promotional codes.
 */
contract CollectionManager is ICollectionManager, Errors, Ownable {

    /**
     * @notice Maximum length allowed for a collection's name.
     */
    uint256 private constant MAX_NAME_LENGTH = 64;

    /**
     * @notice Maximum length allowed for a collection's symbol.
     */
    uint256 private constant MAX_SYMBOL_LENGTH = 8;

    /**
     * @notice The address of the main contract that is authorized to interact with this contract.
     * @dev Only the main contract can call certain functions in this contract.
     */
    address public mainContract;

    /**
     * @notice Structure containing information about an NFT collection.
     * @dev Details about each field are provided below.
     * @param name The name of the collection.
     * @param symbol The symbol of the collection.
     * @param collectionOwner The address of the collection owner.
     * @param collectionURI The base URI for the collection's metadata.
     * @param price The price of each NFT in the collection.
     * @param quantityInStock The number of NFTs currently available in the collection.
     * @param collectionAddress The address of the ERC721 contract for the collection.
     */
    struct CollectionInfo {
        string name;
        string symbol;
        address collectionOwner;
        string collectionURI;
        uint256 price;
        uint256 quantityInStock;
        address collectionAddress;
    }

    mapping(address => CollectionInfo) public collections;

    mapping(address => address[]) public collectionsByCreator;

    /**
     * @notice Modifier that restricts function execution to the creator of a collection or the main contract.
     * @param _collectionAddress The address of the collection.
     */
    modifier onlyCreator(address _collectionAddress) {
        require(collections[_collectionAddress].collectionOwner == msg.sender || msg.sender == mainContract,
            onlyCollectionOwner(collections[_collectionAddress].collectionOwner,mainContract, msg.sender ));
        _;
    }

    /**
     * @notice Emitted when a new collection is created.
     * @param newCollectionAddress The address of the newly created ERC721 contract.
     * @param collectionOwner The address of the collection owner.
     * @param collectionURI The base URI for the collection's metadata.
     * @param collectionName The name of the collection.
     * @param price The price of each NFT in the collection.
     * @param amountOfStock The initial number of NFTs in stock.
     */
    event CollectionCreated(
        address newCollectionAddress,
        address collectionOwner,
        string collectionURI,
        string collectionName,
        uint256 price,
        uint amountOfStock
    );

    /**
     * @notice Constructor that sets the initial owner of the contract.
     * @param initialOwner The address of the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // require(initialOwner !=address(0));
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function setMainContract (address _mainContract) external onlyOwner {
        require(_mainContract != address(0), ZeroMainContractAddress(address(0)));
        mainContract = _mainContract;
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _collectionURI,
        uint256 _price,
        uint256 _quantityInStock
    ) external payable  {
        // Check input parameters.
        require(
            bytes(_name).length > 0 && bytes(_name).length < MAX_NAME_LENGTH,
            incorrectNameLength(1, 0, 64)
        );
        require(
            bytes(_symbol).length > 0 && bytes(_symbol).length < MAX_SYMBOL_LENGTH,
            incorrectSymbolLength(1, 0)
        );
        require(bytes(_collectionURI).length > 0, incorrectURI(1,0));
        require(_price > 0, incorrectPrice(1,0));

        // Deploy a new ERC721NewCollection contract.
        NewERC721Collection collection = new NewERC721Collection(
            _name,
            _symbol,
            _collectionURI,
            msg.sender,
            owner(),
            mainContract
        );
        address collectionAddress = address(collection);

        // require(collectionAddress != address(0), FailedToDeployContract(false, address(0)));

        // Save collection info in the collections mapping.
        CollectionInfo memory newCollection = CollectionInfo({
            name: _name,
            symbol: _symbol,
            collectionOwner: msg.sender,
            collectionURI: _collectionURI,
            price: _price,
            quantityInStock: _quantityInStock,
            collectionAddress: collectionAddress
        });
        collections[collectionAddress] = newCollection;
        collectionsByCreator[msg.sender].push(collectionAddress);


        // Emit event.
        emit CollectionCreated(
            collectionAddress,
            msg.sender,
            _collectionURI,
            _name,
            _price,
            _quantityInStock
        );
    }

    function getCollectionOwnerByAddressOwner(address _collectionsOwner) external view returns (CollectionInfo[] memory) {
        require(_collectionsOwner != address(0));

        address[] memory collectionAddresses = collectionsByCreator[_collectionsOwner];
        CollectionInfo[] memory result = new CollectionInfo[](collectionAddresses.length);
        
        for(uint i = 0; i <collectionAddresses.length; ++i) {
            address collectionAddress = collectionAddresses[i];
            result[i] = collections[collectionAddress];
        }
        return result;
    }

    /**
     * @notice Retrieves collection information based on the collection ID.
     * @return CollectionInfo Returns a `CollectionInfo` struct containing the collection's details.
     * @dev This function returns the CollectionInfo struct directly from the collections mapping using the provided ID.
     */
    function getCollectionByAddress (address _collectionAddress) external view returns (CollectionInfo memory) {
        require(collectionExist(_collectionAddress), collectionNotFound(false));
        return (collections[_collectionAddress]);
    }
    
    /**
     *  @inheritdoc ICollectionManager
     *  @dev onlyCreator modifier.
     */
    function changePrice (uint _newPrice,address _collectionAddress) public payable onlyCreator(_collectionAddress) {
         _updatePrice(_collectionAddress, _newPrice);
    }

    /**
     *  @inheritdoc ICollectionManager
     *  @dev onlyCreator modifier.
     */
    function changeQuantityInStock (uint _newQuantity,address _collectionAddress) external payable onlyCreator(_collectionAddress) {
        _updateQuantity(_collectionAddress, _newQuantity);
    }


    /**
     *  @inheritdoc ICollectionManager
     */
    function collectionExist (address _collectionAddress) public view returns (bool) {
        if(collections[_collectionAddress].collectionAddress != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Updates the price of an NFT collection.
     * @dev Modifies the `price` field of a collection in the `collections` mapping.  This function is intended for internal use only.
     * @param _collectionAddress The address of the collection to update.
     * @param _newPrice The new price of the collection.
     */
    function _updatePrice(address _collectionAddress, uint256 _newPrice) private {
        collections[_collectionAddress].price = _newPrice;
    }

    /**
     * @notice Updates the quantity in stock of an NFT collection.
     * @dev Modifies the `quantityInStock` field of a collection in the `collections` mapping. This function is intended for internal use only.
     * @param _collectionAddress The address of the collection to update.
     * @param _newQuantity The new quantity in stock.
     */
    function _updateQuantity(address _collectionAddress, uint256 _newQuantity) private {
        collections[_collectionAddress].quantityInStock = _newQuantity;
    }
}
