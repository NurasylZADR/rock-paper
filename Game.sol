// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public player1;
    address public player2;
    uint256 public minimumBet = 0.0001 ether;
    uint256 public contractBalance;
    bytes32 public encryptedMove1;
    bytes32 public encryptedMove2;
    string public clearMove1;
    string public clearMove2;
    uint256 public revealTimeout = 60; // Set your reveal timeout duration in seconds.
    uint256 public revealDeadline;
    bool public gameFinished;
    bool public player1Revealed;
    bool public player2Revealed;
    
    constructor() {
        player1 = address(0);
        player2 = address(0);
        gameFinished = false;
        player1Revealed = false;
        player2Revealed = false;
    }
    
    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "You are not a registered player.");
        _;
    }
    
    modifier bothPlayersPlayed() {
        require(player1 != address(0) && player2 != address(0), "Both players must be registered.");
        require(encryptedMove1 != bytes32(0) && encryptedMove2 != bytes32(0), "Both players must make their moves.");
        _;
    }
    
    modifier revealPhaseTimeout() {
        require(block.timestamp >= revealDeadline, "Reveal phase has not started yet.");
        _;
    }
    
    function register() external payable {
        require(msg.value >= minimumBet, "Insufficient funds to register.");
        require(player1 == address(0) || player2 == address(0), "Both players are already registered.");
        
        if (player1 == address(0)) {
            player1 = msg.sender;
        } else {
            player2 = msg.sender;
        }
        
        contractBalance += msg.value;
    }
    
    function play(bytes32 _encryptedMove) external onlyPlayers {
        require(encryptedMove1 == bytes32(0) || encryptedMove2 == bytes32(0), "Both players have already made their moves.");
        
        if (msg.sender == player1) {
            encryptedMove1 = _encryptedMove;
        } else {
            encryptedMove2 = _encryptedMove;
        }
    }
    
    function reveal(string memory _clearMove) external onlyPlayers bothPlayersPlayed revealPhaseTimeout {
        require(keccak256(abi.encodePacked(_clearMove)) == encryptedMove1 || keccak256(abi.encodePacked(_clearMove)) == encryptedMove2, "Invalid clear move.");
        
        if (msg.sender == player1) {
            clearMove1 = _clearMove;
            player1Revealed = true;
        } else {
            clearMove2 = _clearMove;
            player2Revealed = true;
        }
        
        if (player1Revealed && player2Revealed) {
            determineWinner();
        }
    }
    
    function determineWinner() private {
        require(!gameFinished, "Game is already finished.");
        
        if (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked(clearMove2))) {
            // It's a draw, return the bets.
            payable(player1).transfer(minimumBet);
            payable(player2).transfer(minimumBet);
        } else if ((keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("scissors"))) ||
                   (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("paper"))) ||
                   (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("rock")))) {
            // Player 1 wins, send the total balance to player 1.
            payable(player1).transfer(contractBalance);
        } else {
            // Player 2 wins, send the total balance to player 2.
            payable(player2).transfer(contractBalance);
        }
        
        gameFinished = true;
    }
    
    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }
    
    function whoAmI() external view returns (uint256) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }
    
    function bothPlayed() external view returns (bool) {
        return encryptedMove1 != bytes32(0) && encryptedMove2 != bytes32(0);
    }
    
    function bothRevealed() external view returns (bool) {
        return player1Revealed && player2Revealed;
    }
    
    function revealTimeLeft() external view returns (uint256) {
        if (block.timestamp < revealDeadline) {
            return revealDeadline - block.timestamp;
        } else {
            return 0;
        }
    }
}
