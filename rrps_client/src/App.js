// App.js
import React, { useState, useEffect } from 'react';
import Select from 'react-select';
import './App.css';
import Web3 from 'web3';

const abi = require('./RRPS.json').abi;

function App() {

  // Web3 Shit


  const Ganache = new Web3("HTTP://127.0.0.1:7545");
  const accounts = Ganache.eth.getAccounts();

  const contract = new Ganache.eth.Contract(abi, '0xEc2226e1a33b4dB2ac8811051F2F7d3Fe0faA232');

  async function interact(){
    const providersAccounts = await Ganache.eth.getAccounts();
    const defaultAccount = providersAccounts[0];
    const player2 = providersAccounts[1];
    const player3 = providersAccounts[2];

    try{
      await contract.methods.startGame().send({
        from: player2,
        gas: 1000000,
      });
    }
    catch (error){
      console.error(error);
    }

    contract.getPastEvents('PlayerHasJoined')
    .then(function(events) {
      // Process the retrieved events
      console.log(events);
    })
    .catch(function(error) {
      // Handle errors
      console.error(error);
    });
  }



  const [stars, setStars] = useState(0);
  const [rock, setRock] = useState(0);
  const [paper, setPaper] = useState(0);
  const [scissors, setScissor] = useState(0);


  async function getBalance(){
    const providersAccounts = await Ganache.eth.getAccounts();
    const defaultAccount = providersAccounts[0];
    const player2 = providersAccounts[1];
    const player3 = providersAccounts[2];

    try {
      const inventory = await contract.methods.balanceOf().call({
        from: player2,
      }
      )
      
      setStars(parseInt(inventory[0]));
      setRock(parseInt(inventory[1]));
      setPaper(parseInt(inventory[2]));
      setScissor(parseInt(inventory[3]));
    } catch (error){
      console.error(error);
    }
  }
  
  

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


  // RPS Shit

  const [playerChoice, setPlayerChoice] = useState(null);
  const [computerChoice, setComputerChoice] = useState(null);
  const [result, setResult] = useState(null);

  const [computerWins, setComputerWins] = useState(0);
  const [playerWins, setPlayerWins] = useState(0);

  const choices = ['rock', 'paper', 'scissors'];

  const generateComputerChoice = () => {
    const randomIndex = Math.floor(Math.random() * choices.length);
    return choices[randomIndex];
  };

  const determineWinner = (player, computer) => {
    if (player === computer) return 'It\'s a tie!';
    if (
      (player === 'rock' && computer === 'scissors') ||
      (player === 'scissors' && computer === 'paper') ||
      (player === 'paper' && computer === 'rock')
    ) {
      setPlayerWins(playerWins + 1);
      return 'You win!';
    }
    setComputerWins(computerWins + 1);
    return 'Computer wins!';
  };

  const playGame = (playerChoice) => {
    const computerChoice = generateComputerChoice();
    const winner = determineWinner(playerChoice, computerChoice);
    
    setPlayerChoice(playerChoice);
    setComputerChoice(computerChoice);
    setResult(winner);
  };


  const InventoryComponent = () => {
    return (
      <div className="result" style={{position: 'fixed', bottom: 5, left:5 }}>
        {
          <div className="result">
            <h2>Your Inventory:</h2>
            <p>Stars: {stars}</p>
            <p>Rock: {rock}</p>
            <p>Paper: {paper}</p>
            <p>Scissors: {scissors}</p>
            <button onClick={getBalance}>Update Inventory</button>
          </div>
        }
      </div>
    );
  };

  const TotalsComponent = () => {
    return (
      <div className="result" style={{position: 'fixed', bottom: 5, right:5 }}>
        {
          <div className="result">
            <h2>Your Inventory:</h2>
            <span>&nbsp;&nbsp;</span>
            <p>Rock: {rock}</p>
            <p>Paper: {paper}</p>
            <p>Scissors: {scissors}</p>
            <button onClick={getBalance}>Update Inventory</button>
          </div>
        }
      </div>
    );

  };

  const ResultsComponent = () => {
    return(
      <div className="result">
        <p>You chose: {playerChoice}</p>
        <p>Computer chose: {computerChoice}</p>
        <p>{result}</p>
        <span>&nbsp;&nbsp;</span>
        <p>Total Player Wins: {playerWins}</p>
        <p>Total Computer Wins (boo): {computerWins}</p>
        <span>&nbsp;&nbsp;</span>
        <span>&nbsp;&nbsp;</span>
        <span>&nbsp;&nbsp;</span>
        <button className="choice-button" onClick={interact}>SEND TRANSACTION</button>
      </div>
    )
  };
    

  return (
    <div className="App">
      <h1>Restricted Rock-Paper-Scissors</h1>
      <div className="choices">
        {choices.map((choice) => (
          <button
            key={choice}
            className="choice-button"
            onClick={() => playGame(choice)}
          >
            {choice}
          </button>
        ))}
      </div>
      <ResultsComponent />
      <InventoryComponent />
      <TotalsComponent />
    </div>
  );
}

export default App;

