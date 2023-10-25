import React from 'react';
import { useState } from 'react';

import {InventoryComponent} from './info_display_components/inventoryComponent';
import {TotalsComponent} from './info_display_components/totalsComponent';


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