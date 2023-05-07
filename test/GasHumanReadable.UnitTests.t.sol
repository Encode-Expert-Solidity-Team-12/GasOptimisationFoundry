// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/GasHumanReadable.sol";

contract GasTest is Test {
    GasContract public gas;
    uint256 public totalSupply = 1000000000;
    address owner = address(0x1234);
    address addr1 = address(0x5678);
    address addr2 = address(0x9101);
    address addr3 = address(0x1213);

    address[] admins = [
        address(0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2),
        address(0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46),
        address(0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf),
        address(0xeadb3d065f8d15cc05e92594523516aD36d1c834), 
        owner
    ];

    //deploys contract from the owner's account
    //REQUIRES CONSTRUCTOR THAT TAKES 2 PARAMETERS (address[] admins, uint256 totalSupply)
    function setUp() public {
        vm.startPrank(owner);
        gas = new GasContract(admins, totalSupply);
        vm.stopPrank();
    }

    //checks that deployed contracts has the expected administrators
    //REQUIRES ARRAY administrators OF TYPE address[] - can be defined at onset if not modified in later tests
    function test_admins() public {
        for (uint8 i = 0; i < admins.length; ++i) {
            assertEq(admins[i], gas.administrators(i));
        }
    } 
    
    //Checks addToWhiteList can't be called if not owner
    //REQUIRES AddToWhitelist FUNCTION WHICH TAKES 2 PARAMETERS (address user, uint256 tier) AND RESTRICTED TO OWNER ONLY
    function test_onlyOwner(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.expectRevert();
        gas.addToWhitelist(_userAddrs, _tier);
    }

    //Checks addToWhiteList works if called by owner
    //REQUIRES AddToWhitelist FUNCTION WHICH TAKES 2 PARAMETERS (address user, uint256 tier) AND RESTRICTED TO OWNER ONLY
    function test_tiers(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.prank(owner);
        gas.addToWhitelist(_userAddrs, _tier);
    }

    // Expect Event --> 
    //Checks that addToWhiteList() emits event AddedToWhiteList with correct values
    //REQUIRES AddToWhitelist FUNCTION TO EMIT AddedToWhitelist EVENT WITH 2 PARAMETERS (address user, uint256 tier)
    event AddedToWhitelist(address userAddress, uint256 tier);
    function test_whitelistEvents(address _userAddrs, uint256 _tier) public {
        vm.startPrank(owner);
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.expectEmit(true, true, false, true); //bools determines which event values are checked - in this case checks indexed params 0 (by default), 1 & 2 (first 2 bools), doesn't check indexed param 3, and checks the data (ie tier) 
        emit AddedToWhitelist(_userAddrs, _tier);
        gas.addToWhitelist(_userAddrs, _tier);
        vm.stopPrank();
    }


    //----------------------------------------------------//
    //------------- Test whitelist Transfers -------------//
    //----------------------------------------------------//

    //Checks that whiteTransfer() creates new entry in struct Payment[] with bool and amount
    //REQUIRES 
        //balanceOf FUNCTION WHICH TAKES 1 PARAMETER (address user) AND RETURNS UINT256 balance
        //transfer FUNCTION WHICH TAKES 3 PARAMETERS (address recipient, uint256 amount, string name)
        //addToWhitelist FUNCTION WHICH TAKES 2 PARAMETERS (address user, uint256 tier)
        //whiteTransfer FUNCTION WHICH TAKES 2 PARAMETERS (address recipient, uint256 amount)
        //getPaymentStatus FUNCTION WHICH TAKES 1 PARAMETER (address sender) AND RETURNS 2 VALUES (bool status, uint256 amount)
    function test_whitelistTransfer(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {
        _amount = bound(_amount,0 , gas.balanceOf(owner));
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 );
        _tier = bound( _tier, 1, 244);
        //owner sends some tokens? to sender and adds sender to whitelist
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        //sender transfers to recipient
        vm.prank(_sender);
        gas.whiteTransfer(_recipient, _amount);
        //checks getPaymentStatus returns the correct values
        (bool a, uint256 b) = gas.getPaymentStatus(address(_sender));
        console.log(a);
        assertEq(a, true);
        assertEq(b, _amount);
    }

    // Reverts if teirs out of bounds (> 254)
    // REQUIRES addToWhitelist function WHICH TAKES 2 PARAMETERS (address user, uint256 tier). UINT256 tier RESTRICTED TO <= 254
    function test_tiersReverts(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        vm.assume(_tier > 254);
        vm.prank(owner);
        vm.expectRevert();
        gas.addToWhitelist(_userAddrs, _tier);
    }

    // Expect Event --> 
    //Checks that whiteTransfer() emits event WhiteListTransfer with one value: recipient address
    //REQUIRES
        //balanceOf FUNCTION WHICH TAKES 1 PARAMETER (address user) AND RETURNS UINT256 balance
        //transfer FUNCTION WHICH TAKES 3 PARAMETERS (address recipient, uint256 amount, string name)
        //addToWhitelist function WHICH TAKES 2 PARAMETERS (address user, uint256 tier)
        //whiteTransfer WHICH TAKES 2 PARAMETERS (address recipient, uint256 amount) AND EMITS EVENT WhitelistTransfer WITH 1 PARAMETER (address recipient)
    event WhiteListTransfer(address indexed);
    function test_whitelistEvents(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {

        _amount = bound(_amount,0 , gas.balanceOf(owner));
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 );
        _tier = bound( _tier, 1, 244);
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        vm.startPrank(_sender);
        vm.expectEmit(true, false, false, true);
        emit WhiteListTransfer(_recipient);
        gas.whiteTransfer(_recipient, _amount);
        vm.stopPrank();
    }

        /* whiteTranfer balance logic. 
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx]; 
        */

    // check balances update 
    //REQUIRES
        //balances[] MAPPING OF USER ADDRESS TO BALANCE
        //whitelist[] MAPPING OF USER ADDRESS TO WHITELIST AMOUNT - test should work without writing anything to it in contract
        //balanceOf FUNCTION WHICH TAKES 1 PARAMETER (address user) AND RETURNS UINT256 balance
        //transfer FUNCTION WHICH TAKES 3 PARAMETERS (address recipient, uint256 amount, string name)
        //addToWhitelist function WHICH TAKES 2 PARAMETERS (address user, uint256 tier)
        //whiteTransfer WHICH TAKES 2 PARAMETERS (address recipient, uint256 amount) AND UPDATES THE balances[] MAPPING AS FOLLOWS:
            // AT SENDER ADDRESS: DEDUCTS BALANCE BY AMOUNT TRANSFERED AND ADDS SENDER WHITELIST AMOUNT
            // AT RECIPIENT ADDRESS: ADDS BALANCE BY AMOUNT TRANSFERED AND DEDUCTS SENDER WHITELIST AMOUNT
    function testWhiteTranferAmountUpdate(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {
        uint256 _preRecipientAmount = gas.balances(_recipient) + 0;
        vm.assume(_recipient != address(0));
        vm.assume(_sender != address(0));
         _amount = bound(_amount,0 , gas.balanceOf(owner));
        _tier = bound( _tier, 1, 244);
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 && bytes(_name).length >0);
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        uint256 _preSenderAmount = gas.balances(_sender);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        vm.prank(_sender);
        gas.whiteTransfer(_recipient, _amount);
        assertEq(gas.balances(_sender), (_preSenderAmount - _amount) + gas.whitelist(_sender));
        assertEq(gas.balances(_recipient),(_preRecipientAmount + _amount) - gas.whitelist(_sender));
    }


}

