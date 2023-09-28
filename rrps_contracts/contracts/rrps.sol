// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./BalanceCheckers.sol";


/*
TODO LIST:

- Make the standard ERC1155 "SafeTransfer" function private/internal and create a wrapper
  that allows players to trade stars but does not allow for players to trade their last star.
    - **OR**, as an alternative to the above; allow players to trade away their last star, 
      but every trade checks for 0 stars and calls gameOver() if any player ends up with 0.

- Add block number logging and logic for allowing chalengees to automatically win if the 
  challenger doesn't reveal in a reasonable timeframe

- 

*/


contract RRPS is ERC1155, Ownable, BalanceCheckers {
    constructor() ERC1155("") {}

    // Nested mapping allows rapid identification of who is challenging whom
    // TODO: REPLACE BOOL WITH HASH OR THE STRUCT??

    struct commit {
        bytes32 hash;
        uint cardType;
        bool exists;
        bool hashStrike; 
        uint blockNum;
    }

    mapping (address => mapping (address => commit)) challenges;
    mapping (address => uint) challengesCount;

    function startGame(string memory nickname) public /* payable */ {
        // Check payment
        // require(msg.value >= 0.1 ether);
        // Ensure that nickname is unique
        require(nicknamesToAddresses[nickname] == address(0), "Nickname already exists");
        // Ensure that address is not currently playing the game
        require(players[msg.sender] == false, "Address is already playing.");
        // Log the address as playing the game
        players[msg.sender] = true; 
        // Associate the nickname 
        nicknamesToAddresses[nickname] = msg.sender;
        addressesToNicknames[msg.sender] = nickname;
        // nicknameList.push(nickname);

        // Mint new set of cards
        mint(msg.sender, ROCK, 4, "");
        mint(msg.sender, PAPER, 4, "");
        mint(msg.sender, SCISSORS, 4, "");
        
        // Mint new set of stars
        mint(msg.sender, STAR, 3, "");
    }


    function gameOverCheck(address player) internal {
        //Check if player has no stars remaining
        if (balanceOf(player, STAR) == 0){
            // DOUBLE check!
            require(balanceOf(player, STAR) == 0, "This player still has stars!");

            //Burn remaining cards
            _burn(player, ROCK, balanceOf(player, ROCK));
            _burn(player, PAPER, balanceOf(player, PAPER));
            _burn(player, SCISSORS, balanceOf(player, SCISSORS));

            //De-register address and nickname
            nicknamesToAddresses[addressesToNicknames[player]] = address(0);
            addressesToNicknames[player] = "";
            players[player] = false;
        }
    }

    function cashOut() public {
        // Check that player has no cards remaining
        require(totalCards(msg.sender) < 1);
        // Check that player has 3 or more stars remaining
        require(balanceOf(msg.sender, STAR) > 2);

        // TODO: Implement cashing out stars from the contract's account -- 0.03 Eth per star on a 0.1 Eth buyin?
        // For now, just burn the remaining stars
        _burn(msg.sender, STAR, balanceOf(msg.sender, STAR)); 

        //De-register address and nickname
        nicknamesToAddresses[addressesToNicknames[msg.sender]] = address(0);
        addressesToNicknames[msg.sender] = "";
        players[msg.sender] = false;
    }



    function challengeCommit(string memory challengeeNickname, bytes32 hash) public {
        require(nicknamesToAddresses[challengeeNickname] != address(0), "That nickname isn't associated with an active player!");
        challengeCommit(nicknamesToAddresses[challengeeNickname], hash);
    }

    // This function is written from the perspective of the challenger
    function challengeCommit(address challengee, bytes32 hash) public {

        // Check that player is in the game 
        require(players[challengee]);

        // Check that challenger and challengee are different accounts
        require(msg.sender != challengee, "You cannot challenge yourself!");

        // Check that challenger has at least one star and at least one card remaining
        require(balanceOf(msg.sender, STAR) > 0, "Requires that you have at least one star.");
        require(totalCards(msg.sender) > 0, "Requires that you have at least one card to challenge with.");

        // Check that challengee has at least one star and at least one card remaining
        require(balanceOf(challengee, STAR) > 0, "Requires that the challengee has at least one star.");
        require(totalCards(challengee) > 0, "Requires that challengee has at least one card.");

        // Check that challenger has at least one card and at least one star not already committed to a challenge
        require((totalCards(msg.sender) - challengesCount[msg.sender]) > 0, "Requires that you have at least one uncommitted card to challenge with.");
        require((balanceOf(msg.sender, STAR) - challengesCount[msg.sender]) > 0, "Requires that you have at least one uncommitted star to challenge with.");

        // Check that challengee has at least one card and at least one star not already committed to a challenge
        require((totalCards(challengee) - challengesCount[challengee]) > 0, "Requires that challengee has at least one uncommitted card.");
        require((balanceOf(challengee, STAR) - challengesCount[challengee]) > 0, "Requires that challengee has at least one uncommitted star.");

        // Check that challengee doesn't have an open challenge against challenger
        require(challenges[challengee][msg.sender].exists == false, "Challengee already has an open challenge against you.");
        // Check that challenger doesn't have an open challenge against challengee
        require(challenges[msg.sender][challengee].exists == false, "You already have an open challenge against challengee.");

        // Set challenges mapping challenger -> challengee -> cardType and increment challengeCount for challenger 
        challenges[msg.sender][challengee].hash = hash;
        challenges[msg.sender][challengee].exists = true;
        challengesCount[msg.sender] += 1;
        
    }

    event PlayerNotFound(address missingPlayer, string message);

    function openCommit(string memory challengerNickname, uint cardType) public {
        require(nicknamesToAddresses[challengerNickname] != address(0), "That nickname isn't associated with an active player!");
        openCommit(nicknamesToAddresses[challengerNickname], cardType);
    }

    // This function is written from the perspective of the challengee
    function openCommit(address challenger, uint cardType) public{

        // Check that challengee has been challenged by challenger
        require(challenges[challenger][msg.sender].exists);

        // Check to see if challenger is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challenger] == false){
            delete challenges[challenger][msg.sender];
            emit PlayerNotFound(challenger, "Player not found! Removing challenge...");
        }

        // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        require(cardType > 0 && cardType < 4, "cardType must be 1, 2, or 3 (corresponding to ROCK, PAPER, and SCISSORS, respectively.");

        // Check that challenger and challengee are different accounts
        require(msg.sender != challenger, "You cannot challenge yourself!");

        // Check that challengee has at least one star and at least one card remaining
        require(balanceOf(msg.sender, STAR) > 0, "Requires that you have at least one star.");
        require(totalCards(msg.sender) > 0, "Requires that you have at least one card to challenge with.");

        // Check that challengee has at least one card and at least one star not already committed to a challenge
        require((totalCards(msg.sender) - challengesCount[msg.sender]) > 0, "Requires that you have at least one uncommitted card to challenge with.");
        require((balanceOf(msg.sender, STAR) - challengesCount[msg.sender]) > 0, "Requires that you have at least one uncommitted star to challenge with.");

        // Check that challengee has at least one copy of the card they're trying to commit
        require(balanceOf(msg.sender, cardType) > 0, "Requires that you have at least one copy of the card you're trying to commit.");


        // Set challenges mapping challengee -> challenger -> cardType
        challenges[msg.sender][challenger].cardType = cardType;
        challenges[msg.sender][challenger].exists = true;

        // Increment challengeCount for challengee 
        challengesCount[msg.sender] += 1;
    }

    enum GameResult {
        Challenger_Loses,
        Tie,
        Challenger_Wins,
        Misplay_Challenger_Loses,   // Result if the challenger doesn't possess a card of the type they committed
        Misplay_Tie,                // Result if neither player posesses the card they committed
        Misplay_Challenger_Wins     // Result if the challengee doesn't possess a card of the type they committed
    }

    function reveal(string memory challengeeNickname, uint cardType, string calldata salt) public {
        require(nicknamesToAddresses[challengeeNickname] != address(0), "That nickname isn't associated with an active player!");
        reveal(nicknamesToAddresses[challengeeNickname], cardType, salt);
    }

    // Written from the perspective of the challenger, who must now reveal their card by proving their hash
    function reveal(address challengee, uint cardType, string calldata salt) public returns(string memory) {

        // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        require(cardType > 0 && cardType < 4, "cardType must be 1, 2, or 3 (corresponding to ROCK, PAPER, and SCISSORS, respectively.");

        // Check to ensure that an open commit from the challengee exists against the challenger's challenge
        require(challenges[msg.sender][challengee].exists, "You haven't challenged this player yet.");
        require(challenges[challengee][msg.sender].exists, "This player hasn't yet responded to your challenge.");

        // Check to see if challengee is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challengee] == false){
            delete challenges[challengee][msg.sender];
            delete challenges[msg.sender][challengee];
            emit PlayerNotFound(challengee, "Player not found! Removing challenge...");
        }

        // Check that challenger isn't revealing against themselves
        require(msg.sender != challengee, "You cannot reveal against yourself!");

        // Check that challenger's hash is solved using the card type and salt.
        // If they fail to do so, they get a hash strike and the function returns.
        uint challengerCard;

        if (hashCommit(cardType, salt) == challenges[msg.sender][challengee].hash && balanceOf(msg.sender, cardType) > 0){
            challengerCard = cardType;
        } else if (!challenges[msg.sender][challengee].hashStrike) {
            challenges[msg.sender][challengee].hashStrike = true;
            return ("Challenger failed to reproduce hash for a card they own in sufficient quantity. Strike issued. Another failure will result in automatic win for the challengee.");
        } else {
            challengerCard = 0;
        }
        
        
        uint challengeeCard = challenges[challengee][msg.sender].cardType;
        
        GameResult gameResult;

        // Ensure that challengee is in possession of the card they committed; 
        // if they're not, change card type to 0, representing a misplay.
        if (balanceOf(msg.sender, challengerCard) < 1)  {challengerCard = 0;}
        if (balanceOf(challengee, challengeeCard) < 1)  {challengeeCard = 0;}

        // Determine Winner
        if      (challengerCard == 0 && challengeeCard == 0)            {gameResult = GameResult.Misplay_Tie;}
        else if (challengerCard == 0)                                   {gameResult = GameResult.Misplay_Challenger_Loses;}
        else if (challengeeCard == 0)                                   {gameResult = GameResult.Misplay_Challenger_Wins;}
        else if (challengerCard == challengeeCard)                      {gameResult = GameResult.Tie;}
        else if (challengerCard == ROCK && challengeeCard == SCISSORS)  {gameResult = GameResult.Challenger_Wins;}
        else if (challengerCard == SCISSORS && challengeeCard == PAPER) {gameResult = GameResult.Challenger_Wins;}
        else if (challengerCard == PAPER && challengeeCard == ROCK)     {gameResult = GameResult.Challenger_Wins;}
        else if (challengerCard == ROCK && challengeeCard == PAPER)     {gameResult = GameResult.Challenger_Loses;}
        else if (challengerCard == PAPER && challengeeCard == SCISSORS) {gameResult = GameResult.Challenger_Loses;}
        else if (challengerCard == SCISSORS && challengeeCard == ROCK)  {gameResult = GameResult.Challenger_Loses;}
        else {revert("Invalid card combination; something went wrong!");}

        // If the outcome is legitimate, burn both cards used, otherwise, only burn the legit cards.

        if      (gameResult == GameResult.Misplay_Challenger_Loses)     {_burn(challengee, challengeeCard, 1);}
        else if (gameResult == GameResult.Misplay_Challenger_Wins)      {_burn(msg.sender, challengerCard, 1);}
        else {
            _burn(msg.sender, challengerCard, 1);
            _burn(challengee, challengeeCard, 1);
        }


        // If there's a winner, move one star from loser to winner
        if (gameResult == GameResult.Challenger_Loses || gameResult == GameResult.Misplay_Challenger_Loses){
            _burn(msg.sender, STAR, 1);
            mint(challengee, STAR, 1, "");
        }
        if (gameResult == GameResult.Challenger_Wins || gameResult == GameResult.Misplay_Challenger_Wins){
            _burn(challengee, STAR, 1);
            mint(msg.sender, STAR, 1, "");
        }
        // If the result is a double misplay, burn one star from both participants.
        if (gameResult == GameResult.Misplay_Tie) {
            _burn(msg.sender, STAR, 1);
            _burn(challengee, STAR, 1);
        }

        // Set challenges mapping for both address orderings to false or 0??
        delete challenges[msg.sender][challengee];
        delete challenges[challengee][msg.sender];

        // Decrement challengeCount for both participants
        challengesCount[msg.sender] -= 1;
        challengesCount[challengee] -= 1;

        // Check for Game Over for both players
        gameOverCheck(msg.sender);
        gameOverCheck(challengee);

        return("Match complete!");
    }

    function withdrawChallenge(string memory challengeeNickname) public {
        withdrawChallenge(nicknamesToAddresses[challengeeNickname]);
    }

    function withdrawChallenge(address challengee) public {
        
        // Check that player has an ongoing challenge against another player
        require(challenges[msg.sender][challengee].exists);

        // Ensure that the other player hasn't yet made an open commit to the challenge
        require(challenges[challengee][msg.sender].exists == false);

        // Withdraw the challenge by deregistering and decrementing challengesCount
        delete challenges[msg.sender][challengee];
        challengesCount[msg.sender] -= 1;

    }

    function withdrawOpenCommit(string memory challengerNickname) public {
        withdrawOpenCommit(nicknamesToAddresses[challengerNickname]);
    }

    function withdrawOpenCommit(address challenger) public {

        // Check that sender has made an open commit against another player's ongoing challenge
        require(challenges[msg.sender][challenger].exists);

        // There shouldn't be any need to ensure that the reveal hasn't happened yet, as the challenge 
        // will be deregistered as soon as the reveal occurs

        // Withdraw the open commit by deregistering and decrementing challengesCount
        delete challenges[msg.sender][challenger];
        challengesCount[msg.sender] -= 1;
    }



    function setURI(string memory newuri) internal {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
    {
        _mintBatch(to, ids, amounts, data);
    }

    // Pure has function
    function hashCommit(uint cardType, string calldata salt) public view returns(bytes32) {
        require((cardType > 0) && (cardType < 4), "Please enter a valid card type (id must be 1, 2, or 3).");
        return keccak256(abi.encodePacked(msg.sender, cardType, salt));
    }

    // Transfer Overrides

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public pure override {
        revert("ERC1155 Transfer standards disabled for this game.");
    }
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory values,bytes memory data) public pure override {
        revert("ERC1155 Transfer standards disabled for this game.");
    }

}
