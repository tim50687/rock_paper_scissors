# Rock_Paper_Scissors
This project is a decentralized betting Rock, Paper and scissors game. Players are able to bet ethereum on their choices and receive the prize based on game result without any trusted central intermediary.

## Remix IDE
Remix IDE is an open source web and desktop application. It fosters a fast development cycle and has a rich set of plugins with intuitive GUIs. Remix is used for the entire journey of contract development with Solidity language as well as a playground for learning and teaching Ethereum.

Start developing using Remix on browser, visit: https://remix.ethereum.org

## Prerequisites
* Compiler:
  0.8.9 <= version < 0.9.0
  
## Workflow
* Deploy the smart contract. (RPS_game.sol)

  1. Set **_durationRegisteredMinutes** and **_durationRevealMinutes**.
  
* Registered State

  1. Both Players need to generate sealed Choice by **generateSealedChoice(string memory _choice, uint _secret)** in order to prevent other player from knowing their chioces. 
  
      Ex. generateSealedChoice("rock", 7823221)
  
  2. Players need to register for RPS game with sealedChoice and ETH. 

* Reveal State
 
  1. Both players need to reveal their choices by **reveal(string memory _choice, uint _secret)**. 
 
      Ex. reveal("rock", 7823221)
    
* After reveal state

  1. Both players can get the game result.
  
  2. Only winner can withdraw the prize pool money.
  
  * If the game result is tie, both players can withdraw their money back.

  * **If only one player reveal his choice, another player will be regarded as waiver. The only one who reveal his answer can get all prize pool money.**
  
  
