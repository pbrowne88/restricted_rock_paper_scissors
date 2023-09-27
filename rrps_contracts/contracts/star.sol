// SPDX-License-Identifier: MIT
pragma solidity >=0.7.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Star is ERC721 {
  
  constructor() ERC721("Star", "ST") {
  }
  
}
