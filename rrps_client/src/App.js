// App.js
import React, { useState, useEffect } from 'react';
import './App.css';
import Web3 from 'web3';
import Select from 'react-select'
const abi = require('./RRPS.json').abi;

const optionsForSelect = [
  { value: 'chocolate', label: 'Chocolate' },
  { value: 'strawberry', label: 'Strawberry' },
  { value: 'vanilla', label: 'Vanilla' }
]


function App() {

  const [stars, setStars] = useState(0);
  const [rock, setRock] = useState(0);
  const [paper, setPaper] = useState(0);
  const [scissors, setScissor] = useState(0);

  const [totalStars, setTotalStars] = useState(0);
  const [totalRock, setTotalRock] = useState(0);
  const [totalPaper, setTotalPaper] = useState(0);
  const [totalScissors, setTotalScissor] = useState(0);

  const [playerNames, setPlayerNames] = useState([{value: 'No Player', label: 'No Players'}])
  const [playerChoice, setPlayerChoice] = useState(0x00000000);

  // Web3 Shit
  const Ganache = new Web3("HTTP://127.0.0.1:7545");
  const accounts = Ganache.eth.getAccounts();

  const contract = new Ganache.eth.Contract(abi, '0x3B74336e8dd246A3f2D6489dCC11Ee1292930932');

  async function interact(){
    const providersAccounts = await Ganache.eth.getAccounts();
    // const defaultAccount = providersAccounts[0];
    // const player2 = providersAccounts[1];
    // const player3 = providersAccounts[2];

    const nicknames = ['player1', 'player2', 'player3'];

    for (let i = 0; i < nicknames.length; i++) {
      try{
        await contract.methods.startGame(nicknames[i]).send({
          from: providersAccounts[i],
          gas: 1000000,
        });
      }
      catch (error){
        console.error(error);
      }
    }
  };

  async function getNicknames(){
    var Events = await contract.getPastEvents('allEvents', {fromBlock:1})
    .then(function(events) {
      // Process the retrieved events
      return events;
    })
    .catch(function(error) {
      // Handle errors
      console.error(error);
    });

    return Events;
  }

  async function readNicknames(){
    var Events = await getNicknames();

    var nicknames = [];

    for (let i = 0; i < Events.length; i++) {

      // This adds a player that has joined
      if (Events[i].event === 'PlayerJoined'){
        const nickname = Events[i].returnValues.nickname;
        console.log(nickname); 
  
        const address = Events[i].returnValues.playerAddress;
        console.log(address);

        nicknames.push({label: nickname, value: address})

      }

      // This removes a player that has already joined (and, I presume, won't fail if the player hasn't joined yet)
      if (Events[i].event === 'PlayerLeft'){
        const address = Events[i].returnValues.playerAddress;
        console.log(address);

        nicknames = nicknames.filter((item) => item.value !== address);
      }
    }

    setPlayerNames(nicknames);
  }


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

  async function getTotal(id) {
    const result = await contract.methods.totals(id).call();
    return parseInt(result);
  }

  async function getTotals() {
    setTotalStars(await getTotal(0));
    setTotalRock(await getTotal(1));
    setTotalPaper(await getTotal(2));
    setTotalScissor(await getTotal(3));
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


  const InventoryComponent = () => {
    return (
      <div className="result" style={{position: 'fixed', bottom: 5, left:5 }}>
        {
          <div className="result">
            <h2>Inventory:</h2>
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
            <h2>Totals:</h2>
            <p>Stars: {totalStars}</p>
            <p>Rock: {totalRock}</p>
            <p>Paper: {totalPaper}</p>
            <p>Scissors: {totalScissors}</p>
            <button onClick={getTotals}>Update Inventory</button>
          </div>
        }
      </div>
    );
  };

  const handleSelectChange = (playerChoice) => {
    console.log(playerChoice['value']);
    setPlayerChoice(playerChoice);
  };

  return (
    <div className="App">
      <h1>Restricted Rock-Paper-Scissors</h1>
      <span>&nbsp;&nbsp;</span>
      <button className='choice-button' onClick={interact}>Start Game</button>
      <span>&nbsp;&nbsp;</span>
      <h2>Select Player:</h2>
      <span>&nbsp;&nbsp;</span>
      <Select className='select'
        options={playerNames}
        value = {playerChoice}
        onChange = {handleSelectChange}
        theme = {(theme) => ({
          ...theme,
          borderRadius: 0,
          colors:{
            ...theme.colors,
            text: 'black',
            neutral0: '#22839e',
            neutral5: 'black',
            neutral10: 'black',
            neutral20: 'black',
            neutral30: 'black',
            neutral40: 'black',
            neutral50: 'black',
            neutral80: 'black',
            primary25: 'black',
            primary: '#000277'
          }})}
      />
      <button className='choice-button' onClick={readNicknames}>Nicknames</button>
      <InventoryComponent />
      <TotalsComponent />
    </div>
  );
}

export default App;

