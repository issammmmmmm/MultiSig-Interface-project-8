// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    uint public requiredConfirmations;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint confirmations;
    }

    Transaction[] public transactions;
    mapping(address => bool) public isOwner;
    mapping(uint => mapping(address => bool)) public confirmations;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Tx does not exist");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!confirmations[_txIndex][msg.sender], "Already confirmed");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Already executed");
        _;
    }

    constructor(address[] memory _owners, uint _requiredConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(_requiredConfirmations > 0 && _requiredConfirmations <= _owners.length, "Invalid number of confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner], "Owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransaction(address _to, uint _value) public onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            executed: false,
            confirmations: 0
        }));
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        confirmations[_txIndex][msg.sender] = true;
        transactions[_txIndex].confirmations += 1;

        if (transactions[_txIndex].confirmations >= requiredConfirmations) {
            executeTransaction(_txIndex);
        }
    }

    function executeTransaction(uint _txIndex)
        internal
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(address(this).balance >= transaction.value, "Not enough balance");

        transaction.executed = true;
        payable(transaction.to).transfer(transaction.value);
    }

    receive() external payable {}
}
