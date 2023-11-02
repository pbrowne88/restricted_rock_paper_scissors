import React from 'react';
import { useState } from 'react';

import {SelectPlayer} from "./game_interface_components/selectPlayer"
import {SelectAddress} from "./game_interface_components/selectAddress"

import { ActionButtons } from './game_interface_components/actionButtons';

import { InfoDisplay } from './info_display_components/infoDisplay';


function GameInterface (props){

    // Functions and states and stuff go here.

    const [currentAddress, setCurrentAddress] = useState(null);
    const [currentAddressExists, setCurrentAddressExists] = useState(false); // This is a boolean that is true if the current address is in the list of players.
    const [nicknameInput, setNicknameInput] = useState(''); // This is the nickname that the user inputs.
    
    const [opponentPlayer, setOpponentPlayer] = useState(null);
    const [abandonAttempt, setAbandonAttempt] = useState(false); // This is a boolean that is true if the user has clicked the abandon game button.

    function addressHandler(){
        if (currentAddress) {
            return currentAddress.value;
        }
        else {
            return null;
        }
    }

    async function startGame(){     
        if (await props.contract.methods.playerExists(addressHandler()).call({from: addressHandler()})) {
            alert("This address is already playing the game!")
        }
        if (nicknameInput.trim().length < 4){
            alert("Please enter a nickname of at least 4 characters.");
            return;
        }
        try{
            await props.contract.methods.startGame(nicknameInput).send({
                from: addressHandler(),
                // gas: 1000000,
            });
            setCurrentAddress(null);
            setOpponentPlayer(null);
            setNicknameInput('');
        }
        catch (error){
            console.error(error);
        }
    }

    async function abandonGame(){
        try{
            await props.contract.methods.leaveGame().send({
            from: addressHandler(),
            gas: 1000000,
            });
            setCurrentAddress(null);
            setOpponentPlayer(null);
            setAbandonAttempt(false);
        }
        catch (error){
            console.error(error);
        }
    }

    async function cashOut(){
        const inventory = await props.contract.methods.balanceOf().call({from: addressHandler()})
        if (parseInt(inventory[1]) + parseInt(inventory[2]) + parseInt(inventory[1]) > 0){
            alert("You can't cash out while you have cards in your inventory.");
            return ;
        }
        try{
            await props.contract.methods.cashOut().send({
            from: addressHandler(),
            gas: 1000000,
            });
            setCurrentAddress(null);
            setOpponentPlayer(null);
        }
        catch (error){
            console.error(error);
        }
    }

    function abandonAttemptHandler(){
        alert("Are you sure you want to abandon the game?");
        setAbandonAttempt(true);
    }
    
    return (
        <div>
            {!abandonAttempt && <div>
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
            </div>}

            {abandonAttempt && <div>
                    <button className='danger-button' onClick={abandonGame}>Confirm Abandon Game</button>
                    <button className='choice-button' onClick={() => setAbandonAttempt(false)}>Cancel</button>
                </div>
            }

            {!abandonAttempt && currentAddress && !currentAddressExists && <div>
                <h3>Enter Nickname Here:</h3>
                <input type="text" maxLength="20" value={nicknameInput} onChange={(e) => setNicknameInput(e.target.value)}></input>
                <div></div>
                <button className='choice-button' onClick={startGame}>Start Game</button> 
            </div>}



            {!abandonAttempt && currentAddress && currentAddressExists &&
                <div>
                    {!opponentPlayer && <h2>Select Opponent:</h2>}
                    {opponentPlayer && <h2>--VS--</h2>}
                <SelectPlayer 
                    contract={props.contract} 
                    playerChoice={opponentPlayer} 
                    setPlayerChoice={setOpponentPlayer} 
                    Ganache={props.Ganache}
                    currentAddress={addressHandler()} 
                    setCurrentAddress={setCurrentAddress} 
                />
                    {!opponentPlayer && <div>
                    <h3>-- OR --</h3>
                    <button className='danger-button' onClick={abandonAttemptHandler}>Abandon Game</button> 
                    <button className='choice-button' onClick={cashOut}>Cash Out</button>
                    </div>}
                </div>
            }
            {!abandonAttempt && opponentPlayer &&
            <div>
            <ActionButtons
                Ganache={props.Ganache} 
                contract={props.contract} 
                currentAddress={addressHandler()}  
                opponentPlayer={opponentPlayer.value}
            />
            </div>
            }

            <InfoDisplay 
                contract={props.contract} 
                currentAddress={addressHandler()} 
                Ganache={props.Ganache} 
            />


        </div>
    );
}

export {GameInterface};