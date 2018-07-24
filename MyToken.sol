pragma solidity ^0.4.18;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
contract MyToken is owned {
    mapping(address => uint256) public balanceOf;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;
    bytes32 public  currentChallenge;
    uint public timeOfLastProof;
    uint public difficulty = 10**32;

    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public approvedAccount;
    event FrozenFunds(address target, bool frozen);
    event ApprovedAccount(address target, bool frozen);

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function approvedAccount (address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        ApprovedAccount(target, freeze);
    }
        /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;  
        totalSupply= initialSupply;
        timeOfLastProof = now;            // Amount of decimals for display purposes
    }
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function transfer(address _to, uint256 _value) {
        require(balanceOf[msg.sender] >= _value && balanceOf[_to]+_value >= balanceOf[_to]);
        require(!frozenAccount[msg.sender]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
                /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
        if (msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance)/sellPrice);
        if (_to.balance<minBalanceForAccounts)
            _to.send(sell((minBalanceForAccounts - _to.balance)/sellPrice));
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
        /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    function buy() payable returns (uint amount) {
        amount = msg.value / buyPrice;                    // calculates the amount
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        balanceOf[this] -= amount;                        // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

    function sell(uint amount) returns (uint revenue) {
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue));                // sends ether to the seller: it's important to do this last to prevent recursion attacks
        Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
        function giveBlockReward() {
        balanceOf[block.coinbase] += 1;
    }
    // uint currentChallenge = 1;
    // function rewardMathGeniuses(uint answerToCurrentReward, uint nextChallenge) {
    //     require(answerToCurrentReward**3 == currentChallenge); // If answer is wrong do not continue
    //     balanceOf[msg.sender] += 1;         // Reward the player
    //     currentChallenge = nextChallenge;   // Set the next challenge
    // }                              // Difficulty starts reasonably low

    function proofOfWork(uint nonce) {
        bytes8 n = bytes8(sha3(nonce, currentChallenge));    // Generate a random hash based on input
        require(n >= bytes8(difficulty));                   // Check if it's under the difficulty

        uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
        require(timeSinceLastProof >= 5 seconds);         // Rewards cannot be given too quickly
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;  // The reward to the winner grows by the minute

        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  // Adjusts the difficulty

        timeOfLastProof = now;                              // Reset the counter
        currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1));  // Save a hash that will be used as the next proof
    }
}