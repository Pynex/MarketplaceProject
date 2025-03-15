// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollectionManager} from "./IContractManager.sol";
import {NewERC721Collection} from "./NewERC721Collection.sol";
import {Errors} from "./Errors.sol";
import {MainContract} from "./MainContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollectionManager
 * @author Your Name / Organization
 * @notice Manages the creation and retrieval of NFT collections.  This contract implements the
 *         ICollectionManager interface and provides functionality for creating new ERC721 collections,
 *         managing collection information, and generating promotional codes.
 */
contract CollectionManager is ICollectionManager, Errors, Ownable {
    /**
     * @notice Counter for unique collection IDs.
     * @dev This counter is incremented each time a new collection is created to ensure unique IDs.
     */
    uint256 public idCounter = 1;

    // onlyMainContract

    /**
     * @notice Maximum length allowed for a collection's name.
     */
    uint256 private constant MAX_NAME_LENGTH = 64;

    /**
     * @notice Freeze time for the collection
     */
    uint256 private constant FREZE_TIME = 10 minutes;

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
     * @notice Mapping from collection ID to CollectionInfo.
     * @dev Stores information about each NFT collection, including its name, symbol, and more.
     */
    mapping(uint256 => CollectionInfo) public collections;

    /**
     * @notice Mapping from user address to an array of promotional codes.
     * @dev Stores the unique promotional codes generated for each user.
     */
    mapping(address => bytes8[]) private uniqPromoForUser;

    /**
     * @notice Mapping from user address to a counter for generated codes.
     * @dev Used for generating unique promo codes for each user.
     */
    mapping(address => uint) codesCounter;

    /**
     * @notice Modifier that restricts function execution to the creator of a collection or the main contract.
     * @param _id The ID of the collection.
     */
    modifier onlyCreator(uint256 _id) {
        require(collections[_id].collectionOwner == msg.sender || msg.sender == mainContract, 
        onlyCollectionOwner(collections[_id].collectionOwner,mainContract, msg.sender ));
        _;
    }

    modifier IncorrectId(uint _id) {
        require(_id <= idCounter, incorrectIdError(idCounter, _id));
        _;
    }

    /**
     * @notice Emitted when a new collection is created.
     * @param newCollectionAddress The address of the newly created ERC721 contract.
     * @param collectionOwner The address of the collection owner.
     * @param collectionURI The base URI for the collection's metadata.
     * @param collectionName The name of the collection.
     * @param price The price of each NFT in the collection.
     * @param id The unique ID of the collection.
     * @param amountOfStock The initial number of NFTs in stock.
     */
    event CollectionCreated(
        address newCollectionAddress,
        address collectionOwner,
        string collectionURI,
        string collectionName,
        uint256 price,
        uint256 id,
        uint amountOfStock
    );

    /**
     * @notice Emitted when a promotional code is successfully used.
     * @param user The address of the user who used the promo code.
     * @param collectionAddress The address of the collection for which the promo code was used.
     */
    event PromoCodeSuccessfullyUsed(
        address indexed user,
        address indexed collectionAddress
    );

    /**
     * @notice Constructor that sets the initial owner of the contract.
     * @param initialOwner The address of the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        require(initialOwner !=address(0),incorrectAddress(address(0))) ;
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function setMainContract (address _mainContract) external onlyOwner {
        require(_mainContract != address(0), ZeroMainContractAddress(address(0)));
        mainContract = _mainContract;
    }

    function createCollection(
        string calldata _name,
        string calldata _symbol,
        string calldata _collectionURI,
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
            address(this)
        );
        address collectionAddress = address(collection);

        require(collectionAddress != address(0), FailedToDeployContract(false, address(0)));

        // Save collection info in the collections mapping.
        CollectionInfo memory newCollection = CollectionInfo({
            name: _name,
            symbol: _symbol,
            collectionOwner: msg.sender,
            collectionURI: _collectionURI,
            price: _price,
            quantityInStock: _quantityInStock,
            collectionAddress: collectionAddress,
            id: idCounter
        });
        collections[idCounter] = newCollection;

        // Emit event.
        emit CollectionCreated(
            collectionAddress,
            msg.sender,
            _collectionURI,
            _name,
            _price,
            idCounter,
            _quantityInStock
        );

        // Increment after emitting the event
        idCounter++;
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getCollectionInfoByCollectionAddress ( address _collection ) external view returns (CollectionInfo memory) {
        require(_collection != address(0), incorrectAddress(address(0)));
        for (uint i = 1; i < idCounter; i++) { // Start from 1 because idCounter starts at 1
                if (_collection==collections[i].collectionAddress){
                return collections[i];
            }
        }
        revert collectionNotFound(false);
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getCollectionInfoByAddressOwner (address _seller) external view returns (CollectionInfo memory) {
        require(_seller != address (0), incorrectAddress(address(0)));
        for (uint i = 1; i < idCounter; i++) { // Start from 1 because idCounter starts at 1
                if (_seller==collections[i].collectionOwner){
                return collections[i];
            }
        }
        revert collectionNotFound(false);
    }
    
    /**
     *  @inheritdoc ICollectionManager
     */
    function redeemCode (uint _id, bytes8 _code) external  payable {
         
        require(collectionExist(_id), collectionNotFound(false));

        // Get collection contract.
        address _collectionAddress = getAddressById(_id);
        NewERC721Collection collection = NewERC721Collection(_collectionAddress);

        // Check if mainContract is valid.
        require(
            address(this) == collection.mainContract(),
            incorrectCollectionAddress(address(this), collection.mainContract(), false)
        );
        // Check if promo code is valid.
        require(_isPromoValid(_code) == true, invalidPromoCode(false));

        // Mint the NFT.
        collection.mint(msg.sender);

        // Delete promo code for user.
        _deletePromoCode(msg.sender, _code);

        // Emit event.
        emit PromoCodeSuccessfullyUsed(msg.sender, _collectionAddress);
    }

    /**
     *  @inheritdoc ICollectionManager
     *  @dev onlyCreator modifier.
     */
    function changePrice (uint _newPrice,uint _id) public payable onlyCreator(_id) {
         _updatePrice(_id, _newPrice);
    }

    /**
     *  @inheritdoc ICollectionManager
     *  @dev onlyCreator modifier.
     */
    function changeQuantityInStock (uint _newQuantity,uint _id) external payable onlyCreator(_id) {
        _updateQuantity(_id, _newQuantity);
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getAddressById(uint256 _id) public IncorrectId(_id) view  returns (address) {
        require(collectionExist(_id),collectionNotFound(false));
        return (collections[_id].collectionAddress);
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getPrice(uint256 _id) public IncorrectId(_id) view returns (uint256) {
        require(collectionExist(_id),collectionNotFound(false));
        return (collections[_id].price);
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getQuantity(uint256 _id) public IncorrectId(_id) view returns (uint256) {
        require(collectionExist(_id), collectionNotFound(false));
        return (collections[_id].quantityInStock);
    }

    /**
     *  @inheritdoc ICollectionManager
     *  @dev onlyOwner modifier.
     */
    function getPromo(uint256 _indexOfPromo, address _user)
        public
        view
        onlyOwner
        returns (bytes8)
    {
        require(_user != address(0), incorrectAddress(address(0)));
        require(
            uniqPromoForUser[_user][_indexOfPromo] != bytes8(0),
            incorrectIndex(bytes8(0), false)
        );
        return (uniqPromoForUser[_user][_indexOfPromo]);
    }

    function collectionExist (uint _id) public IncorrectId(_id) view returns (bool) {
        require(collections[_id].collectionAddress != address(0), TokenNotExsist(address(0)));
        return true;
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function getOwnerByCollectionId(uint256 _id) public view returns (address) {
        require(collectionExist(_id),collectionNotFound(false));
        return collections[_id].collectionOwner;
    }

    /**
     * @notice Checks if a given promo code is valid for the message sender.
     * @dev Iterates through the user's list of promo codes to find a match.
     * @param _promoCode The promo code to validate.
     * @return bool Returns true if the promo code is valid, false otherwise.
     */
    function _isPromoValid(bytes8 _promoCode) internal view returns (bool) {
        for (uint256 i = 0; i < uniqPromoForUser[msg.sender].length; i++) {
            if (uniqPromoForUser[msg.sender][i] == _promoCode) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Deletes a promotional code for a specific user.
     * @dev  This function removes a promo code from a user's list.  It swaps the promo code
     *       to be deleted with the last element in the array and then removes the last element.
     *       The function reverts if the user address is zero or if the promo code is not found for the specified user.
     * @param _user The address of the user whose promo code should be deleted.
     * @param _promoCode The promotional code to delete.
     */
    function _deletePromoCode(address _user, bytes8 _promoCode) internal {
        require(_user != address(0), incorrectAddress(address(0)));
        (uint256 _index, bool status) = _findIndexByUserAddress(
            _user,
            _promoCode
        );

        if (!status) {
            revert promoCodeNotFound(false);
        }

        // Swap the promo code to be deleted with the last element in the array
        uniqPromoForUser[_user][_index] = uniqPromoForUser[_user][
            uniqPromoForUser[_user].length - 1
        ];
        // Remove the last element (which is now a duplicate)
        uniqPromoForUser[_user].pop();
    }

    /**
     * @notice Finds the index of a promo code in a user's list of promo codes.
     * @dev Iterates through the user's `uniqPromoForUser` array to find the index of the specified promo code.
     * @param _user The address of the user whose promo code list is being searched.
     * @param _promoCode The promo code to find.
     * @return (uint256, bool) Returns a tuple: the index of the promo code if found,
     *          and a boolean indicating whether the promo code was found (true) or not (false).
     *          If the promo code is not found, the index will be 0 and the boolean will be false.
     */
    function _findIndexByUserAddress(address _user, bytes8 _promoCode)
        internal
        view
        returns (uint256, bool)
    {
        bytes8[] storage promoCodes = uniqPromoForUser[_user];
        for (uint256 i = 0; i < promoCodes.length; i++) {
            if (promoCodes[i] == _promoCode) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     *  @inheritdoc ICollectionManager
     */
    function _generatePromoCode(uint _amount,uint _id, address _user) public {
        require(_user != address(0),incorrectAddress(address(0)));
        require(msg.sender == address(mainContract), onlyMainContract(address(mainContract), msg.sender));
        require(_amount > 0, incorrectQuantity(1,0));
        uint counter = codesCounter[msg.sender];
        
        for (uint i = 0; i < _amount ; i++) {
        bytes8 random = bytes8(
            keccak256(abi.encode((blockhash(block.number - i)),block.timestamp,counter,msg.sender,_id, i, tx.origin,
            block.prevrandao)));
        uniqPromoForUser[_user].push(random);
        codesCounter[msg.sender]++;
        }
    }


    /**
     * @notice Updates the price of an NFT collection.
     * @dev Modifies the `price` field of a collection in the `collections` mapping.  This function is intended for internal use only.
     * @param _id The ID of the collection to update.
     * @param _newPrice The new price of the collection.
     */
    function _updatePrice(uint256 _id, uint256 _newPrice) private IncorrectId(_id) {
        collections[_id].price = _newPrice;
    }

    /**
     * @notice Updates the quantity in stock of an NFT collection.
     * @dev Modifies the `quantityInStock` field of a collection in the `collections` mapping. This function is intended for internal use only.
     * @param _id The ID of the collection to update.
     * @param _newQuantity The new quantity in stock.
     */
    function _updateQuantity(uint256 _id, uint256 _newQuantity) private IncorrectId(_id) {
        collections[_id].quantityInStock = _newQuantity;
    }
}
