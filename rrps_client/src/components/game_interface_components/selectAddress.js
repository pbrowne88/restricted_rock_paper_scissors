import React from 'react';
import { useState } from 'react';
import Select from 'react-select';

const SelectAddress = (
    function (props){

      const [playerAddresses, setPlayerAddresses] = useState([{value: null, label: 'No Players'}])

      async function getNicknames(){
        var Events = await props.contract.getPastEvents('allEvents', {fromBlock:1})
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
          var nicknames  = [];
          for (let i = 0; i < Events.length; i++) {
              if (Events[i].event === 'PlayerJoined'){
                const nickname = Events[i].returnValues.nickname;
                const address = Events[i].returnValues.playerAddress;
                nicknames.push({nickname: `${nickname} (${address})`, address: address})
              }

              if (Events[i].event === 'PlayerLeft'){
                const address = Events[i].returnValues.playerAddress;
                nicknames = nicknames.filter((item) => item.address !== address);
              }
            }

          
          return(nicknames);
      }

      async function getAddresses(){
          const addresses = await props.Ganache.eth.getAccounts();
          var addressList = [];
          const nicknames = await readNicknames();
          for (let i = 0; i < addresses.length; i++) {
            const address = addresses[i];
            if (nicknames.find((item) => item.address === address)) {
              addressList.push({label: nicknames.find((item) => item.address === address).nickname, value: address})

            } else {
              addressList.push({label: addresses[i], value: addresses[i]})
            }
            
          }

          setPlayerAddresses(addressList);
      }

      async function handleSelectChange (pchoice) {
        var exists = false;
        if (pchoice) {
           exists = await props.contract.methods.playerExists(pchoice.value).call({from: pchoice.value})          
        }

        props.setCurrentAddress(pchoice);
        props.setCurrentAddressExists(exists);
        props.setOpponentPlayer(null);
      };

      return (
      <div>
          <Select className='select'
          options={playerAddresses}
          value = {props.currentAddress}
          onChange = {handleSelectChange}
          onMenuOpen = {getAddresses}
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

export {SelectAddress}