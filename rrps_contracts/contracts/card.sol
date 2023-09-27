// SPDX-License-Identifier: MIT
pragma solidity >=0.7.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Card is ERC721 {
  
  constructor() ERC721("Card", "CD") {
  }
  
}
