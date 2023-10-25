import React from 'react';
import { useState } from 'react';

const InventoryComponent = (props) => {

  const [stars, setStars] = useState(0);
  const [rock, setRock] = useState(0);
  const [paper, setPaper] = useState(0);
  const [scissors, setScissor] = useState(0);

  async function getBalance(){
    const providersAccounts = await props.ganache.eth.getAccounts();
    const defaultAccount = providersAccounts[0];
    const player2 = providersAccounts[1];
    const player3 = providersAccounts[2];

    try {
      const inventory = await props.contract.methods.balanceOf().call({
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

export {InventoryComponent}