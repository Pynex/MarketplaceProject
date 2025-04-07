// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { CollectionManager } from "../src/CollectionManager.sol";

contract Helper is Test{
    CollectionManager public collectionManager;

    function deployCollection(
        string memory _name,
        string memory _symbol,
        string memory _collectionURI,
        uint256 _price,
        uint256 _quantityInStock
    ) public returns(address, uint, uint) {
        vm.recordLogs();
        

        collectionManager.createCollection(
            _name,
            _symbol,
            _collectionURI,
            _price,
            _quantityInStock
        );


        Vm.Log[] memory entries = vm.getRecordedLogs();
        address newCollectionAddress = abi.decode(entries[0].data,(address));
        return(newCollectionAddress, _price, _quantityInStock);
    }

    function isValidSymbol(string calldata str) public pure returns (bool) {
    bytes memory b = bytes(str);
    if(b.length < 2) return false;
    
    for(uint i = 0; i < b.length; i++) {
        bytes1 char = b[i];
        // Разрешаем только A-Z, a-z, 0-9
        if(!(char >= 0x41 && char <= 0x5A) && // A-Z
           !(char >= 0x61 && char <= 0x7A) && // a-z
           !(char >= 0x30 && char <= 0x39)) { // 0-9
            return false;
        }
    }
    return true;
}
}