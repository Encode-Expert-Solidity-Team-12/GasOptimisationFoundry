// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    address _owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;


    mapping(address => uint256) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(checkForAdmin(msg.sender) || _owner == msg.sender, "Caller not admin");
        _;
    }

    modifier checkIfWhiteListed() {
        require( whitelist[msg.sender] > 0, "Not whitelisted");
        _;
    }


    constructor(address[] memory _admins, uint256 _totalSupply) {
        _owner = msg.sender;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            address ad = _admins[ii];
            if (ad != address(0)) {
                administrators[ii] = ad;
                if (ad == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient Balance"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require( _tier < 255, "tier greater than 255");
        uint256 tier = _tier;
        if(tier > 3) tier = 3;
        whitelist[_userAddrs] = tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed() {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient Balance"
        );
        require(
            _amount > 3,
            "amount less than 3"
        );

        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) public view returns (bool, uint256) {        
        uint256 a = whiteListStruct[sender];
        return (a > 0, a);
    }
}