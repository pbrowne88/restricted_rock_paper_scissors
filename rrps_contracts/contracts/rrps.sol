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
    constructor() ERC1155(emptyString) {}

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

    event PlayerHasJoined(address playerAddress); //, string nickname);

    // error NicknameAlreadyExists();
    error AddressAlreadyPlaying();
    error PlayerNotFound();
    error PlayerHasNoStars();
    error PlayerHasNoCards();
    error PlayerHasNoUncommittedCards();
    error PlayerHasNoUncommittedStars();
    error PlayerStillHasStars();
    error PlayerStillHasCards();
    error InsufficientStars();
    // error NicknameNotFound();
    error NoSelfChallenge();
    error PlayerAlreadyChallenged();
    error NotYetChallenged();
    error MustBeRockPaperOrScissors();
    error NeedCopyOfCard();
    error NoOpenCommit();
    error InvalidCardCombination();

    event PlayerHasLeft(address playerAddress);//, string nickname);
    event ChallengerFailedHashOnce(address challenger);//, string nickname);
    event ChallengerFailedHashTwice(address challenger);//, string nickname);

    bytes emptyData = "";
    string emptyString = "";

    enum GameResult {
        Challenger_Loses,
        Tie,
        Challenger_Wins,
        Misplay_Challenger_Loses,   // Result if the challenger doesn't possess a card of the type they committed
        Misplay_Tie,                // Result if neither player posesses the card they committed
        Misplay_Challenger_Wins     // Result if the challengee doesn't possess a card of the type they committed
    }

    function startGame() public {//string memory nickname) public /* payable */ {
        // Check payment
        // require(msg.value >= 0.1 ether);
        // Ensure that nickname is unique
        // if (nicknamesToAddresses[nickname] != address(0)) {revert NicknameAlreadyExists();}
        // Ensure that address is not currently playing the game
        if (players[msg.sender] == true) {revert AddressAlreadyPlaying();}
        // Log the address as playing the game
        players[msg.sender] = true; 
        // Associate the nickname 
        // nicknamesToAddresses[nickname] = msg.sender;
        // addressesToNicknames[msg.sender] = nickname;

        // Emit event
        emit PlayerHasJoined(msg.sender);//, nickname);

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

            //De-register address and nickname
            // nicknamesToAddresses[addressesToNicknames[player]] = address(0);
            // addressesToNicknames[player] = emptyString;
            players[player] = false;
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

        //De-register address and nickname
        // nicknamesToAddresses[addressesToNicknames[msg.sender]] = address(0);
        // addressesToNicknames[msg.sender] = emptyString;
        players[msg.sender] = false;
    }

    // function challengeCommit(string memory challengeeNickname, bytes32 hash) public {
    //     if (nicknamesToAddresses[challengeeNickname] == address(0)) {revert NicknameNotFound();}
    //     challengeCommit(nicknamesToAddresses[challengeeNickname], hash);
    // }

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
        
    }

    // function openCommit(string memory challengerNickname, uint cardType) public {
    //     if (nicknamesToAddresses[challengerNickname] == address(0)) {revert NicknameNotFound();}
    //     openCommit(nicknamesToAddresses[challengerNickname], cardType);
    // }

    // This function is written from the perspective of the challengee
    function openCommit(address challenger, uint cardType) public{

        // Check that challengee has been challenged by challenger
        if (!challenges[challenger][msg.sender].exists) {revert NotYetChallenged();}

        // Check to see if challenger is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challenger] == false){
            delete challenges[challenger][msg.sender];
            emit PlayerHasLeft(challenger);//, addressesToNicknames[challenger]);
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
    }

    // function reveal(string memory challengeeNickname, uint cardType, string calldata salt) public {
    //     if (nicknamesToAddresses[challengeeNickname] == address(0)) {revert NicknameNotFound();} 
    //     reveal(nicknamesToAddresses[challengeeNickname], cardType, salt);
    // }

    // Written from the perspective of the challenger, who must now reveal their card by proving their hash
    function reveal(address challengee, uint cardType, string calldata salt) public {

        // Check that cardType is one of ROCK (1), PAPER (2), SCISSORS (3)
        if(cardType < 1 || cardType > 3) {revert MustBeRockPaperOrScissors();}

        // Check to ensure that an open commit from the challengee exists against the challenger's challenge
        if(!challenges[challengee][msg.sender].exists) {revert NotYetChallenged();}
        if(!challenges[msg.sender][challengee].exists) {revert NoOpenCommit();}

        // Check to see if challengee is still in the game. If they are not, withdraw the challenge and end function early
        if (players[challengee] == false){
            delete challenges[challengee][msg.sender];
            delete challenges[msg.sender][challengee];
            emit PlayerHasLeft(challengee);//, addressesToNicknames[challengee]);
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
            emit ChallengerFailedHashOnce(msg.sender);//, addressesToNicknames[msg.sender]);
            return ();
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
        else {revert InvalidCardCombination();}

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
            mint(challengee, STAR, 1, emptyData);
        }
        if (gameResult == GameResult.Challenger_Wins || gameResult == GameResult.Misplay_Challenger_Wins){
            _burn(challengee, STAR, 1);
            mint(msg.sender, STAR, 1, emptyData);
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

        return();
    }

    // function withdrawChallenge(string memory challengeeNickname) public {
    //     withdrawChallenge(nicknamesToAddresses[challengeeNickname]);
    // }

    function withdrawChallenge(address challengee) public {
        
        // Check that player has an ongoing challenge against another player
        require(challenges[msg.sender][challengee].exists);

        // Ensure that the other player hasn't yet made an open commit to the challenge
        require(challenges[challengee][msg.sender].exists == false);

        // Withdraw the challenge by deregistering and decrementing challengesCount
        delete challenges[msg.sender][challengee];
        challengesCount[msg.sender] -= 1;

    }

    // function withdrawOpenCommit(string memory challengerNickname) public {
    //     withdrawOpenCommit(nicknamesToAddresses[challengerNickname]);
    // }

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
