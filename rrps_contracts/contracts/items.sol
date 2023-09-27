// SPDX-License-Identifier: MIT
pragma solidity >=0.7.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract Star is ERC721 {

  using Counters for Counters.Counter;
  Counters.Counter public starId;

  constructor() ERC721("Star", "Star") {
    starId.increment();
  }

  function createStars(address to) public {
    starId.increment();
    _safeMint(to, starId.current());
  }
  
}



contract Card is ERC721 {
  
  using Counters for Counters.Counter;
  Counters.Counter public cardId;

  constructor() ERC721("Card", "Card") {
    cardId.increment();
  }


  function createCards(address to) public {
    cardId.increment();
    _safeMint(to, cardId.current());
  }
  
}
