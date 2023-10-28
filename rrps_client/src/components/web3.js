import React from 'react';
import { useState } from 'react';
import Web3, { ProviderError } from 'web3';

import { GameInterface } from './gameInterface';

const abi = require('../RRPS.json').abi;

const Ganache = new Web3("ws://127.0.0.1:7545");
const contract = new Ganache.eth.Contract(abi, '0xAAe097b9cE4DAC4AcCbFDfe0B949BfF93feb5bc3');


function Web3Container (){

  // Metamask Shit

  // const [web3, setWeb3] = useState(null);
  // const [account, setAccount] = useState('');

  // useEffect(() => {
  //   async function loadWeb3() {
  //     if (window.ethereum) {
  //       const web3Instance = new Web3(window.ethereum);
  //       setWeb3(web3Instance);

  //       try {
  //         // Request account access if needed
  //         await window.ethereum.enable();
  //         // Get the user's Ethereum address
  //         const accounts = await web3Instance.eth.getAccounts();
  //         setAccount(accounts[0]);
  //       } catch (error) {
  //         console.error('Error connecting to MetaMask:', error);
  //       }
  //     } else {
  //       console.error('MetaMask not detected. Please install MetaMask.');
  //     }
  //   }

  //   loadWeb3();
  // }, []);


  // async function displayWallet(){
  //   console.log(account)
  // }



    return (
      <div>
      <GameInterface 
        contract={contract} 
        Ganache={Ganache}
        Web3={Web3}
      />
      </div>
    );
}

export {Web3Container};