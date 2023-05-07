// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    address private immutable _owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address indexed userAddress, uint256 indexed tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(_owner == msg.sender || checkForAdmin(msg.sender), "Caller not admin");
        _;
    }

    modifier checkIfWhiteListed() {
        require( whitelist[msg.sender] > 0, "Not whitelisted");
        _;
    }


    constructor(address[] memory _admins, uint256 _totalSupply) {
        _owner = msg.sender;

        for (uint256 ii; ii < administrators.length; ii++) {
            address ad = _admins[ii];
            if (ad != address(0)) {
                administrators[ii] = ad;
                if (ad == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                }
            }
        }
    }

    function checkForAdmin(address _user) private view returns (bool admin_) {
        for (uint256 ii; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin_ = true;
            }
        }
        admin_ = false;
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external  {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient Balance"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        external
        onlyAdminOrOwner
    {
        require( _tier < 255, "tier greater than 255");
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external checkIfWhiteListed() {
        require(
            _amount > 3,
            "amount less than 3"
        );

        require(
            balances[msg.sender] >= _amount,
            "Insufficient Balance"
        );


        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) external view returns (bool biggerThan0, uint256 val) {
        val = whiteListStruct[sender];
        biggerThan0 = val > 0;
    }
}