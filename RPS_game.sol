//SPDX-License_identifier:MIT

pragma solidity ^0.8.9;

contract RPSGame {
    
    // Store registered players' data
    struct playerBet{
        address player;
        bytes32 choice;
        uint amount;
    }
    playerBet[] public player_list;

    // Store data that revealed by both players
    struct revealChoice{
        address player;
        string choice;
    }
    revealChoice [] public revealedChoices;

    // Game parameters
    uint public registeredEnd;
    uint public revealEnd;
    uint public prizePool;
    uint splitPrize; // If game is tied, split the prize pool and send back to each player
    string result;

    // Prevent player withdraw second time when the game is tied
    mapping(address => bool) hasWithdrawed; 

    modifier onlyBefore(uint time) {
        require(block.timestamp < time, "Too late.");
        _;
    }

    modifier onlyAfter(uint time) {
        require(block.timestamp > time, "Too early.");
        _;
    }

    constructor (uint _durationRegisteredMinutes, uint _durationRevealMinutes) {
        registeredEnd = block.timestamp + _durationRegisteredMinutes * 1 minutes; 
        revealEnd = registeredEnd + _durationRevealMinutes * 1 minutes;
    }
    
    // Rock Paper Scissors's game rule
    function RPS_gamerule(address _player1, string memory _player1Choice, address _player2, string memory _player2Choice) private view returns(string memory winner) {
        // Solidity cannot compare string with each other, thus transforming string by hash function in order to do comparison
        bytes32 player1Choice = keccak256(abi.encodePacked(_player1Choice));
        bytes32 player2Choice = keccak256(abi.encodePacked(_player2Choice));
        bytes32 rock = keccak256(abi.encodePacked("rock"));
        bytes32 paper = keccak256(abi.encodePacked("paper"));
        bytes32 scissors = keccak256(abi.encodePacked("scissors"));
        if (player1Choice == player2Choice) {
            return "It's a tie game!";
        }
        else if (player1Choice == rock) {
            if (player2Choice == scissors) {
                return "You win!";
            } else {
                return "You Lose :(";
            }
        }
        else if (player1Choice == paper) {
            if (player2Choice == rock) {
                return "You win!";
            } else {
                return "You Lose :(";
            }
        }
        else if (player1Choice == scissors) {
            if (player2Choice == paper) {
                return "You win!";
            } else {
                return "You Lose :(";
            }
        }
        
    }

    // Players can hash their choices and specific secret(0 ~ (2^256)-1) 
    function generateSealedChoice(string memory _choice, uint _secret) public pure returns (bytes32 _sealedChoice) {
        bytes32 sealedChoice = keccak256(abi.encodePacked(_secret, _choice));
        return sealedChoice;
    }

    // Register RPS game 
    function register(bytes32 _sealedChoice) external onlyBefore(registeredEnd) payable {
        require(msg.value > 0, "You need to make a bet!");
        require(player_list.length < 2, "Two People already register this game!");
        
        if (player_list.length == 1) {
            require(msg.value == player_list[0].amount, "Amount of money doesn't match.");
            require(player_list[0].player != msg.sender, "Same player is not allow to register in one game");
            splitPrize = msg.value;
        }
        
        // Store registered player's information
        playerBet memory _playerBet = playerBet({
            player: msg.sender,
            choice: _sealedChoice,
            amount: msg.value
        });
        player_list.push(_playerBet); 

        // Add up both users' bet to the prize pool
        prizePool += msg.value;
    }

    // Since players use hash function to hide their choice, players need to reveal their choices at reveal state 
    function reveal(string memory _choice, uint _secret) external onlyBefore(revealEnd) onlyAfter(registeredEnd) {
        if(revealedChoices.length == 1 ) {
            require(revealedChoices[0].player != msg.sender, "You've already revealed your choice!");
        }
        
        bytes32 hashedInput = generateSealedChoice(_choice, _secret);
        for (uint i; i < 2; i++) {
            if (player_list[i].choice == hashedInput && msg.sender == player_list[i].player) { // Choice is successfully revealed
                revealedChoices.push(revealChoice({ // Store player choice
                    player: msg.sender,
                    choice: _choice
                }));              
            }
        }       
    }

    function showResult() external onlyAfter(revealEnd) view returns (string memory _result){
        require(revealedChoices.length == 2, "Both players need to reveal their choices before seeing result!"); 
        // Game Rule implementation    
        if (revealedChoices[0].player == msg.sender) {
            return RPS_gamerule(revealedChoices[0].player, revealedChoices[0].choice, revealedChoices[1].player, revealedChoices[1].choice);
        } else if (revealedChoices[1].player == msg.sender) {
            return RPS_gamerule(revealedChoices[1].player, revealedChoices[1].choice, revealedChoices[0].player, revealedChoices[0].choice);
        }        
    }

    function withdraw() external onlyAfter(revealEnd) { 
        // If only one player reveal his choice, another player will be regarded as waiver.
        // The one who reveal his answer can get all prize pool money
        if (revealedChoices.length == 1 && msg.sender == revealedChoices[0].player) {
            uint amount = prizePool;
            prizePool = 0;
            payable(msg.sender).transfer(amount);
        } else if (revealedChoices.length == 2) { // Both Two players reveal their choices
            // msg.sender need to be in array revealedChoices to get result, then withdraw money
            if (revealedChoices[0].player == msg.sender) {
                result =  RPS_gamerule(revealedChoices[0].player, revealedChoices[0].choice, revealedChoices[1].player, revealedChoices[1].choice);
            } else if (revealedChoices[1].player == msg.sender) {
                result =  RPS_gamerule(revealedChoices[1].player, revealedChoices[1].choice, revealedChoices[0].player, revealedChoices[0].choice);
            } 

            bytes32 hashResult = keccak256(abi.encodePacked(result));

            if (hashResult == keccak256(abi.encodePacked("It's a tie game!"))) {
                require(!hasWithdrawed[msg.sender], "Already withdraw!");
                hasWithdrawed[msg.sender] = true; // Prevent player withdraw two times when game is tied
                prizePool -= splitPrize;
                payable(msg.sender).transfer(splitPrize);
            } else {
            // Only allow winner to withdraw money 
            require(hashResult == keccak256(abi.encodePacked("You win!")), "Only winner can withdraw money!");
            // Prevent from reentrancy attack
            uint amount = prizePool;
            prizePool = 0;
            payable(msg.sender).transfer(amount);
            }
        } 
    }

}
