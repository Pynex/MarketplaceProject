// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { CollectionManager } from "../src/CollectionManager.sol";
import {NewERC721Collection} from "../src/NewERC721Collection.sol";
// import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MainContract} from "../src/MainContract.sol";
import {Errors} from "../src/Errors.sol";
import {Helper} from "../test/Helper.sol";

contract MarketPlaceTest is Test,Helper {
    MainContract public mainContract;
    address collectionManagerAddress;


    event CollectionCreated(
        address newCollectionAddress,
        address collectionOwner,
        string collectionURI,
        string collectionName,
        uint256 price,
        uint amountOfStock
    );

    address[6] public signers = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906,
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
        0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
    ];

    function setUp() public {
        collectionManager = new CollectionManager(signers[0]);
        address cmAddress = address(collectionManager);
        mainContract = new MainContract(signers[0], 10, cmAddress);
        vm.prank(signers[0]);
        address mcAddress = address(mainContract);
        collectionManager.setMainContract(mcAddress);
        vm.deal(address(this), 10 ether);
    }

    ///////////////////////////
    // CollectionManager Test
    ///////////////////////////

    function testCreateCollection() public {
        vm.prank(signers[1]);
        vm.recordLogs();

        collectionManager.createCollection("classical","CLS","ipfs/...",100000000000000000, 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (address collectionAddress) = abi.decode(entries[0].data,(address));
        collectionManagerAddress = collectionAddress;

        vm.assertTrue(entries.length > 0);
        ////////////////////////////////////////////////
        CollectionManager.CollectionInfo memory info = collectionManager.getCollectionByAddress(collectionAddress);
        vm.assertEq(info.name, "classical");
        /////////////////////////////////////////////////
        bool check = collectionManager.collectionExist(collectionAddress);
        vm.assertTrue(check);
        /////////////////////////////////////////////////
        vm.expectRevert();
        collectionManager.getCollectionByAddress(signers[0]);
        ///////////////////////////////////////////////// 
        // Negative 
        /////////////////////////////////////////////////

        CollectionManager.CollectionInfo[] memory infoes = collectionManager.getCollectionOwnerByAddressOwner(signers[1]);
        vm.assertEq(infoes.length, 1);
        vm.assertEq(infoes[0].name, "classical");

        vm.expectRevert();
        collectionManager.getCollectionOwnerByAddressOwner(address(0));

        vm.expectRevert(abi.encodeWithSelector(Errors.incorrectPrice.selector, 1, 0));
        collectionManager.createCollection("classical","CLS","ipfs/...", 0, 100);

        vm.expectRevert(abi.encodeWithSelector(Errors.incorrectNameLength.selector, 1, 0, 64));
        collectionManager.createCollection("","CLS","ipfs/...",100000000000000000, 100);

        vm.expectRevert(abi.encodeWithSelector(Errors.incorrectSymbolLength.selector, 1, 0));
        collectionManager.createCollection("classical","","ipfs/...",100000000000000000, 100);
        
        vm.expectRevert(abi.encodeWithSelector(Errors.incorrectURI.selector, 1, 0));
        collectionManager.createCollection("classical","CLS","",100000000000000000, 100);
    }

    function testConstructor() public {
        address owner = signers[0];
        CollectionManager newManager = new CollectionManager(owner);
        vm.assertEq(newManager.owner(), owner);

        vm.expectRevert(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);
        new CollectionManager(address(0));
    }
    
    function testSetMainContract() public {
        vm.prank(signers[0]);
        vm.expectRevert();
        collectionManager.setMainContract(address(0));

        vm.prank(signers[0]);
        collectionManager.setMainContract(signers[2]);

        vm.prank(address(0));
        vm.expectRevert();
        collectionManager.setMainContract(signers[2]);
    }

    function testChangeValues(uint _newPrice, uint _newQuantity) public {
        address collectionOwner = signers[1];
        vm.startPrank(collectionOwner);
        vm.assume(_newPrice <= type(uint256).max - _newPrice && _newPrice > 0);
        vm.assume(_newQuantity <= type(uint256).max - _newQuantity);

        (address newCollectionAddress, uint rPrice, uint rQuantity) = Helper.deployCollection("Pepe", "Pepe","ipfs/p12321njk", _newPrice, _newQuantity);

        collectionManager.changePrice(_newPrice, newCollectionAddress);

        vm.expectRevert();
        collectionManager.getCollectionByAddress(address(0));

        vm.assertEq(rPrice, _newPrice);
        vm.startPrank(address(mainContract));

        collectionManager.changeQuantityInStock(_newQuantity, newCollectionAddress);
        vm.assertEq(rQuantity, _newQuantity);
        //negative

        vm.startPrank(address(0));
        vm.expectRevert();
        collectionManager.changeQuantityInStock(_newQuantity, newCollectionAddress);
    } 

    ///////////////////////////
    //NewErc721Collection Test
    ///////////////////////////

    function testNFTdeploy() public {
        ///negative
        address owner = collectionManager.owner();
        address MC = collectionManager.mainContract();
        vm.expectRevert();
        new NewERC721Collection(
            "a",
            "XYZ",
            "ipfs/...",
            address(0),
            owner,
            MC
        );

        vm.expectRevert();
        new NewERC721Collection(
            "a",
            "XYZ",
            "ipfs/...",
            msg.sender,
            address(0),
            MC
        );

        vm.expectRevert();
        new NewERC721Collection(
            "a",
            "XYZ",
            "ipfs/...",
            msg.sender,
            owner,
            address(0)
        );
    }

    function testMint_Approval_BaseUriAndTokenUri() public {
        vm.startPrank(address(mainContract));
        string memory URI = "ipfs/...";
        NewERC721Collection collection = new NewERC721Collection(
            "a",
            "XYZ",
            URI,
            msg.sender,
            collectionManager.owner(),
            collectionManager.mainContract()
        );

        collection.mint(signers[2]);
        uint balance = collection.balanceOf(signers[2]);
        vm.assertEq(balance, 1);

        vm.stopPrank();
        vm.prank(signers[2]);
        collection.setApprovalForAll(signers[1], true);

        vm.prank(signers[1]);
        collection.safeTransferFrom(signers[2], signers[0], 1);
        vm.assertEq(collection.balanceOf(signers[0]), 1);

        string memory uri = collection.tokenURI(5);
        console.log(uri);

        string memory check = collection.getBaseURI();
        vm.assertEq(check, URI);

        //negative
        vm.stopPrank();
        vm.prank(signers[1]);
        vm.expectRevert();
        collection.mint(signers[0]);
    }
    ///////////////////////////
    //MainContract Test
    ///////////////////////////

    function testMCConstructor () public {
        //negative 
        vm.expectRevert();
        new MainContract(address(0),50, signers[1]);

        vm.expectRevert();
        new MainContract(signers[1],150, signers[1]);

        vm.expectRevert();
        new MainContract(signers[1],50, address(0));
    }

    function testSetCollectionManager (address newCM) public {
        mainContract = new MainContract(address(this), 5, signers[1]);
        mainContract.setCollectionManager(newCM);
    }

    function testBuyAndRedeemCode() public {
        vm.prank(signers[1]);
        vm.recordLogs();
        uint _price = 1 ether;

        collectionManager.createCollection("classical","CLS","ipfs/...",_price, 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (address collectionAddress) = abi.decode(entries[0].data,(address));


        vm.deal(signers[3], 10 ether);
        vm.startPrank(signers[3]);
        mainContract.buy{value:5 ether}(collectionAddress, 1);

        uint expectedBalance3acc = 9 ether;
        console.log("first account balance after buy:", signers[1].balance);
        vm.assertEq(signers[3].balance, expectedBalance3acc);
        uint expectedBalance0acc = _price*10/100; // 10% comission
        vm.assertEq(signers[0].balance, expectedBalance0acc);

        //redeemcodeTest
        bytes8 code = 0xc91ca672d41b1783;
        // vm.expectRevert();
        mainContract.redeemCode(collectionAddress, code);

        //negative reddemcodeTest
        
        //negative

        vm.expectRevert(abi.encodeWithSelector(Errors.notEnoughProductsInStock.selector, 1000, 99));
        mainContract.buy{value:9 ether}(collectionAddress, 1000);

        vm.expectRevert(abi.encodeWithSelector(Errors.NotEnoughFunds.selector, 1 ether, 50000));
        mainContract.buy{value: 50000}(collectionAddress, 1);
    }

    function testBatchBuy() public {
        vm.startPrank(signers[1]);
        vm.recordLogs();
        uint _price0 = 1 ether;

        collectionManager.createCollection("classical","CLS","ipfs/...",_price0, 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (address collectionAddress0) = abi.decode(entries[0].data,(address));

        vm.startPrank(signers[2]);
        vm.recordLogs();
        uint _price1 = 3 ether;

        collectionManager.createCollection("Pepe","Pepe","ipfs/...",_price1, 100);

        Vm.Log[] memory entries1 = vm.getRecordedLogs();
        (address collectionAddress1) = abi.decode(entries1[0].data,(address));
        console.log(collectionAddress1);

        address[] memory transmittedAddresses = new address[](2);
        transmittedAddresses[0] = collectionAddress0;
        transmittedAddresses[1] = collectionAddress1;
        
        uint[] memory transmittedNums = new uint256[](2);
        transmittedNums[0] = 1;
        transmittedNums[1] = 3;

        console.log(signers[3].balance);
        vm.deal(signers[3], 15 ether);
        vm.startPrank(signers[3]);
        mainContract.batchBuy{value:12 ether}(transmittedAddresses, transmittedNums);
        vm.assertEq(signers[3].balance, 5 ether);
        uint exQuantiti0 = mainContract.getQuantity(collectionAddress0);
        vm.assertEq(exQuantiti0, 99);

        uint exQuantiti1 = mainContract.getQuantity(collectionAddress1);
        vm.assertEq(exQuantiti1, 97);

        //negative 

        vm.deal(signers[4], 15 ether);
        vm.startPrank(signers[4]);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotEnoughFunds.selector, 10 ether, 1 ether));
        mainContract.batchBuy{value:1 ether}(transmittedAddresses, transmittedNums);

        address[] memory transmittedAddressesMissmatch = new address[](2);
        transmittedAddressesMissmatch[0] = collectionAddress0;
        transmittedAddressesMissmatch[1] = collectionAddress1;
        
        uint[] memory transmittedNumsMissmatch = new uint256[](3);
        transmittedNumsMissmatch[0] = 1;
        transmittedNumsMissmatch[1] = 3;
        transmittedNumsMissmatch[2] = 3;

        vm.expectRevert(abi.encodeWithSelector(Errors.arraysMisMatch.selector,
        transmittedAddressesMissmatch.length, transmittedNumsMissmatch.length));
        // vm.expectRevert();
        mainContract.batchBuy{value:1 ether}(transmittedAddressesMissmatch, transmittedNumsMissmatch);


        address[] memory transmittedAddressesOver25 = new address[](30);
        uint[] memory transmittedNumsOver25 = new uint256[](30);

        vm.expectRevert(abi.encodeWithSelector(Errors.tooManyProductsToBuy.selector,
        25, transmittedNumsOver25.length));

        mainContract.batchBuy{value:1 ether}(transmittedAddressesOver25, transmittedNumsOver25);

        address[] memory transmittedAddressesIncQuan = new address[](1);
        transmittedAddressesIncQuan[0] = collectionAddress0;
        uint[] memory transmittedNumsIncQuan = new uint256[](1);
        transmittedNumsIncQuan[0] = 0;

        vm.expectRevert(abi.encodeWithSelector(Errors.incorrectQuantity.selector, 1, 0));
        mainContract.batchBuy{value:1 ether}(transmittedAddressesIncQuan, transmittedNumsIncQuan);

        vm.deal(signers[5], 15000 ether);
        vm.startPrank(signers[5]);

        address[] memory transmittedAddressesOverQuan = new address[](1);
        transmittedAddressesOverQuan[0] = collectionAddress1;
        uint[] memory transmittedNumsOverQuan = new uint256[](1);
        transmittedNumsOverQuan[0] = 101;

        uint exQuantity = mainContract.getQuantity(collectionAddress1);
        vm.expectRevert(abi.encodeWithSelector(Errors.notEnoughProductsInStock.selector, 101, exQuantity));
        mainContract.batchBuy{value:500 ether}(transmittedAddressesOverQuan, transmittedNumsOverQuan);
    }


    // function testGetQuantity() public {
    //     mainContract.getQuantity(address(0));
    // }
}