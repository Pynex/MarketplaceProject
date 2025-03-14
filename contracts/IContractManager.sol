// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICollectionManager
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice Interface for managing NFT collections.  This interface defines the functions
 *         for creating, managing, and retrieving information about NFT collections.
 */
interface ICollectionManager {

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
     * @param id The unique ID of the collection.
     */
    struct CollectionInfo {
        string name;
        string symbol;
        address collectionOwner;
        string collectionURI;
        uint256 price;
        uint256 quantityInStock;
        address collectionAddress;
        uint256 id;
    }

    /**
     * @notice Creates a new NFT collection.
     * @dev Deploys a new ERC721 contract for the collection.
     * @param _name The name of the collection.
     * @param _symbol The symbol of the collection.
     * @param _collectionURI The base URI for the collection's metadata.
     * @param _price The price of each NFT in the collection.
     * @param _quantityInStock The number of NFTs initially available in the collection.
     */
    function createCollection(
        string calldata _name,
        string calldata _symbol,
        string calldata _collectionURI,
        uint256 _price,
        uint256 _quantityInStock
    ) external payable;

    /**
     * @notice Sets the address of the main contract that can interact with this contract.
     * @dev  This function is used to establish trust between contracts.
     * @param _mainContract The address of the main contract.
     */
    function setMainContract(address _mainContract) external;

    /**
     * @notice Retrieves collection information based on the collection address.
     * @param _collection The address of the ERC721 collection.
     * @return CollectionInfo Returns a `CollectionInfo` struct containing the collection's details.
     */
    function getCollectionInfoByCollectionAddress(address _collection) external view returns (CollectionInfo memory);

    /**
     * @notice Retrieves collection information based on the address of the collection owner.
     * @param _seller The address of the collection owner (seller).
     * @return CollectionInfo Returns a `CollectionInfo` struct containing the collection's details.
     */
    function getCollectionInfoByAddressOwner(address _seller) external view returns (CollectionInfo memory);

    /**
     * @notice Redeems a promotional code for a specific collection.
     * @dev Allows a user to redeem a promo code for a discount or other benefit.
     * @param _id The ID of the collection.
     * @param _code The promotional code to redeem.
     */
    function redeemCode(uint _id, bytes8 _code) external payable;

    /**
     * @notice Changes the quantity in stock for a specific collection.
     * @param _newQuantity The new quantity in stock.
     * @param _id The ID of the collection.
     */
    function changeQuantityInStock(uint _newQuantity, uint _id) external payable;

    /**
     * @notice Changes the price for a specific collection.
     * @param _newPrice The new price.
     * @param _id The ID of the collection.
     */
    function changePrice(uint _newPrice, uint _id) external payable;

    /**
     * @notice Retrieves the address of the ERC721 contract for a specific collection ID.
     * @param _id The ID of the collection.
     * @return address The address of the ERC721 contract.
     */
    function getAddressById(uint256 _id) external view returns (address);

    /**
     * @notice Retrieves the price of an NFT in a specific collection.
     * @param _id The ID of the collection.
     * @return uint256 The price of the NFT.
     */
    function getPrice(uint256 _id) external view returns (uint256);

    /**
     * @notice Retrieves the quantity in stock for a specific collection.
     * @param _id The ID of the collection.
     * @return uint256 The quantity in stock.
     */
    function getQuantity(uint256 _id) external view returns (uint256);

    /**
     * @notice Retrieves a promotional code for a specific user and index.
     * @param _indexOfPromo The index of the promo code in the user's list of codes.
     * @param _user The address of the user.
     * @return bytes8 The promotional code.
     */
    function getPromo(uint256 _indexOfPromo, address _user) external view returns (bytes8);

    /**
     * @notice Checks if a collection with a given ID exists.
     * @param _id The ID of the collection.
     * @return bool Returns true if the collection exists, false otherwise.
     */
    function collectionExist(uint _id) external view returns (bool);

    /**
     * @notice Retrieves the owner of a collection given the collection ID.
     * @param _id The ID of the collection.
     * @return address The address of the collection owner.
     */
    function getOwnerByCollectionId(uint256 _id) external view returns (address);

    /**
     * @notice Generates a promotional code for a user.
     * @dev  This function is intended for internal use by the main contract. It should not be called directly.
     * @param _amount The amount of promo codes to generate.
     * @param _id The ID of the collection.
     * @param _user The address of the user to generate the promo code for.
     */
    function _generatePromoCode(uint _amount, uint _id, address _user) external;
}