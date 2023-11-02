import React from 'react';
import { useState, useEffect } from 'react';
import Web3, { ProviderError } from 'web3';
import { ethers } from 'ethers';

import { GameInterface } from './gameInterface';

const abi = require('../remix_abi.json');

let signer = null;
let provider;
let contractINIT;
if (window.ethereum == null) {
  console.log("Metamask not installed; using read-only defaults");
} else {
  provider = new ethers.BrowserProvider(window.ethereum);
  contractINIT = new ethers.Contract('0x94BB080844AC1E043C3326c7f4785bFDdA8386A7', abi, provider);
}

function Web3Container (){

  const [contract, setContract] = useState(contractINIT);

  

  function logAddress(){
    console.log(contract);
  }

  return (
    <div>
    <GameInterface 
      contract={contract} 
      setContract={setContract}
      provider={provider}
      abi={abi}
    />
    <button onClick={logAddress}> LOG ME BRO</button>
    </div>
  );
}

export {Web3Container};




// Old Ganache code -- place at top of script to revert to Ganache testing

// const Ganache = new Web3("ws://127.0.0.1:7545");
// const contract = new Ganache.eth.Contract(abi, '0xFEfdca043c0060981c8c06cd8190FAe56Ff95dcA');
// const abi = require('../RRPS.json').abi;


// Potentially superfluous code for getting accounts from MetaMask

