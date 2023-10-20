// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
TODO LIST:

- Re-implement payable tag on startGame function

- Implement cashing out stars from the contract's account -- 0.03 Eth per star on a 0.1 Eth buyin?

- Replace block duration test value of 1 with the intended value of 5000

- Create separate commit trackers for each kind of card (rock, paper, scissors) so that 
  players can't commit to a challenge with a card they don't have, and so that players
  can't trade away cards they (might) have committed to a challenge.

- Implement trading logic ** DONE, BUT UNTESTED **

*/

contract RRPS is Ownable {

    error AddressAlreadyPlaying();          // Address is already playing the game
    error PlayerNotFound();                 // Address is not currently playing the game
    error PlayerHasNoStars();               // Player has no stars remaining
    error PlayerHasNoCards();               // Player has no cards remaining
    error InsufficientUncommittedTokens();   // Player has insufficient tokens remaining that aren't already committed to a challenge
    error PlayerStillHasCards();            // Player still has cards remaining
    error InsufficientStars();              // Player has less than 3 stars remaining
    error NoSelfChallenge();                // Player cannot challenge themselves
    error PlayerAlreadyChallenged();        // Player has already challenged the other player
    error NotYetChallenged();               // Player has not yet been challenged by the other player
    error MustBeRockPaperOrScissors();      // Card type must be 1, 2, or 3
    error NeedCopyOfCard();                 // Player must have at least one copy of the card they're trying to commit
    error NoOpenCommit();                   // Player has not yet made an open commit to the other player's challenge
    error InvalidCardCombination();         // Invalid card combination
    error OtherPlayerAlreadyCommitted();    // Other player has already made an open commit to the challenge

    event PlayerJoined(address playerAddress, string nickname);                                                 // A player has joined the game for any reason
    event PlayerLeft(address playerAddress);                                                                    // A player has left the game for any reason
    event PlayerEliminated(address playerAddress);                                                              // Player has lost all of their stars
    event PlayerCashedOut(address playerAddress);                                                               // Player voluntarily cashes out
    event ChallengeCommit(address challenger, address challengee);                                              // Challenger has issued a challenge to challengee
    event OpenCommit(address challenger, address challengee);                                                   // Challengee has made an open commit to challenger's challenge
    event ChallengerWins(address challenger, uint challengerCard, address challengee, uint challengeeCard);     // Challenger has won the challenge against challengee
    event ChallengerLoses(address challenger, uint challengerCard, address challengee, uint challengeeCard);    // Challengee has won the challenge against challenger
    event Tie(address challenger, uint challengerCard, address challengee, uint challengeeCard);                // Challenger and challengee have tied
    event Misplay(address player, uint card);                                                                   // Player has misplayed a card
    event WithdrawnChallengeCommit(address challenger, address challengee);                                     // Challenger has withdrawn their challenge to challengee
    event WithdrawnOpenCommit(address challenger, address challengee);                                          // Challengee has withdrawn their open commit to challenger
    event OrphanedCommit(address challenger, address challengee);                                               // Player left unresolved commit behind
    event ChallengerFailedHashOnce(address challenger, address challengee);                                     // Challenger failed to solve hash once
    event ChallengerFailedHashTwice(address challenger, address challengee);                                    // Challenger failed to solve hash twice (auto-loss of star with no card burnt)
    event TransferRequest(address requestSender, address requestee, uint tokenType, uint amount);               // Player has requested a token transfer 
    event TransferApproved(address requestSender, address requestee, uint tokenType, uint amount);              // Player has approved a token transfer           

    uint constant STAR = 0;
    uint constant ROCK = 1; 
    uint constant PAPER = 2;
    uint constant SCISSORS = 3;

    struct commit {
        bytes32 hash;
        uint cardType;
        bool exists;
        bool hashStrike; 
        uint blockNum;
    }

    struct transferRequest {
        address requestee;
        uint tokenType;
        uint amount;
    }

    enum GameResult {
        Challenger_Loses,
        Tie,
        Challenger_Wins,
        Misplay_Challenger_Loses,   // Result if the challenger doesn't possess a card of the type they committed
        Misplay_Tie,                // Result if neither player posesses the card they committed
        Misplay_Challenger_Wins     // Result if the challengee doesn't possess a card of the type they committed
    }

    mapping (address => bool) players;                          // Tracks whether a player is active in the game
    mapping (address => mapping (uint => uint)) balances;       // Tracks each player's balance of each token type
    mapping (uint => uint) totals;                              // Tracks the total supply of each token type
    mapping (address => mapping (address => commit)) commits;   // Tracks each player's commits against other players
    mapping (address => address[]) commitArray;                 // This is merely used to re-initialize the commits mapping when a player leaves the game
    mapping (address => uint) commitCount;                      // Tracks the number of games a player is currently committed to
    mapping (address => transferRequest) transferRequests;      // Tracks transfer requests
    
    bytes emptyData = "";
    string emptyString = "";

    function incrementToken(address player, uint256 id, uint256 amount) internal {
        balances[player][id] += amount;
        totals[id] += amount;
    }

    function decrementToken(address player, uint256 id, uint256 amount) internal {
        balances[player][id] -= amount;
        totals[id] -= amount;
    }

    // This function is written from the perspective of the challenger
    function issueCommit(address challengee, bytes32 hash) internal {
        commits[msg.sender][challengee].hash = hash;                        // Add hash to commits mapping
        commits[msg.sender][challengee].exists = true;                      // Set commits mapping to exist
        commits[msg.sender][challengee].blockNum = block.number;            // Add blocknumber 
        commitArray[msg.sender].push(challengee);                           // Add challengee to array of addresses committed against
        commitCount[msg.sender] += 1;                                       // Increment commitCount for challenger 
    }

    // This function is written from the perspective of the challengee
    function issueCommit(address challenger, uint cardType) internal {
        // Set commits mapping challengee -> challenger -> cardType
        commits[msg.sender][challenger].cardType = cardType;                // Add cardType to commits mapping
        commits[msg.sender][challenger].exists = true;                      // Set commits mapping to exist
        commits[msg.sender][challenger].blockNum = block.number;            // Add blocknumber 
        commitArray[msg.sender].push(challenger);                           // Add challenger to array of addresses committed against 
        commitCount[msg.sender] += 1;                                       // Increment commitCount for challengee 
    }

    function removeCommit(address fromPlayer, address toPlayer) internal {
        if (commits[fromPlayer][toPlayer].exists){
            delete commits[fromPlayer][toPlayer];
            commitCount[fromPlayer] -= 1;
        }
    }

    function startGame(string memory nickname) public /* payable */ {
        // require(msg.value >= 0.1 ether); // Check payment
        if (players[msg.sender] == true) {revert AddressAlreadyPlaying();}  // Ensure that address is not currently playing the game
        players[msg.sender] = true;                                         // Log the address as playing the game
        for (uint i=0; i<commitArray[msg.sender].length; i++){
            removeCommit(msg.sender, commitArray[msg.sender][i]);           // Delete any existing outgoing commits
            removeCommit(commitArray[msg.sender][i], msg.sender);           // Delete any existing incoming commits
        }
        delete commitCount[msg.sender];                                     // Delete commits count
        delete transferRequests[msg.sender];                                // Delete transfer requests
        emit PlayerJoined(msg.sender, nickname);

        // Give player fresh set of cards and stars
        incrementToken(msg.sender, STAR, 3);
        incrementToken(msg.sender, ROCK, 4);
        incrementToken(msg.sender, PAPER, 4);
        incrementToken(msg.sender, SCISSORS, 4);
    }

    function gameOverCheck(address player) internal {
        if (balanceOf(player, STAR) < 1){                                   // Check if player has no stars remaining
            decrementToken(player, ROCK, balanceOf(player, ROCK));          // Remove remaining rock cards
            decrementToken(player, PAPER, balanceOf(player, PAPER));        // Remove remaining paper cards
            decrementToken(player, SCISSORS, balanceOf(player, SCISSORS));  // Remove remaining scissors cards
            players[player] = false;                                        // Deregister player
            for (uint i=0; i<commitArray[player].length; i++){
                removeCommit(player, commitArray[player][i]);               // Delete any existing outgoing commits
                removeCommit(commitArray[player][i], player);               // Delete any existing incoming commits
            }
            delete commitCount[player];                                     // Delete any existing commits count
            delete transferRequests[player];                                // Delete transfer requests                                                                

            emit PlayerEliminated(player);
            emit PlayerLeft(player);
        }
    }

    function cashOut() public {
        if (totalCards(msg.sender) > 0) {revert PlayerStillHasCards();}     // Check that player has no cards remaining
        if (balanceOf(msg.sender, STAR) < 3) {revert InsufficientStars();}  // Check that player has 3 or more stars remaining
        decrementToken(msg.sender, STAR, balanceOf(msg.sender, STAR));      // Remove remaining stars
        players[msg.sender] = false;                                        // Deregister player
        delete transferRequests[msg.sender];                                // Delete transfer requests
        for (uint i=0; i<commitArray[msg.sender].length; i++){
            removeCommit(msg.sender, commitArray[msg.sender][i]);           // Delete any existing outgoing commits
            removeCommit(commitArray[msg.sender][i], msg.sender);           // Delete any existing incoming commits
        }
        emit PlayerCashedOut(msg.sender);
        emit PlayerLeft(msg.sender);
    }

    // This function is written from the perspective of the challenger
    function challengeCommit(address challengee, bytes32 hash) public {
        if (players[msg.sender] == false) {revert PlayerNotFound();}                    // Check that player is in the game 
        if (msg.sender == challengee) {revert NoSelfChallenge();}                       // Check that challenger and challengee are different accounts
        if ((totalCards(msg.sender) - commitCount[msg.sender]) < 1) {revert InsufficientUncommittedTokens();}         // Check for uncommitted challenger card
        if ((totalCards(challengee) - commitCount[challengee]) < 1) {revert InsufficientUncommittedTokens();}         // Check for uncommitted challengee card
        if ((balanceOf(msg.sender, STAR) - commitCount[msg.sender]) < 1) {revert InsufficientUncommittedTokens();}    // Check for uncommitted challenger star
        if ((balanceOf(challengee, STAR) - commitCount[challengee]) < 1) {revert InsufficientUncommittedTokens();}    // Check for uncommitted challengee star
        if (commits[challengee][msg.sender].exists) {revert PlayerAlreadyChallenged();} // Check for open challenge against challengee
        if (commits[msg.sender][challengee].exists) {revert PlayerAlreadyChallenged();} // Check for open challenge against challenger
        issueCommit(challengee, hash);                                                  // Set commit mapping and increment commitCount for challenger 
        emit ChallengeCommit(msg.sender, challengee);
    }

    // This function is written from the perspective of the challengee
    function openCommit(address challenger, uint cardType) public{
        if (players[msg.sender] == false) {revert PlayerNotFound();}                // Check that player is in the game 
        if (msg.sender == challenger) {revert NoSelfChallenge();}                   // Check that challenger and challengee are different accounts
        if (!commits[challenger][msg.sender].exists) {revert NotYetChallenged();}   // Check that challengee has been challenged by challenger
        if (cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}     // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        if (msg.sender == challenger) {revert NoSelfChallenge();}                   // Check that challenger and challengee are different accounts
        if (balanceOf(msg.sender, cardType) < 1) {revert NeedCopyOfCard();}         // Check that challengee has at least one copy of the card to be committed
        if ((totalCards(msg.sender) - commitCount[msg.sender]) < 1) {revert InsufficientUncommittedTokens();}         // Check challengee's uncommitted cards
        if ((balanceOf(msg.sender, STAR) - commitCount[msg.sender]) < 1) {revert InsufficientUncommittedTokens();}    // Check challengee's uncommitted stars
        if (players[challenger] == false){                                          // Check to see if challenger is still in the game.
            removeCommit(challenger, msg.sender);                                   // If they are not, withdraw the challenge and end function early
            removeCommit(msg.sender, challenger);
            emit OrphanedCommit(challenger, msg.sender);
            return ();
        }
        issueCommit(challenger, cardType);                                           // Set commit mapping and increment commitCount for challengee
        emit OpenCommit(challenger, msg.sender);
    }

    // Written from the perspective of the challenger, who must now reveal their card by proving their hash
    function reveal(address challengee, uint cardType, string calldata salt) public {
        if (msg.sender == challengee) {revert NoSelfChallenge();}                   // Check that challenger isn't revealing against themselves
        if (players[msg.sender] == false) {revert PlayerNotFound();}                // Check that player is in the game 
        if (cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}     // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        if (!commits[challengee][msg.sender].exists) {revert NoOpenCommit();}       // Check that challengee has made an open commit to challenger's challenge
        if (!commits[msg.sender][challengee].exists) {revert NotYetChallenged();}   // Check that challenger has challenged challengee

        if (players[challengee] == false){                                          // Check to see if challengee is still in the game. 
            removeCommit(msg.sender, challengee);                                   // If they are not, withdraw the challenge and end function early.
            removeCommit(challengee, msg.sender);
            emit OrphanedCommit(msg.sender, challengee);
            return ();
        }

        // Check that challenger's hash is solved using the card type and salt.
        uint challengerCard;

        if (
            hashCommit(cardType, salt) == commits[msg.sender][challengee].hash && 
            balanceOf(msg.sender, cardType) > 0
        ){
            challengerCard = cardType;                                              // If the hash matches, accept the card type as the challenger's card
        } else if (!commits[msg.sender][challengee].hashStrike) {
            commits[msg.sender][challengee].hashStrike = true;                      // If the hash doesn't match, strike the hash once,
            emit ChallengerFailedHashOnce(msg.sender, challengee);                  // and then end the function early
            return ();
        } else {
            emit ChallengerFailedHashTwice(msg.sender, challengee);                 // If the hash doesn't match and has already been struck once,
            challengerCard = 0;                                                     // Set challengerCard to 0, which indicates a misplay 
        }
        
        uint challengeeCard = commits[challengee][msg.sender].cardType;             // Get the challengee's card
        
        GameResult gameResult;

        if (balanceOf(msg.sender, challengerCard) < 1)  {challengerCard = 0;}       // Ensure that challenger is in possession of a card of the type they committed
        if (balanceOf(challengee, challengeeCard) < 1)  {challengeeCard = 0;}       // Ensure that challengee is in possession of a card of the type they committed

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
        else {revert InvalidCardCombination();}

        // CARD HANDLING:
        // If the outcome is legitimate, burn both cards used, otherwise, only burn the legit card.
        if      (gameResult == GameResult.Misplay_Challenger_Loses)     {decrementToken(challengee, challengeeCard, 1); emit Misplay(msg.sender, challengerCard);}
        else if (gameResult == GameResult.Misplay_Challenger_Wins)      {decrementToken(msg.sender, challengerCard, 1); emit Misplay(challengee, challengeeCard);}
        else {
            decrementToken(msg.sender, challengerCard, 1);
            decrementToken(challengee, challengeeCard, 1);
        }

        // STAR HANDLING:
        // If there's a winner, move one star from loser to winner
        if (gameResult == GameResult.Challenger_Loses || gameResult == GameResult.Misplay_Challenger_Loses){
            decrementToken(msg.sender, STAR, 1);
            incrementToken(challengee, STAR, 1);
            emit ChallengerLoses(msg.sender, challengerCard, challengee, challengeeCard);
        }
        if (gameResult == GameResult.Challenger_Wins || gameResult == GameResult.Misplay_Challenger_Wins){
            decrementToken(challengee, STAR, 1);
            incrementToken(msg.sender, STAR, 1);
            emit ChallengerWins(msg.sender, challengerCard, challengee, challengeeCard);
        }
        // If the result is a double misplay, burn one star from both participants.
        if (gameResult == GameResult.Misplay_Tie) {
            decrementToken(msg.sender, STAR, 1);
            decrementToken(challengee, STAR, 1);
            emit Misplay(msg.sender, challengerCard);
            emit Misplay(challengee, challengeeCard);
        }
        // If the result is a legitimate tie, no stars change hands
        if (gameResult == GameResult.Tie) {
            emit Tie(msg.sender, challengerCard, challengee, challengeeCard);
        }

        // Remove both commits
        removeCommit(msg.sender, challengee);
        removeCommit(challengee, msg.sender);

        // Check for Game Over for both players
        gameOverCheck(msg.sender);
        gameOverCheck(challengee);
    }

    function withdrawChallenge(address challengee) public {
        if (commits[challengee][msg.sender].exists) {revert OtherPlayerAlreadyCommitted();}     // Ensure no open commit from other player yet exists
        removeCommit(msg.sender, challengee);                                                   // Remove the commit
        emit WithdrawnChallengeCommit(msg.sender, challengee);
    }

    function withdrawOpenCommit(address challenger) public {
        if (!commits[msg.sender][challenger].exists) {revert NoOpenCommit();}       // Check that challengee has made an open commit to challenger's challenge
        if (!commits[challenger][msg.sender].exists) {revert NotYetChallenged();}   // Check that challenger has challenged challengee
        removeCommit(challenger, msg.sender);                                       // Remove the open commit
        emit WithdrawnOpenCommit(challenger, msg.sender);
    }

    function timeOutWin(address challenger) public {
        if (!commits[msg.sender][challenger].exists) {revert NoOpenCommit();}       // Check that challengee has made an open commit to challenger's challenge
        if (!commits[challenger][msg.sender].exists) {revert NotYetChallenged();}   // Check that challenger has challenged challengee

        if (players[challenger] == false){                                          // Check to see if challenger is still in the game. 
            removeCommit(msg.sender, challenger);                                   // If they are not, withdraw the challenge and end function early.
            removeCommit(challenger, msg.sender);
            emit OrphanedCommit(msg.sender, challenger);
            return ();
        }

        if (commits[msg.sender][challenger].blockNum < (block.number - 1 /*Change this to 5000 for deployment*/)){ // Check if 5000 blocks have elapsed
            decrementToken(challenger, STAR, 1);                                    // Challenger loses a star
            incrementToken(msg.sender, STAR, 1);                                    // Challengee gains a star
            decrementToken(msg.sender, commits[msg.sender][challenger].cardType, 1);// Challengee burns their card; challenger does not.
            removeCommit(msg.sender, challenger);                                   // Remove the open commit
            removeCommit(challenger, msg.sender);                                   // Remove the initial commit
            gameOverCheck(challenger);
            emit ChallengerLoses(challenger, commits[challenger][msg.sender].cardType, msg.sender, commits[msg.sender][challenger].cardType);
        }
    }

    function hashCommit(uint cardType, string calldata salt) public view returns(bytes32) {
        if(cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}
        return keccak256(abi.encodePacked(msg.sender, cardType, salt));
    }

    function contractBalance() public view returns(uint256) {
        return(address(this).balance);
    }

    function balanceOf(address account, uint id) public view returns(uint256) {
        return(balances[account][id]);
    }
    
    function balanceOf(address account) public view returns(uint256, uint256, uint256, uint256) {
        return (
            balanceOf(account, 0),
            balanceOf(account, 1),
            balanceOf(account, 2),
            balanceOf(account, 3)
        );
    }

    function balanceOf() public view returns(uint256, uint256, uint256, uint256) {
        return(balanceOf(msg.sender));
    }

    function totalCards(address player) public view returns (uint256) {
        return(
            balanceOf(player, ROCK) + 
            balanceOf(player, PAPER) + 
            balanceOf(player, SCISSORS)
        );
    }

    // Players can only have one token take request at a time; token take requests ALWAYS send tokens FROM requestee TO requester.
    // In other words, you can request other players give you their tokens, but you cannot request that other players take yours.
    function requestTokenTake(address requestee, uint id, uint amount) public {
        if (players[requestee] == false) {revert PlayerNotFound();}                 // Check that requestee is in the game 
        if (requestee == msg.sender) {revert NoSelfChallenge();}                    // Check that requester and requestee are different accounts
        if ((balanceOf(requestee, id) - commitCount[requestee]) < amount) {revert InsufficientUncommittedTokens();} // Check for sufficient uncommitted requestee tokens
        transferRequests[msg.sender].requestee = requestee;                         // Set requestee
        transferRequests[msg.sender].tokenType = id;                                // Set token type
        transferRequests[msg.sender].amount = amount;                               // Set amount
        emit TransferRequest(msg.sender, requestee, id, amount);                       
    }

    function approveTokenTake(address requestSender) public {
        if (players[requestSender] == false) {revert PlayerNotFound();}             // Check that requestSender is in the game 
        require(transferRequests[requestSender].requestee == msg.sender, "No request from that player."); // Check that requester's request is to requestee

        if (
            (balanceOf(msg.sender, transferRequests[requestSender].tokenType) 
            - commitCount[msg.sender]) < transferRequests[requestSender].amount
            ) {revert InsufficientUncommittedTokens();} // Check for sufficient uncommitted requestee tokens

        incrementToken(requestSender, transferRequests[requestSender].tokenType, transferRequests[requestSender].amount);   // Increment requester's token balance
        decrementToken(msg.sender, transferRequests[requestSender].tokenType, transferRequests[requestSender].amount);      // Decrement requestee's token balance
        emit TransferApproved(requestSender, msg.sender, transferRequests[requestSender].tokenType, transferRequests[requestSender].amount); 
        gameOverCheck(msg.sender);
    }
}
