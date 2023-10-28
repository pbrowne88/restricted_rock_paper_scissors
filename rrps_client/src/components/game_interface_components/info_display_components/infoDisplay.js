import React from 'react';
import { useState } from 'react';

import {InventoryComponent} from './inventoryComponent';
import {TotalsComponent} from './totalsComponent';


function InfoDisplay (props){

    // Functions and states and stuff go here.

    return (
        <div>
            <InventoryComponent ganache={props.Ganache} contract={props.contract} currentAddress={props.currentAddress}/>
            <TotalsComponent contract={props.contract}/>
        </div>
    );
}

export {InfoDisplay};