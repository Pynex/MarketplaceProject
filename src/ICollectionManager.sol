// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICollectionManager
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice Interface for managing NFT collections.  This interface defines the functions
 *         for creating, managing, and retrieving information about NFT collections.
 */
interface ICollectionManager {

    // /**
    //  * @notice Structure containing information about an NFT collection.
    //  * @dev Details about each field are provided below.
    //  * @param name The name of the collection.
    //  * @param symbol The symbol of the collection.
    //  * @param collectionOwner The address of the collection owner.
    //  * @param collectionURI The base URI for the collection's metadata.
    //  * @param price The price of each NFT in the collection.
    //  * @param quantityInStock The number of NFTs currently available in the collection.
    //  * @param collectionAddress The address of the ERC721 contract for the collection.
    //  */
    // struct CollectionInfo {
    //     string name;
    //     string symbol;
    //     address collectionOwner;
    //     string collectionURI;
    //     uint256 price;
    //     uint256 quantityInStock;
    //     address collectionAddress;
    // }

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
     * @notice Changes the quantity in stock for a specific collection.
     * @param _newQuantity The new quantity in stock.
     * @param _collectionAddress The address of the collection.
     */
    function changeQuantityInStock(uint _newQuantity, address _collectionAddress) external payable;

    /**
     * @notice Changes the price for a specific collection.
     * @param _newPrice The new price.
     * @param _collectionAddress The address of the collection.
     */
    function changePrice(uint _newPrice, address _collectionAddress) external payable;

    /**
     * @notice Checks if a collection with a given ID exists.
     * @param _collectionAddress The address of the collection.
     * @return bool Returns true if the collection exists, false otherwise.
     */
    function collectionExist(address _collectionAddress) external view returns (bool);
}