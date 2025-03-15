// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Errors {
    error NotEnoughFunds(uint price, uint getPrice);
    // error PromoUsedAlredy(bool used); мне кажется что данная ошибка не особо нужна, т.к у нас есть _isPromoValid который проверяет "А существует ли данный промокод", потому что после приминения они удаляются, тем самым нету необходимости проверять то что он был уже приминен, ведь те промокоды, которые применили - удалены 
    // error InvalidPromo(); есть invalidPromoCode
    error incorrectIdError(uint lastId, uint youId);
    error arraysMisMatch(uint ids, uint quantities);
    error inncorectIdInButchBuy(uint ids);
    // error ZeroCollectionAddress(); есть FailedToDeployContract
    error TokenNotExsist(address conllectionAddress);
    error FailedToDeployContract(bool deploy, address collectionAddress);
    error notEnoughProductsInStock(uint youWant, uint inStock);
    error invalidPromoCode(bool exsistPromoCode);
    // error notEnoughFunds(); есть NotEnoughFunds
    error incorrectSymbolLength(uint minimalSymbolLength, uint youSymbolLength);
    error incorrectURI(uint minimalURILength, uint youURILength);
    error incorrectPrice(uint minimalPrice, uint youPrice);
    error incorrectQuantity(uint minimalQuantity, uint youQuantity);
    error onlyMainContract(address mainContractAddress, address youAddress);
    error collectionNotFound(bool collectionExsist);
    error promoCodeNotFound(bool promoCodeExsist);
    error incorrectIndex(bytes8 promoCode, bool promoCodeExsist);
    error incorrectCollectionAddress(address mainContract, address getMainContract, bool valid);
    error incorrectNameLength(uint minimalNameLength, uint youNameLength, uint maxNameLength);
    error onlyCollectionOwner(address collectionCreator, address mainContract, address you);
    error incorrectAddress(address argumentAddress);
    error ZeroMainContractAddress(address mainContractAddress);
}
