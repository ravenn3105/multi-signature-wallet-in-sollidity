solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSignatureWallet {
    // Variables
    address[] public owners;
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    // Struct to represent a transaction
    struct Transaction {
        address destination;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }

    // Events
    event TransactionProposed(uint256 indexed transactionId, address indexed destination, uint256 amount, address indexed proposer);
    event TransactionApproved(uint256 indexed transactionId, address indexed approver);

    // Modifiers
    modifier onlyOwners() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    modifier transactionExists(uint256 _transactionId) {
        require(_transactionId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _transactionId) {
        require(!transactions[_transactionId].executed, "Transaction already executed");
        _;
    }

    // Constructor
    constructor(address[] memory _owners) {
        require(_owners.length == 3, "Must provide exactly three owners");
        owners = _owners;
    }

    // Function to check if an address is an owner
    function isOwner(address _address) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to propose a transaction
    function proposeTransaction(address _destination, uint256 _amount) external onlyOwners {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: _destination,
            amount: _amount,
            approvals: 0,
            executed: false
        });

        transactionCount++;

        emit TransactionProposed(transactionId, _destination, _amount, msg.sender);
    }

    // Function to approve a transaction
    function approveTransaction(uint256 _transactionId) external onlyOwners transactionExists(_transactionId) notExecuted(_transactionId) {
        transactions[_transactionId].approvals++;
        emit TransactionApproved(_transactionId, msg.sender);

        // Execute the transaction if approvals from at least two owners are reached
        if (transactions[_transactionId].approvals >= 2) {
            executeTransaction(_transactionId);
        }
    }

    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) internal transactionExists(_transactionId) notExecuted(_transactionId) {
        transactions[_transactionId].executed = true;
        payable(transactions[_transactionId].destination).transfer(transactions[_transactionId].amount);
    }
}
