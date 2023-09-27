// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Card, Star} from "./items.sol";


contract RRPS {

  mapping(address => bool) players;
  mapping(string => address) nicknames;

  Star starNFT = new Star();
  Card cardNFT = new Card();

  function dealIn(address playerAddress) public {
    
    for (uint i=0; i <= 3; i++){
      starNFT.createStars(playerAddress);

    }
  }

  function startGame(string memory nickname) payable public {
    require(players[msg.sender] == false);
    players[msg.sender] = true;
    nicknames[nickname] = msg.sender;
    dealIn(msg.sender);
  }
}
