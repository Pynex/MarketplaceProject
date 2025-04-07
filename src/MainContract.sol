// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./Errors.sol";
import {IMainContract} from "./IMainContract.sol";
import {CollectionManager} from "./CollectionManager.sol";
import {NewERC721Collection} from "./NewERC721Collection.sol";


/**
 * @title MainContract
 * @author Pynex, ivaaaaaaaaaaaa.
 * @notice The main contract for handling purchases and commissions. This contract allows users to buy NFTs,
 *         handles commission calculations, and interacts with the CollectionManager contract.
 */
contract MainContract is IMainContract, Ownable, ReentrancyGuard , Errors{

    /**
     * @notice The interface to the CollectionManager contract.
     */
    CollectionManager public collectionManager;

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
     * @notice The amount of marketplace commission (in %).  This value is immutable and set during construction.
     */
    uint256 public immutable commission;
    //collection address => collectionInfo
    // mapping(address=>)

    /**
     * @notice Emitted when a product is purchased.
     * @param buyer The address of the buyer.
     * @param collectionAddress The address of the purchased product.
     * @param price The price of the product.
     * @param cQuantity The quantity of the product purchased.
     */
    event productPurchased(
        address buyer,
        address indexed collectionAddress,
        uint256 price,
        uint256 cQuantity
    );

    /**
     * @notice Emitted when a promotional code is successfully used.
     * @param user The address of the user who used the promo code.
     * @param collectionAddress The address of the product for which the promo code was used.
     */
    event promoCodeSuccessfullyUsed(
        address indexed user,
        address indexed collectionAddress
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
        collectionManager = CollectionManager(_collectionManager);
        commission = _commission;
    }

    /**
     *  @inheritdoc IMainContract
     */
    function setCollectionManager(address _newCollectionManager) public onlyOwner {
        collectionManager = CollectionManager(_newCollectionManager);
    }
    
    /**
     *  @inheritdoc IMainContract
     */
    function buy(address _collectionAddress, uint256 _quantity) external payable nonReentrant {
        
        // Get price and quantity.
        uint256 price = getPrice(_collectionAddress);
        uint256 cQuantity = getQuantity(_collectionAddress);
        require(cQuantity >= _quantity, notEnoughProductsInStock(_quantity, cQuantity));

        // Calculate total price and commission.
        uint256 totalPrice = price * _quantity;
        require(msg.value >= totalPrice, NotEnoughFunds(totalPrice, msg.value));
        uint256 fundsForSeller = totalPrice - (totalPrice * commission) / 100;
        uint256 amountOfCommission = totalPrice - fundsForSeller;
    
        // Refund excess funds to the buyer (if any).
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        // _generatePromoCode(_quantity, _collectionAddress, msg.sender);
        // collectionManager.changeQuantityInStock(cQuantity-_quantity, _collectionAddress);

        // Transfer funds for seller and comission for owner.
        payable(getCollectionOwnerByAddress(_collectionAddress)).transfer(fundsForSeller);
        payable(owner()).transfer(amountOfCommission);
        
        emit productPurchased(msg.sender, _collectionAddress, price, _quantity);
    }

    /**
     *  @inheritdoc IMainContract
     */
    function batchBuy (address[] calldata _collectionAddresses, uint256[] calldata _quantities) external payable nonReentrant {
        uint ids = _collectionAddresses.length;
        uint quants = _quantities.length;
        require(_collectionAddresses.length == _quantities.length, arraysMisMatch(ids, quants));
        // Limitation of the number of products in a transaction
        require(_collectionAddresses.length <= 25);

        // Initialize the total price
        uint totalPrice = 0;
        for(uint i = 0; i < _collectionAddresses.length; i++) {
            uint quantiti = _quantities[i];
            address collectionAddress = _collectionAddresses[i];
            require(quantiti > 0, incorrectQuantity(1,0));
            uint256 cQuantity = getQuantity(collectionAddress);
            require(cQuantity >= quantiti, notEnoughProductsInStock(quantiti, cQuantity));

            uint price = (getPrice(collectionAddress))  * quantiti;
            totalPrice += price;

            _generatePromoCode(quantiti, collectionAddress, msg.sender);
            collectionManager.changeQuantityInStock(getQuantity(collectionAddress)-quantiti, collectionAddress);

            // Transfer of funds to the seller
            payable(getCollectionOwnerByAddress(collectionAddress)).transfer(price - price*commission /100);

            // Emit an event for the product purchased
            emit productPurchased(msg.sender, collectionAddress,  price, _quantities[i]);
        }
        require(msg.value >= totalPrice, NotEnoughFunds(totalPrice, msg.value));
        uint256 fundsForSeller = totalPrice - (totalPrice * commission) / 100;
        uint amountOfCommission = totalPrice - fundsForSeller;
        
        // Refund excess funds to the buyer (if any).
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        // Transfer commission to the contract owner
        payable(owner()).transfer(amountOfCommission);
    }

    /**
     *  @inheritdoc IMainContract
     */
    function redeemCode (address _collectionAddress, bytes8 _code) external payable {
        require(collectionManager.collectionExist(_collectionAddress), collectionNotFound(false));

        // Get collection contract.
        NewERC721Collection collection = NewERC721Collection(_collectionAddress);

        // Check if mainContract is valid.
        require(
            address(this) == collection.mainContract(),
            incorrectCollectionAddress(address(this), collection.mainContract(), false)
        );
        // Check if promo code is valud.
        require(_isPromoValid(_code) == true, invalidPromoCode(false));

        // Mint the NFT.
        collection.mint(msg.sender);

        // Delete promo code for user.
        _deletePromoCode(msg.sender, _code);

        // Emit event.
        emit promoCodeSuccessfullyUsed(msg.sender, _collectionAddress);
    }

    /**
     * @notice Checks if a given promo code is valid for the message sender.
     * @dev Iterates through the user's list of promo codes to find a match.
     * @param _promoCode The promo code to validate.
     * @return bool Returns true if the promo code is valid, false otherwise.
     */
    function _isPromoValid(bytes8 _promoCode) internal view returns (bool) {
        for (uint256 i = 0; i < uniqPromoForUser[msg.sender].length; ++i) {
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
     * @notice Generates unique promo codes for a specified user and collection.
     * @dev This function generates `_amount` unique promo codes associated with the provided user.
     *      It leverages a combination of blockchain parameters and user-specific data to create these codes,
     *      including blockhash, timestamp, sender, and collection address.
     *      Generated promo codes are stored in the `uniqPromoForUser` mapping, and the `codesCounter` is incremented.
     * @param _amount uint The number of promo codes to generate. Must be greater than 0.
     * @param collectionAddress address The address of the collection for which the promo codes will be used.
     * @param _user address The address of the user to whom the promo codes are generated. Cannot be the zero address.
     */
    function _generatePromoCode(uint _amount,address collectionAddress, address _user) internal {
        require(_user != address(0),incorrectAddress(address(0)));
        require(_amount > 0, incorrectQuantity(1,0));
        uint counter = codesCounter[msg.sender];
        
        for (uint i = 0; i < _amount ; i++) {
        bytes8 random = bytes8(
            keccak256(abi.encode((blockhash(block.number - i)),block.timestamp,counter,msg.sender,collectionAddress, i, tx.origin,
            block.prevrandao)));
        uniqPromoForUser[_user].push(random);
        codesCounter[msg.sender]++;
        }
    }


    //////////////////////////////////////////////////////
    //  get functions
    //////////////////////////////////////////////////////

    /**
     *  @inheritdoc IMainContract
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

    /**
     *  @inheritdoc IMainContract
     */
    function getQuantity(address _collectionAddress) public view returns (uint256) {
        return collectionManager.getCollectionByAddress(_collectionAddress).quantityInStock;
    }

    /**
     *  @inheritdoc IMainContract
     */
    function getPrice(address _collectionAddress) public view returns (uint256) {
        return collectionManager.getCollectionByAddress(_collectionAddress).price;
    }

    /**
     *  @inheritdoc IMainContract
     */
    function getCollectionOwnerByAddress(address _collectionAddress) public view returns (address) {
        return collectionManager.getCollectionByAddress(_collectionAddress).collectionOwner;
    }
}