// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract RRPS is ERC1155, Ownable {
    constructor() ERC1155("") {}

    uint public constant STAR = 0;
    uint public constant ROCK = 1; 
    uint public constant PAPER = 2;
    uint public constant SCISSORS = 3;

    mapping(address => bool) players;
    mapping(string => address) nicknamesToAddresses;
    mapping(address => string) addressesToNicknames;
    // string[] nicknameList;

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


    function gameOver(address player) internal {
        //Double check that player has no stars remaining
        require(balanceOf(player, STAR) == 0, "Player still has stars remaining");

        //Burn remaining cards
        _burn(player, ROCK, balanceOf(player, ROCK));
        _burn(player, PAPER, balanceOf(player, PAPER));
        _burn(player, SCISSORS, balanceOf(player, SCISSORS));

        //De-register address and nickname
        nicknamesToAddresses[addressesToNicknames[player]] = address(0);
        addressesToNicknames[player] = "";
        players[player] = false;
    }

    struct challenge {
        address challenger;
        address challengee;
    }

    // Nested mapping allows rapid identification of who is challenging whom
    mapping (address => mapping (address => bool)) challenges; 


    function challengeCommit(address challengee) public view {
        // Check that challenger has at least one star and at least one card remaining
        require(balanceOf(msg.sender, STAR) > 0, "Requires that you have at least one star.");
        require(totalCards(msg.sender) > 0, "Requires that you have at least one card to challenge with.");
        // Check that challengee has at least one star and at least one card remaining
        require(balanceOf(challengee, STAR) > 0, "Requires that the challengee has at least one star.");
        require(totalCards(challengee) > 0);
        // Check that challenger has at least one card not already committed to a challenge
        // Check that challengee doesn't have an open challenge against challenger


    }

    function openCommit(uint cardType) public{
        

    }

    function reveal() public {

    }

    function _burnOneStar() public returns(uint) {
        require(balanceOf(msg.sender, STAR) > 0, "Requires at least one star.");
        _burn(msg.sender, STAR, 1);
        if (balanceOf(msg.sender, STAR) <= 0){
            gameOver(msg.sender);
        }
        return(balanceOf(msg.sender, STAR));
    }



    // event newPlayer()

    function contractBalance() public view returns(uint256){
        return(address(this).balance);
    }

    function totalCards(address player) public view returns (uint256) {
        return(
            balanceOf(player, ROCK) + 
            balanceOf(player, PAPER) + 
            balanceOf(player, SCISSORS)
        );
    }

    function balanceOf() public view returns(uint256, uint256, uint256, uint256) {
        return(balanceOf(msg.sender));
    }
    
    function balanceOf(string memory nickname) public view returns(uint256, uint256, uint256, uint256){
        return(balanceOf(nicknamesToAddresses[nickname]));
    }
    
    function balanceOf(address account) public view returns(uint256, uint256, uint256, uint256) {
        return (
            balanceOf(account, 0),
            balanceOf(account, 1),
            balanceOf(account, 2),
            balanceOf(account, 3)
        );
    }

    function balanceOf(string memory nickname, uint256 id) public view {
        balanceOf(nicknamesToAddresses[nickname], id);
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
}
