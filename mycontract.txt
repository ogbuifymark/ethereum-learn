pragma solidity ^0.4.18;
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract Payroll is owned { 
    
    
    struct Anemployee {
        address Address;
        bytes32 employeeName;
        uint256 salaryAmount;
        uint bonus;
    }
    mapping(address => Anemployee) public employee;
    mapping(address => uint) public account;
    Anemployee public thisemployee;
    address public companyAccount;
    uint public dueDate;
    
    
    
    function Payroll(address _employeeAddress, uint _employeeSalary, bytes32 _employeeName, 
    uint _companyAmount, uint _dueDate) public {
        Anemployee storage receiver = employee[_employeeAddress];
        receiver.Address = _employeeAddress;
        receiver.salaryAmount = _employeeSalary;
        receiver.employeeName = _employeeName;
        companyAccount = msg.sender;
        account[companyAccount] = _companyAmount;
        dueDate = _dueDate;
    }
    
    function receivePayment() public {
        if(dueDate < now){
            if (account[companyAccount] > thisemployee.salaryAmount){
                transfer(thisemployee.Address,thisemployee.salaryAmount);
            }
        }
    }
    function transfer(address _to, uint256 _value)public {
        require(account[companyAccount] >= _value && account[_to] + _value >= account[_to]);
        account[companyAccount] -= _value;
        account[_to] += _value;
    }
}