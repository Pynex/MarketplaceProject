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
     * @param _id The ID of the product to purchase.
     * @param _quantity The quantity of the product to purchase.
     */
    function buy(uint256 _id, uint256 _quantity) external payable;

    /**
     * @notice Allows a user to purchase multiple products in a single transaction.
     * @dev The user must send enough Ether to cover the price of all products.
     * @param _ids An array of product IDs to purchase.
     * @param _quantities An array of quantities for each product to purchase.
     */
    function batchBuy(uint256[] calldata _ids, uint256[] calldata _quantities) external payable;
}