import React from 'react';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';

function ToggleButtons(props) {

  const handleAlignment = (event, newAlignment) => {
    if (newAlignment !== null) {
        props.setTokenType(newAlignment);
      }
  };

  return (
    <ToggleButtonGroup
      value={props.tokenType}
      exclusive
      onChange={handleAlignment}
      sx={{ bgcolor: '#00cafa'}}
      
    >
      <ToggleButton value={1}>Rock</ToggleButton>
      <ToggleButton value={2}>Paper</ToggleButton>
      <ToggleButton value={3}>Scissors</ToggleButton>
    </ToggleButtonGroup>
  );
}

function ToggleButtonsFour(props) {

  const handleAlignment = (event, newAlignment) => {
    if (newAlignment !== null) {
        props.setTokenType(newAlignment);
      }
  };

  return (
    <ToggleButtonGroup
      value={props.tokenType}
      exclusive
      onChange={handleAlignment}
      sx={{ bgcolor: '#00cafa'}}
      
    >
      <ToggleButton value={0}>Star</ToggleButton>
      <ToggleButton value={1}>Rock</ToggleButton>
      <ToggleButton value={2}>Paper</ToggleButton>
      <ToggleButton value={3}>Scissors</ToggleButton>
    </ToggleButtonGroup>
  );
}

export {ToggleButtons, ToggleButtonsFour};