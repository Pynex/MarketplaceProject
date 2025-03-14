// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./Errors.sol";
import {IMainContract} from "./IMainContract.sol";
import {ICollectionManager} from "./IContractManager.sol";

/**
 * @title Ma1nContract
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice The main contract for handling purchases and commissions. This contract allows users to buy NFTs,
 *         handles commission calculations, and interacts with the CollectionManager contract.
 */
contract MainContract is IMainContract, Ownable, ReentrancyGuard , Errors{

    /**
     * @notice The interface to the CollectionManager contract.
     */
    ICollectionManager public collectionManager;

    /**
     * @notice The amount of marketplace commission (in %).  This value is immutable and set during construction.
     */
    uint256 public immutable commission;

    /**
     * @notice Emitted when a product is purchased.
     * @param buyer The address of the buyer.
     * @param productId The ID of the purchased product.
     * @param price The price of the product.
     * @param cQuantity The quantity of the product purchased.
     */
    event productPurchased(
        address buyer,
        uint indexed productId,
        uint256 price,
        uint256 cQuantity
    );

    /**
     * @notice Emitted when a promotional code is successfully used.
     * @param user The address of the user who used the promo code.
     * @param productId The ID of the product for which the promo code was used.
     */
    event promoCodeSuccessfullyUsed(
        address indexed user,
        uint indexed productId
    );

    /**
     * @notice Constructor that sets the initial owner, commission, and collection manager.
     * @param initialOwner The address of the initial owner.
     * @param _commission The commission percentage.
     * @param _collectionManager The address of the CollectionManager contract.
     */
    constructor(address initialOwner, uint256 _commission, address _collectionManager) Ownable(initialOwner) {
        require(_commission <= 100, "Commission cannot exceed 100%");
        require(_collectionManager != address(0), "cannot be null");
        require(initialOwner != address(0));
        collectionManager = ICollectionManager(_collectionManager);
        commission = _commission;
    }

    /**
     *  @inheritdoc IMainContract
     */
    function setCollectionManager(address _newCollectionManager) public onlyOwner {
        collectionManager = ICollectionManager(_newCollectionManager);
    }
    
    /**
     *  @inheritdoc IMainContract
     */
    function buy(uint256 _id, uint256 _quantity) external payable nonReentrant {
        
        // Get price and quantity.
        uint256 price = collectionManager.getPrice(_id);
        uint256 cQuantity = collectionManager.getQuantity(_id);
        require(cQuantity >= _quantity, incorrectQuantity());

        // Calculate total price and commission.
        uint256 totalPrice = price * _quantity;
        require(msg.value >= totalPrice, notEnoughFunds());
        uint256 fundsForSeller = totalPrice - (totalPrice * commission) / 100;
        uint256 amountOfCommission = totalPrice - fundsForSeller;
    
        // Refund excess funds to the buyer (if any).
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        collectionManager._generatePromoCode(_quantity, _id, msg.sender);
        collectionManager.changeQuantityInStock(cQuantity-_quantity, _id);

        // Transfer funds for seller and comission for owner.
        payable(collectionManager.getOwnerByCollectionId(_id)).transfer(fundsForSeller);
        payable(owner()).transfer(amountOfCommission);
        
        emit productPurchased(msg.sender, _id, price, _quantity);
    }

    /**
     *  @inheritdoc IMainContract
     */
    function batchBuy (uint256[] calldata _ids, uint256[] calldata _quantities) external payable nonReentrant {
        require(_ids.length == _quantities.length, arraysMisMatch());
        // Limitation of the number of products in a transaction
        require(_ids.length <= 25);
        // require(!frezeCall[msg.sender]);

        // Initialize the total price
        uint totalPrice = 0;
        for(uint i = 0; i < _ids.length; i++) {
            require(_quantities[i] > 0, incorrectQuantity());
            uint256 cQuantity = collectionManager.getQuantity(_ids[i]);
            require(cQuantity >= _quantities[i], incorrectQuantity());

            uint price = (collectionManager.getPrice(_ids[i]))  * _quantities[i];
            totalPrice += price;

            collectionManager._generatePromoCode(_quantities[i], _ids[i], msg.sender);
            collectionManager.changeQuantityInStock(_ids[i], collectionManager.getQuantity(_ids[i])-_quantities[i]);

            // Transfer of funds to the seller
            payable(collectionManager.getOwnerByCollectionId(_ids[i])).transfer(price - price*commission /100);

            // Emit an event for the product purchased
            emit productPurchased(msg.sender, _ids[i],  price, _quantities[i]);
        }
        require(msg.value >= totalPrice, notEnoughFunds());
        uint256 fundsForSeller = totalPrice - (totalPrice * commission) / 100;
        uint amountOfCommission = totalPrice - fundsForSeller;
        
        // Refund excess funds to the buyer (if any).
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        // Transfer commission to the contract owner
        payable(owner()).transfer(amountOfCommission);
    }
}