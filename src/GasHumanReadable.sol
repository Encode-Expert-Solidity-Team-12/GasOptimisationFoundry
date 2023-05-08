// Team 12: 349136
// 2023/08/05 Uros, Frank and Alice owe Raouf 2 Beers each
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

error bad();

contract GasContract {
    address private immutable _owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address  userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        _owner = msg.sender;
        balances[msg.sender] = _totalSupply;
        administrators[0] = _admins[0];
        administrators[1] = _admins[1];
        administrators[2] = _admins[2];
        administrators[3] = _admins[3];
        administrators[4] = _admins[4];
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external  {
        if(balances[msg.sender] < _amount) {
            revert bad();
        }
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        external
    {
        if(_owner != msg.sender) revert bad();
        if(_tier > 254) revert bad();
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external
    {
        if(whitelist[msg.sender] == 0) revert bad();
        if(_amount < 4) revert bad();
        if(balances[msg.sender] < _amount) revert bad();

        uint256 a = _amount - whitelist[msg.sender];
        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] -= a;
        balances[_recipient] += a;

        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) external view returns (bool biggerThan0, uint256 val) {
        val = whiteListStruct[sender];
        biggerThan0 = true;
    }
}