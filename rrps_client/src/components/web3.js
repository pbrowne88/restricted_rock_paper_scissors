import React from 'react';
import { useState, useEffect } from 'react';
import Web3, { ProviderError } from 'web3';

import { GameInterface } from './gameInterface';

// const Ganache = new Web3("ws://127.0.0.1:7545");
// const contract = new Ganache.eth.Contract(abi, '0xFEfdca043c0060981c8c06cd8190FAe56Ff95dcA');
// const abi = require('../RRPS.json').abi;

const abi = require('../remix_abi.json');

function Web3Container (){

  const web3 = new Web3(window.ethereum)
  const contract = new web3.eth.Contract(abi, '0x94BB080844AC1E043C3326c7f4785bFDdA8386A7')

  const [account, setAccount] = useState('');
  // const [contract, setContract] = useState(null);

  useEffect(() => {
    async function loadWeb3() {
      if (window.ethereum) {
        // const web3Instance = new ;
        // setWeb3(web3Instance);
        // setContract(new web3.eth.Contract(abi, '0x94BB080844AC1E043C3326c7f4785bFDdA8386A7'))
        try {
          // Request account access if needed
          await window.ethereum.enable();
          // Get the user's Ethereum address
          const accounts = await web3.eth.getAccounts();
          setAccount(accounts[0]);
        } catch (error) {
          console.error('Error connecting to MetaMask:', error);
        }
      } else {
        console.error('MetaMask not detected. Please install MetaMask.');
      }
    }

    loadWeb3();
  }, []);


  function logAddress(){
    console.log(contract);
  }



    return (
      <div>
      <GameInterface 
        contract={contract} 
        Ganache={web3}
      />
      <button onClick={logAddress}> LOG ME BRO</button>
      </div>
    );
}

export {Web3Container};