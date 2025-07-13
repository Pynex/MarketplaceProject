# NFT Marketplace Smart Contract Documentation

## Overview

This NFT marketplace system consists of three main smart contracts that work together to provide a complete NFT marketplace experience:

1. **CollectionManager** - Handles creation and management of NFT collections
2. **MainContract** - Manages purchases, commissions, and promotional codes
3. **NewERC721Collection** - Individual ERC721 NFT collections

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  MainContract   │◄───┤CollectionManager│◄───┤NewERC721Collection│
│                 │    │                 │    │                 │
│ - Purchases     │    │ - Create NFTs   │    │ - Mint tokens   │
│ - Commissions   │    │ - Manage info   │    │ - Token URIs    │
│ - Promo codes   │    │ - Price/Stock   │    │ - Ownership     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Contract Details

### 1. CollectionManager

**Purpose**: Manages the creation and administration of NFT collections.

#### Key Features
- Create new ERC721 collections
- Store collection metadata and configuration
- Update collection prices and stock quantities
- Track collections by creator

#### Core Functions

##### `createCollection()`
```solidity
function createCollection(
    string memory _name,
    string memory _symbol,
    string memory _collectionURI,
    uint256 _price,
    uint256 _quantityInStock
) external payable
```
Creates a new NFT collection with specified parameters.

**Parameters:**
- `_name`: Collection name (1-64 characters)
- `_symbol`: Collection symbol (1-8 characters)
- `_collectionURI`: Base URI for metadata
- `_price`: Price per NFT in wei
- `_quantityInStock`: Initial stock quantity

**Requirements:**
- Name length: 1-64 characters
- Symbol length: 1-8 characters
- URI must not be empty
- Price must be greater than 0

##### `getCollectionByAddress()`
```solidity
function getCollectionByAddress(address _collectionAddress) 
    external view returns (CollectionInfo memory)
```
Retrieves complete collection information by contract address.

##### `changePrice()` / `changeQuantityInStock()`
```solidity
function changePrice(uint _newPrice, address _collectionAddress) 
    public payable onlyCreator(_collectionAddress)
```
Updates collection price or stock quantity. Only accessible by collection creator or main contract.

#### Data Structures

```solidity
struct CollectionInfo {
    string name;
    string symbol;
    address collectionOwner;
    string collectionURI;
    uint256 price;
    uint256 quantityInStock;
    address collectionAddress;
}
```

#### Events

```solidity
event CollectionCreated(
    address newCollectionAddress,
    address collectionOwner,
    string collectionURI,
    string collectionName,
    uint256 price,
    uint amountOfStock
);
```

---

### 2. MainContract

**Purpose**: Handles NFT purchases, commission distribution, and promotional code management.

#### Key Features
- Individual and batch NFT purchases
- Commission calculation and distribution
- Promotional code generation and redemption
- Reentrancy protection

#### Core Functions

##### `buy()`
```solidity
function buy(address _collectionAddress, uint256 _quantity) 
    external payable nonReentrant
```
Purchases NFTs from a specific collection.

**Process:**
1. Validates stock availability
2. Calculates total price including commission
3. Generates promotional codes
4. Updates stock quantity
5. Distributes funds to seller and platform

##### `batchBuy()`
```solidity
function batchBuy(address[] memory _collectionAddresses, uint256[] memory _quantities) 
    external payable nonReentrant
```
Purchases multiple NFTs from different collections in a single transaction.

**Limitations:**
- Maximum 25 collections per transaction
- Arrays must have matching lengths

##### `redeemCode()`
```solidity
function redeemCode(address _collectionAddress, bytes8 _code) 
    external payable
```
Redeems a promotional code to mint an NFT.

**Process:**
1. Validates collection existence
2. Verifies promotional code validity
3. Mints NFT to user
4. Removes used promotional code

#### Commission System

The platform charges a configurable commission on all sales:
- Commission rate set at contract deployment (max 100%)
- Automatically deducted from seller proceeds
- Transferred to platform owner

#### Promotional Code System

- Generated automatically upon purchase
- Unique codes created using blockchain entropy
- One code per NFT purchased
- Codes are user-specific and single-use

#### Events

```solidity
event productPurchased(
    address buyer,
    address indexed collectionAddress,
    uint256 price,
    uint256 cQuantity
);

event promoCodeSuccessfullyUsed(
    address indexed user,
    address indexed collectionAddress
);
```

---

### 3. NewERC721Collection

**Purpose**: Individual ERC721 NFT collection contract with marketplace integration.

#### Key Features
- Standard ERC721 functionality
- Integration with main contract for minting
- Metadata URI management
- Access control for minting

#### Core Functions

##### `mint()`
```solidity
function mint(address _to) external onlyMainContract
```
Mints a new NFT to the specified address. Only callable by the main contract.

##### `tokenURI()`
```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory)
```
Returns the metadata URI for a specific token ID.

#### Access Control
- Only the main contract can mint new tokens
- Prevents unauthorized token creation
- Ensures integration with marketplace purchase flow

---

## Security Features

### Access Control
- **Ownable**: Platform owner controls for configuration
- **Creator-only**: Collection creators can modify their collections
- **Main contract restriction**: Only main contract can mint NFTs

### Reentrancy Protection
- **ReentrancyGuard**: Prevents reentrancy attacks on purchase functions
- Applied to all payable functions that modify state

### Input Validation
- String length limits for names and symbols
- Address zero checks
- Price and quantity validations
- Array length matching for batch operations

### Fund Management
- Automatic excess refunds to buyers
- Secure commission distribution
- Protected fund transfers

## Usage Examples

### Creating a Collection
```solidity
// Deploy CollectionManager and MainContract first
CollectionManager manager = new CollectionManager(owner);
MainContract main = new MainContract(owner, 5, address(manager)); // 5% commission

// Create a collection
manager.createCollection(
    "My NFT Collection",
    "MNC",
    "https://api.example.com/metadata/",
    1 ether,
    1000
);
```

### Purchasing NFTs
```solidity
// Single purchase
mainContract.buy{value: 1 ether}(collectionAddress, 1);

// Batch purchase
address[] memory collections = [collection1, collection2];
uint256[] memory quantities = [2, 3];
mainContract.batchBuy{value: 5 ether}(collections, quantities);
```

### Redeeming Promotional Codes
```solidity
// Redeem a promotional code
mainContract.redeemCode(collectionAddress, promoCode);
```

## Configuration

### Deployment Parameters
- **Commission Rate**: 0-100% (set during MainContract deployment)
- **Collection Limits**: Name (64 chars), Symbol (8 chars)
- **Batch Purchase Limit**: 25 collections per transaction

### Admin Functions
- `setMainContract()`: Update main contract address
- `setCollectionManager()`: Update collection manager address

## Error Handling

The system includes comprehensive error handling with custom error messages:
- Collection existence validation
- Stock availability checks
- Payment sufficiency verification
- Input parameter validation
- Access control enforcement

## Gas Optimization

- Efficient data structures
- Minimal external calls
- Batch operations support
- Optimized storage patterns

---

## License

This project is licensed under the MIT License.
