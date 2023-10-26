import React from 'react';
import { useState } from 'react';

import {SelectPlayer} from "./game_interface_components/selectPlayer"
import {SelectAddress} from "./game_interface_components/selectAddress"

import { InfoDisplay } from './infoDisplay';

function GameInterface (props){

    // Functions and states and stuff go here.

    const [currentAddress, setCurrentAddress] = useState(null);
    const [currentAddressExists, setCurrentAddressExists] = useState(false); // This is a boolean that is true if the current address is in the list of players.
    const [opponentPlayer, setOpponentPlayer] = useState(0x00000000);

    const [nicknameInput, setNicknameInput] = useState(''); // This is the nickname that the user inputs.

    async function startGame(){     
        if (nicknameInput.trim().length < 4){
            alert("Please enter a nickname of at least 4 characters.");
            return;
        }
        try{
            await props.contract.methods.startGame(nicknameInput).send({
            from: currentAddress.value,
            gas: 1000000,
            });
            setCurrentAddress(null);
        }
        catch (error){
            console.error(error);
        }
    }

    async function abandonGame(){
        try{
            await props.contract.methods.leaveGame().send({
            from: currentAddress.value,
            gas: 1000000,
            });
            setCurrentAddress(null);
        }
        catch (error){
            console.error(error);
        }
    }

    async function cashOut(){
        try{
            await props.contract.methods.cashOut().send({
            from: currentAddress.value,
            gas: 1000000,
            });
            setCurrentAddress(null);
        }
        catch (error){
            console.error(error);
        }
    }
    
    return (
        <div>
            <div>
            <h2>Select Your Player:</h2>
            <SelectAddress 
                currentAddress={currentAddress} 
                setCurrentAddress={setCurrentAddress} 
                currentAddressExists={currentAddressExists}
                setCurrentAddressExists={setCurrentAddressExists}
                setOpponentPlayer={setOpponentPlayer}
                Ganache={props.Ganache} 
                contract={props.contract}
            />
            </div>

            {currentAddress && !currentAddressExists && <div>
                <h3>Enter Nickname Here:</h3>
                <input type="text" maxLength="20" pattern="[a-zA-Z0-9]+" value={nicknameInput} onChange={(e) => setNicknameInput(e.target.value)}></input>
                <div></div>
                <button className='choice-button' onClick={startGame}>Start Game</button> 
            </div>}

            {currentAddress && currentAddressExists &&
                <div>
                    <button className='choice-button' onClick={abandonGame}>Abandon Game</button> 
                    <button className='choice-button'>Cash Out</button> 
                <h2>Select Opponent:</h2>
                <SelectPlayer 
                    contract={props.contract} 
                    playerChoice={opponentPlayer} 
                    setPlayerChoice={setOpponentPlayer} 
                    Ganache={props.Ganache}
                    currentAddress={currentAddress} 
                    setCurrentAddress={setCurrentAddress} 
                />
                </div>
            }

            <InfoDisplay 
                contract={props.contract} 
                currentAddress={currentAddress} 
                Ganache={props.Ganache} 
            />
        </div>
    );
}

export {GameInterface};