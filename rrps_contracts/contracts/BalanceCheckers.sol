// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract BalanceCheckers is ERC1155 {

    uint public constant STAR = 0;
    uint public constant ROCK = 1; 
    uint public constant PAPER = 2;
    uint public constant SCISSORS = 3;

    mapping(address => bool) players;
    // mapping(string => address) nicknamesToAddresses;
    // mapping(address => string) addressesToNicknames;

    function contractBalance() public view returns(uint256) {
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
    
    // function balanceOf(string memory nickname) public view returns(uint256, uint256, uint256, uint256){
    //     return(balanceOf(nicknamesToAddresses[nickname]));
    // }
    
    function balanceOf(address account) public view returns(uint256, uint256, uint256, uint256) {
        return (
            balanceOf(account, 0),
            balanceOf(account, 1),
            balanceOf(account, 2),
            balanceOf(account, 3)
        );
    }

    // function balanceOf(string memory nickname, uint256 id) internal view {
    //     balanceOf(nicknamesToAddresses[nickname], id);
    // }


}