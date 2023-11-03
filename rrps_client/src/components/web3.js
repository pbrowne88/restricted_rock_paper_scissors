import React from 'react';
import { useState, useEffect } from 'react';
import Web3, { ProviderError } from 'web3';
import { ethers } from 'ethers';

import { GameInterface } from './gameInterface';

const abi = require('../remix_abi.json');

const contractAddress = '0x94BB080844AC1E043C3326c7f4785bFDdA8386A7';

let signer = null;
let provider;
let contractINIT;
if (window.ethereum == null) {
  console.log("Metamask not installed; using read-only defaults");
} else {
  provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner(0);
  contractINIT = new ethers.Contract(contractAddress, abi, provider);
}

function Web3Container (){

  const [contract, setContract] = useState(contractINIT);

  return (
    <div>
    <GameInterface 
      contractAddress={contractAddress}
      contract={contract} 
      setContract={setContract}
      provider={provider}
      abi={abi}
    />
    </div>
  );
}

export {Web3Container};




// Old Ganache code -- place at top of script to revert to Ganache testing

// const Ganache = new Web3("ws://127.0.0.1:7545");
// const contract = new Ganache.eth.Contract(abi, '0xFEfdca043c0060981c8c06cd8190FAe56Ff95dcA');
// const abi = require('../RRPS.json').abi;
