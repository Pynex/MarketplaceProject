# Marketplace Project - Decentralized NFT Marketplace

A decentralized NFT marketplace on Ethereum for secure trading and collection management.

## Features

*   Create & Manage NFT Collections
*   Secure NFT Trading
*   Promo Code Functionality
*   Automated Commission Handling
*   Transparent & Decentralized

## Structure
MarketplaceProject/
├── contracts/        
│   ├── MainContract.sol
│   ├── CollectionManager.sol
│   ├── IcollectionManager.sol
│   ├── IMainContract.sol
│   ├── Errors.sol
│   └── NewERC721Collection
├── abi/             
│   ├── Ma1nContract.json
│   ├── CollectionManager.json
│   └── ... 
|──Tasks/
|  └──Sample.task.ts
├──hardhat.config.ts 
├── package.json      
├── README.md                 
└── .gitignore        


## Tech

*   Solidity, Ethereum
*   ERC-721 NFTs
*   Hardhat
*   OpenZeppelin

## License

MIT License.

## Deployment Instructions
* Deploy the CollectionManager contract. During deployment, specify the owner address in the constructor. This address will have administrator privileges for the contract.
* Deploy the MainContract contract. During deployment, specify the following in the constructor:
    Owner address: Use the same owner address as you used when deploying CollectionManager.
    Platform commission: Specify the commission in percentage (e.g., 5 for 5%).
    CollectionManager address: Specify the address of the deployed CollectionManager contract.
* After deploying the MainContract, call the setMainContract function in the CollectionManager contract, passing in the address of the deployed MainContract. This will enable the contracts to communicate with each other.

Success!
