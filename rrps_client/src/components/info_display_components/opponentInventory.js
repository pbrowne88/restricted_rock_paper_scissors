import React from 'react';
import { useState, useEffect } from 'react';

const OpponentInventory = (props) => {

  const [stars, setStars] = useState(0);
  const [rock, setRock] = useState(0);
  const [paper, setPaper] = useState(0);
  const [scissors, setScissor] = useState(0);

  useEffect(() => {
    if (props.currentAddress){
      getBalance()
    }
    });

  async function getBalance(){

    try {
      const inventory = await props.contract.methods.balanceOf().call({from: props.currentAddress})
      
      setStars(parseInt(inventory[0]));
      setRock(parseInt(inventory[1]));
      setPaper(parseInt(inventory[2]));
      setScissor(parseInt(inventory[3]));
    } catch (error){
      console.error(error);
    }
  }

    return (
      <div className="result" style={{position: 'fixed', bottom: 5, right:5 }}>
        {
          <div className="result">
            <h2>Opponent:</h2>
            <p>Stars: {stars}</p>
            <p>Rock: {rock}</p>
            <p>Paper: {paper}</p>
            <p>Scissors: {scissors}</p>
          </div>
        }
      </div>
    );
  };

export {OpponentInventory}