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

- Create separate commit trackers for each kind of card (rock, paper, scissors) so that 
  players can't commit to a challenge with a card they don't have, and so that players
  can't trade away cards they (might) have committed to a challenge.

*/


contract RRPS is ERC1155, Ownable, BalanceCheckers {
    constructor() ERC1155(emptyString) {}

    struct commit {
        bytes32 hash;
        uint cardType;
        bool exists;
        bool hashStrike; 
        uint blockNum;
    }

    enum GameResult {
        Challenger_Loses,
        Tie,
        Challenger_Wins,
        Misplay_Challenger_Loses,   // Result if the challenger doesn't possess a card of the type they committed
        Misplay_Tie,                // Result if neither player posesses the card they committed
        Misplay_Challenger_Wins     // Result if the challengee doesn't possess a card of the type they committed
    }

    mapping (address => bool) players;
    mapping (address => mapping (address => commit)) challenges;
    mapping (address => uint) challengesCount;
    
    error AddressAlreadyPlaying();
    error PlayerNotFound();
    error PlayerHasNoStars();
    error PlayerHasNoCards();
    error PlayerHasNoUncommittedCards();
    error PlayerHasNoUncommittedStars();
    error PlayerStillHasStars();
    error PlayerStillHasCards();
    error InsufficientStars();
    error NoSelfChallenge();
    error PlayerAlreadyChallenged();
    error NotYetChallenged();
    error MustBeRockPaperOrScissors();
    error NeedCopyOfCard();
    error NoOpenCommit();
    error InvalidCardCombination();
    error OtherPlayerAlreadyCommitted();

    event PlayerJoined(address playerAddress, string nickname);
    event PlayerLeft(address playerAddress); // A player has left the game for any reason
    event PlayerEliminated(address playerAddress);  // Player has lost all of their stars
    event PlayerCashedOut(address playerAddress); // Player voluntarily cashes out
    
    event ChallengeCommit(address challenger, address challengee); // Challenger has issued a challenge to challengee
    event OpenCommit(address challenger, address challengee); // Challengee has made an open commit to challenger's challenge

    event ChallengerWins(address challenger, uint challengerCard, address challengee, uint challengeeCard); // Challenger has won the challenge against challengee
    event ChallengerLoses(address challenger, uint challengerCard, address challengee, uint challengeeCard); // Challengee has won the challenge against challenger
    event Tie(address challenger, uint challengerCard, address challengee, uint challengeeCard); // Challenger and challengee have tied
    event Misplay(address player, uint card); // Player has misplayed a card

    event WithdrawnChallengeCommit(address challenger, address challengee); // Challenger has withdrawn their challenge to challengee
    event WithdrawnOpenCommit(address challenger, address challengee); // Challengee has withdrawn their open commit to challenger
    
    event OrphanedChallenge(address challenger, address challengee); // Player left unresolved challenges behind
    event ChallengerFailedHashOnce(address challenger, address challengee); // Challenger failed to solve hash once
    event ChallengerFailedHashTwice(address challenger, address challengee); // Challenger failed to solve hash twice (auto-loss of star with no card burnt)

    event TokenTransfer(address from, address to, uint256 id, uint256 amount); // ERC1155 Transfer event

    bytes emptyData = "";
    string emptyString = "";

    function startGame(string memory nickname) public /* payable */ {
        // Check payment
        // require(msg.value >= 0.1 ether);
        // Ensure that address is not currently playing the game
        if (players[msg.sender] == true) {revert AddressAlreadyPlaying();}
        // Log the address as playing the game
        players[msg.sender] = true; 
        // Set challenges count to zero;
        challengesCount[msg.sender] = 0;


        // Emit event
        emit PlayerJoined(msg.sender, nickname);

        // Mint new set of cards
        mint(msg.sender, ROCK, 4, emptyData);
        mint(msg.sender, PAPER, 4, emptyData);
        mint(msg.sender, SCISSORS, 4, emptyData);
        
        // Mint new set of stars
        mint(msg.sender, STAR, 3, emptyData);
    }

    function gameOverCheck(address player) internal {
        //Check if player has no stars remaining
        if (balanceOf(player, STAR) == 0){
            // DOUBLE check!
            if (balanceOf(player, STAR) > 0) {revert PlayerStillHasStars();}

            //Burn remaining cards
            _burn(player, ROCK, balanceOf(player, ROCK));
            _burn(player, PAPER, balanceOf(player, PAPER));
            _burn(player, SCISSORS, balanceOf(player, SCISSORS));


            players[player] = false;
            emit PlayerEliminated(player);
            emit PlayerLeft(player);
        }
    }

    function cashOut() public {
        // Check that player has no cards remaining
        if (totalCards(msg.sender) > 0) {revert PlayerStillHasCards();}
        // Check that player has 3 or more stars remaining
        if (balanceOf(msg.sender, STAR) < 3) {revert InsufficientStars();}

        // TODO: Implement cashing out stars from the contract's account -- 0.03 Eth per star on a 0.1 Eth buyin?
        // For now, just burn the remaining stars
        _burn(msg.sender, STAR, balanceOf(msg.sender, STAR)); 

        players[msg.sender] = false;
        emit PlayerCashedOut(msg.sender);
        emit PlayerLeft(msg.sender);
    }

    // This function is written from the perspective of the challenger
    function challengeCommit(address challengee, bytes32 hash) public {

        // Check that player is in the game 
        if (players[msg.sender] == false) {revert PlayerNotFound();}

        // Check that challenger and challengee are different accounts
        if (msg.sender == challengee) {revert NoSelfChallenge();}

        // Check that challenger has at least one star and at least one card remaining
        if (balanceOf(msg.sender, STAR) == 0) {revert PlayerHasNoStars();}
        if (totalCards(msg.sender) == 0) {revert PlayerHasNoCards();}
        
        // Check that challengee has at least one star and at least one card remaining
        if (balanceOf(challengee, STAR) == 0) {revert PlayerHasNoStars();}
        if (totalCards(challengee) == 0) {revert PlayerHasNoCards();}

        // Check that challenger has at least one card and at least one star not already committed to a challenge
        if ((totalCards(msg.sender) - challengesCount[msg.sender]) < 1) {revert PlayerHasNoUncommittedCards();}
        if ((balanceOf(msg.sender, STAR) - challengesCount[msg.sender]) < 1) {revert PlayerHasNoUncommittedStars();}

        // Check that challengee has at least one card and at least one star not already committed to a challenge
        if ((totalCards(challengee) - challengesCount[challengee]) < 1) {revert PlayerHasNoUncommittedCards();}
        if ((balanceOf(challengee, STAR) - challengesCount[challengee]) < 1) {revert PlayerHasNoUncommittedStars();}

        // Check that challengee doesn't have an open challenge against challenger and vise versa
        if (challenges[challengee][msg.sender].exists) {revert PlayerAlreadyChallenged();}
        if (challenges[msg.sender][challengee].exists) {revert PlayerAlreadyChallenged();}

        // Set challenges mapping challenger -> challengee -> cardType and increment challengeCount for challenger 
        challenges[msg.sender][challengee].hash = hash;
        challenges[msg.sender][challengee].exists = true;
        challengesCount[msg.sender] += 1;

        emit ChallengeCommit(msg.sender, challengee);
    }

    // This function is written from the perspective of the challengee
    function openCommit(address challenger, uint cardType) public{

        // Check that player is in the game 
        if (players[msg.sender] == false) {revert PlayerNotFound();}

        // Check that challengee has been challenged by challenger
        if (!challenges[challenger][msg.sender].exists) {revert NotYetChallenged();}

        // Check to see if challenger is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challenger] == false){
            delete challenges[challenger][msg.sender];
            emit OrphanedChallenge(challenger, msg.sender);
            return ();
        }

        // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        if(cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}

        // Check that challenger and challengee are different accounts
        if (msg.sender == challenger) {revert NoSelfChallenge();}

        // Check that challengee has at least one card and at least one star not already committed to a challenge
        if ((totalCards(msg.sender) - challengesCount[msg.sender]) < 1) {revert PlayerHasNoUncommittedCards();}
        if ((balanceOf(msg.sender, STAR) - challengesCount[msg.sender]) < 1) {revert PlayerHasNoUncommittedStars();}

        // Check that challengee has at least one copy of the card they're trying to commit
        if(balanceOf(msg.sender, cardType) < 1) {revert NeedCopyOfCard();}

        // Set challenges mapping challengee -> challenger -> cardType
        challenges[msg.sender][challenger].cardType = cardType;
        challenges[msg.sender][challenger].exists = true;

        // Increment challengeCount for challengee 
        challengesCount[msg.sender] += 1;

        emit OpenCommit(challenger, msg.sender);
    }

    // Written from the perspective of the challenger, who must now reveal their card by proving their hash
    function reveal(address challengee, uint cardType, string calldata salt) public {

        // Check that player is in the game 
        if (players[msg.sender] == false) {revert PlayerNotFound();}

        // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        if(cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}

        // Check to ensure that an open commit from the challengee exists against the challenger's challenge (which also needs to exist)
        if(!challenges[challengee][msg.sender].exists) {revert NotYetChallenged();}
        if(!challenges[msg.sender][challengee].exists) {revert NoOpenCommit();}

        // Check to see if challengee is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challengee] == false){
            delete challenges[challengee][msg.sender];
            delete challenges[msg.sender][challengee];
            challengesCount[msg.sender] -= 1;
            emit OrphanedChallenge(msg.sender, challengee);
            return ();
        }

        // Check that challenger isn't revealing against themselves
        if (msg.sender == challengee) {revert NoSelfChallenge();}

        // Check that challenger's hash is solved using the card type and salt.
        // If they fail to do so, they get a hash strike and the function returns.
        uint challengerCard;

        if (hashCommit(cardType, salt) == challenges[msg.sender][challengee].hash && balanceOf(msg.sender, cardType) > 0){
            challengerCard = cardType;
        } else if (!challenges[msg.sender][challengee].hashStrike) {
            challenges[msg.sender][challengee].hashStrike = true;
            emit ChallengerFailedHashOnce(msg.sender, challengee);
            return ();
        } else {
            emit ChallengerFailedHashTwice(msg.sender, challengee);
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
        else {revert InvalidCardCombination();}

        // If the outcome is legitimate, burn both cards used, otherwise, only burn the legit cards.

        if      (gameResult == GameResult.Misplay_Challenger_Loses)     {_burn(challengee, challengeeCard, 1); emit Misplay(msg.sender, challengerCard);}
        else if (gameResult == GameResult.Misplay_Challenger_Wins)      {_burn(msg.sender, challengerCard, 1); emit Misplay(challengee, challengeeCard);}
        else {
            _burn(msg.sender, challengerCard, 1);
            _burn(challengee, challengeeCard, 1);
        }

        // If there's a winner, move one star from loser to winner
        if (gameResult == GameResult.Challenger_Loses || gameResult == GameResult.Misplay_Challenger_Loses){
            _burn(msg.sender, STAR, 1);
            mint(challengee, STAR, 1, emptyData);
            emit ChallengerLoses(msg.sender, challengerCard, challengee, challengeeCard);
        }
        if (gameResult == GameResult.Challenger_Wins || gameResult == GameResult.Misplay_Challenger_Wins){
            _burn(challengee, STAR, 1);
            mint(msg.sender, STAR, 1, emptyData);
            emit ChallengerWins(msg.sender, challengerCard, challengee, challengeeCard);
        }
        // If the result is a double misplay, burn one star from both participants.
        if (gameResult == GameResult.Misplay_Tie) {
            _burn(msg.sender, STAR, 1);
            _burn(challengee, STAR, 1);
            emit Misplay(msg.sender, challengerCard);
            emit Misplay(challengee, challengeeCard);
        }
        // If the result is a legitimate tie, no stars change hands
        if (gameResult == GameResult.Tie) {
            emit Tie(msg.sender, challengerCard, challengee, challengeeCard);
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
    }

    function withdrawChallenge(address challengee) public {
        
        // Check that player has an ongoing challenge against another player
        if (!challenges[msg.sender][challengee].exists) {revert NotYetChallenged();}

        // Ensure that the other player hasn't yet made an open commit to the challenge
        if(challenges[challengee][msg.sender].exists) {revert OtherPlayerAlreadyCommitted();}

        // Withdraw the challenge by deregistering and decrementing challengesCount
        delete challenges[msg.sender][challengee];
        challengesCount[msg.sender] -= 1;
        emit WithdrawnChallengeCommit(msg.sender, challengee);
    }

    function withdrawOpenCommit(address challenger) public {

        // Check that sender (challengee) has made an open commit against another player's ongoing challenge
        if(!challenges[msg.sender][challenger].exists) {revert NotYetChallenged();}

        // Withdraw the open commit by deregistering and decrementing challengesCount
        delete challenges[msg.sender][challenger];
        challengesCount[msg.sender] -= 1;
        emit WithdrawnOpenCommit(challenger, msg.sender);
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

    // Pure hash function
    function hashCommit(uint cardType, string calldata salt) public view returns(bytes32) {
        if(cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}
        return keccak256(abi.encodePacked(msg.sender, cardType, salt));
    }

    // Transfer Overrides

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
