// App.js
import React, { useState, useEffect } from 'react';
import './App.css';
import {Web3Container} from './components/web3';

function App() {
  return (
    <div className="App">
      <h1>Restricted Rock-Paper-Scissors</h1>
      <Web3Container />
    </div>
  );
}

export default App;

