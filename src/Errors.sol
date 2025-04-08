// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Error Definitions
 * @dev This contract defines and documents all custom errors used throughout the project, following NatSpec conventions for clarity and discoverability.
 */
contract Errors {

    /**
     * @dev Emitted when an account attempts a transaction with insufficient funds.
     * @param price The required amount (e.g., for a purchase).
     * @param getPrice The account's current balance.
     */
    error NotEnoughFunds(uint price, uint getPrice);

    /**
     * @dev Emitted when an ID provided is incorrect or out of range.
     * @param lastId The last valid ID in the sequence.
     * @param youId The ID that was provided.
     */
    error incorrectIdError(uint lastId, uint youId);

    /**
     * @dev Emitted when the lengths of two arrays being processed together do not match. This can cause unexpected or incomplete processing.
     * @param ids The length of the array of IDs.
     * @param quantities The length of the array of quantities.
     */
    error arraysMisMatch(uint ids, uint quantities);

    /**
     * @dev Emitted during a batch buying operation if one of the provided IDs does not exist or is invalid.
     * @param ids the Id that not exist
     */
    error inncorectIdInButchBuy(uint ids);

    /**
     * @dev Emitted when a token with the specified collection address does not exist in the system.
     * @param conllectionAddress The address of the token collection that could not be found.
     */
    error TokenNotExist(address conllectionAddress);

    /**
     * @dev Emitted when a contract fails to deploy, indicating a potential deployment issue.
     * @param deploy A boolean indicating the status of deployment.
     * @param collectionAddress The address of the collection that failed to deploy.
     */
    error FailedToDeployContract(bool deploy, address collectionAddress);

    /**
     * @dev Emitted when there are not enough products in stock to fulfill a requested order.
     * @param youWant The quantity requested by the buyer.
     * @param inStock The quantity currently in stock.
     */
    error notEnoughProductsInStock(uint youWant, uint inStock);

    /**
     * @dev Emitted when an provided promo code is invalid or not present in system.
     * @param exsistPromoCode A boolean indicating promo code existence
     */
    error invalidPromoCode(bool exsistPromoCode);

    /**
     * @dev Emitted when incorrect symbol length.
     * @param minimalSymbolLength Minimal symbol length
     * @param youSymbolLength you symbol length
     */
    error incorrectSymbolLength(uint minimalSymbolLength, uint youSymbolLength);

    /**
     * @dev Emitted when provided URI is incorrect.
     * @param minimalURILength Minimal uri length
     * @param youURILength you uri length
     */
    error incorrectURI(uint minimalURILength, uint youURILength);

    /**
     * @dev Emitted when provided price is incorrect.
     * @param minimalPrice minimal Price
     * @param youPrice your Price
     */
    error incorrectPrice(uint minimalPrice, uint youPrice);

    /**
     * @dev Emitted when provided quantity is incorrect.
     * @param minimalQuantity minimal quantity
     * @param youQuantity you quantity
     */
    error incorrectQuantity(uint minimalQuantity, uint youQuantity);

    /**
     * @dev Emitted when provided address is not MainContract address.
     * @param mainContractAddress Main contract address
     * @param youAddress address that you provided
     */
    error onlyMainContract(address mainContractAddress, address youAddress);

    /**
     * @dev Emitted when provided address collection is not exisist
     * @param collectionExsist collection exsist
     */
    error collectionNotFound(bool collectionExsist);

    /**
     * @dev Emitted when provided promo code is not exist
     * @param promoCodeExsist promo code exist
     */
    error promoCodeNotFound(bool promoCodeExsist);

    /**
     * @dev Emitted when provided index is incorrect
     * @param promoCode promo Code
     * @param promoCodeExsist promo Code exist
     */
    error incorrectIndex(bytes8 promoCode, bool promoCodeExsist);

    /**
     * @dev Emitted when provided Collection Address incorrect
     * @param mainContract mainContract address
     * @param getMainContract MainContract Address
     * @param valid valid address or not
     */
    error incorrectCollectionAddress(address mainContract, address getMainContract, bool valid);

    /**
     * @dev Emitted when collection name length incorrect
     * @param minimalNameLength minimal name length
     * @param youNameLength you name length
     * @param maxNameLength max Name Length
     */
    error incorrectNameLength(uint minimalNameLength, uint youNameLength, uint maxNameLength);

    /**
     * @dev Emitted when is not collection owner
     * @param collectionCreator is collection creator
     * @param mainContract main contract address
     * @param you who use function
     */
    error onlyCollectionOwner(address collectionCreator, address mainContract, address you);

    /**
     * @dev Emitted when is incorrect Address
     * @param argumentAddress argument Addrress
     */
    error incorrectAddress(address argumentAddress);

     /**
     * @dev Emitted when is  Zero Main Contract Address
     * @param mainContractAddress Main Contract Address
     */
    error ZeroMainContractAddress(address mainContractAddress);

    error tooManyProductsToBuy(uint max, uint currentProductsToBuy);
}