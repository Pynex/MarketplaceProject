// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IMainContract Interface
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice Defines the interface for the main contract responsible for managing collections and sales.
 */
interface IMainContract {

    /**
     * @notice Sets the address of the CollectionManager contract.
     * @dev This function allows the owner to update the address of the CollectionManager.
     * @param _collectionManager The address of the CollectionManager contract.
     */
    function setCollectionManager(address _collectionManager) external;

    /**
     * @notice Allows a user to purchase a specified quantity of a product.
     * @dev The user must send enough Ether to cover the price of the product.
     * @param _collectionAddress The address of the product to purchase.
     * @param _quantity The quantity of the product to purchase.
     */
    function buy(address _collectionAddress, uint256 _quantity) external payable;

    /**
     * @notice Allows a user to purchase multiple products in a single transaction.
     * @dev The user must send enough Ether to cover the price of all products.
     * @param _collectionAddresses An array of product addresses to purchase.
     * @param _quantities An array of quantities for each product to purchase.
     */
    function batchBuy(address[] calldata _collectionAddresses, uint256[] calldata _quantities) external payable;

    /**
     * @notice Redeems a promotional code for a specific collection.
     * @dev Allows a user to redeem a promo code for a discount or other benefit.
     * @param _collectionAddress The address of the collection.
     * @param _code The promotional code to redeem.
     */
    function redeemCode(address _collectionAddress, bytes8 _code) external payable;

    // /**
    //  * @notice Retrieves a promotional code for a specific user and index.
    //  * @param _indexOfPromo The index of the promo code in the user's list of codes.
    //  * @param _user The address of the user.
    //  * @return bytes8 The promotional code.
    //  */
    // function getPromo(uint256 _indexOfPromo, address _user) external view returns (bytes8);

    /**
     * @notice Retrieves the price of an NFT in a specific collection.
     * @param _collectionAddress The address of the collection.
     * @return uint256 The price of the NFT.
     */
    function getPrice(address _collectionAddress) external view returns (uint256);

    /**
     * @notice Retrieves the quantity in stock for a specific collection.
     * @param _collectionAddress The address of the collection.
     * @return uint256 The quantity in stock.
     */
    function getQuantity(address _collectionAddress) external view returns (uint256);

    /**
     * @notice Retrieves the owner of a collection given the collection ID.
     * @param _collectionAddress The address of the collection.
     * @return address The address of the collection owner.
     */
    function getCollectionOwnerByAddress(address _collectionAddress) external view returns (address);

}