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

    address[4] public signers = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906
    ];

    function setUp() public {
        collectionManager = new CollectionManager(signers[0]);
        address cmAddress = address(collectionManager);
        mainContract = new MainContract(signers[0], 0, cmAddress);
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
        NewERC721Collection collection = new NewERC721Collection(
            "a",
            "XYZ",
            "ipfs/...",
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
        vm.assertEq(check, "ipfs/...");

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

    function testBuy() public{
        uint balance = address(this).balance;
        (address _newCollection, uint _price, uint _amount) = Helper.deployCollection("a", "b", "c", 1 gwei, 10);


        console.log(address(this).balance);
        vm.deal(signers[1], 10 ether);
        console.log(signers[1].balance);
        vm.prank(signers[1]);
        mainContract.buy{value:1 ether}(_newCollection, _amount);
        console.log(address(this).balance);

        // bytes4 selector = bytes4(keccak256("buy(address, uint256)"));
        // bytes memory data = abi.encodeWithSelector(selector, _newCollection, _quantity);

        // (bool success, ) = address(mainContract).call{value: 1 ether}(data);
        // vm.assertTrue(success);
        uint qBalance = address(this).balance;
        vm.assertEq(balance+_price*_amount, qBalance);
        vm.assertEq(mainContract.getQuantity(_newCollection), 0);
    }
}