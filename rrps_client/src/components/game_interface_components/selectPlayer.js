import React from 'react';
import { useState } from 'react';
import Select from 'react-select';

const SelectPlayer = (
    function (props){
    
    const [playerNames, setPlayerNames] = useState([{value: 'No Player', label: 'No Players'}])
    
    async function getNicknames(){
      const Events = await props.contract.queryFilter("*", 0, "latest");
      return Events;
    }
    
    async function readNicknames(){
        var Events = await getNicknames();
        // type Nickname ={label: string; value: string}
        var nicknames  = [];
        for (let i = 0; i < Events.length; i++) {

            // This adds a player that has joined
            if (Events[i].eventName === 'PlayerJoined'){
              const nickname = Events[i].args[1];
              const address = Events[i].args[0];
              nicknames.push({label: `${nickname} (${address})`, value: address})
            }

            // This removes a player that has already joined (and, I presume, won't fail if the player hasn't joined yet)
            if (Events[i].fragment.name === 'PlayerLeft'){
              const address = Events[i].args[0];
              nicknames = nicknames.filter((item) => item.value !== address);
            }
        }

        // This removes the current address from the list of opponents, preventing self-challenges
        if (props.currentAddress){
          nicknames = nicknames.filter((item) => item.value !== props.currentAddress);
        }

        setPlayerNames(nicknames);
    }

    const handleSelectChange = (pchoice) => {
        props.setPlayerChoice(pchoice);
    };

    return (
    <div>
        <Select className='select'
        options={playerNames}
        value = {props.playerChoice}
        onChange = {handleSelectChange}
        onMenuOpen = {readNicknames}
        isClearable = {true}
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
    </div>
 )});

export {SelectPlayer}