import React from "react";
import { useState } from "react";

import { ToggleButtons } from "./toggleButtons.js";

const ActionButtons = function (props) {

    const [hashCommit, setHashCommit] = useState(false);
    const [openCommit, setOpenCommit] = useState(false);
    const [challenger, setChallenger] = useState(null);
    const [challengee, setChallengee] = useState(null);
    
    const [hideUI, setHideUI] = useState(false);
    const [hashCommitUI, setHashCommitUI] = useState(false);
    const [openCommitUI, setOpenCommitUI] = useState(false);
    const [revealCardUI, setRevealCardUI] = useState(false);

    const [transferRequestToThisOpponent, setTransferRequestToThisOpponent] = useState(false);
    const [transferRequest, setTransferRequest] = useState(false); // This is a boolean that is true if player has any open transfer request
    const [transferRequestFromThisOpponent, setTransferRequestFromThisOpponent] = useState(false);
    const [transferDetails, setTransferDetails] = useState({id: null, amount: null});

    const [nonceInput, setNonceInput] = useState('');

    const [tokenType, setTokenType] = React.useState(1);


    async function refreshEvents () {
        var Events = await props.contract.getPastEvents('allEvents', {fromBlock:1})
        .then(function(events) {return events;})
        .catch(function(error) {console.error(error);});

        // Handle hashCommits

        // Handle openCommits

        // Handle 

    }

    async function issueChallenge () {

    }

    return (
        <div>
            {!hideUI && <div>       
                {props.opponentPlayer && <div><h3>Select Action:</h3>

                {!hashCommit && !openCommit && <button className='choice-button' onClick={null}>Issue Challenge</button>}
                
                {hashCommit &&  !openCommit && props.currentAddress === challenger && <button className='blocked-button' onClick={null}>Challenge Issued</button>}
                {hashCommit &&  !openCommit && props.currentAddress === challenger && <button className='danger-button' onClick={null}>Withdraw Challenge</button>}
                {hashCommit &&   openCommit && props.currentAddress === challenger && <button className='choice-button' onClick={null}>Reveal Card</button>}
                
                {hashCommit &&  !openCommit && props.currentAddress !== challenger && <button className='choice-button' onClick={null}>Accept Challenge</button>}
                {hashCommit &&   openCommit && props.currentAddress !== challenger && <button className='choice-button' onClick={null}>Time Out Win</button>}
                
                {!transferRequestToThisOpponent && !transferRequest && <button className='choice-button' onClick={null}>Propose Transfer</button> }
                {!transferRequestToThisOpponent && transferRequest && <button className='danger-button' onClick={null}>Propose Transfer (Override)</button> }
                {transferRequestToThisOpponent && <button className='danger-button' onClick={null}>Cancel Proposed Transfer</button> }
                {transferRequestToThisOpponent && <button className='blocked-button' onClick={null}>Transfer Proposal Sent</button>}

                {transferRequestFromThisOpponent && <button className='choice-button' onClick={null}>Approve Transfer of {transferDetails.amount} {transferDetails.id} to Opponent</button>}
                {!transferRequestFromThisOpponent && <button className='blocked-button' onClick={null}>No Incoming Transfer Proposal</button>}
                </div>
                }</div>
            }

            {hideUI && hashCommitUI &&
            <div>
                <h3>Issue Challenge: </h3>
                <p>Enter password and card below.</p>
                <p>Make sure you make a note of the password and card used; you will need this information to reveal your card at the end of the challenge.</p>
                
                <p>Create password:
                <input type="text" maxLength="20" value={nonceInput} onChange={(e) => setNonceInput(e.target.value)}></input>
                </p>
                <p>
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </p>
                <button className='confirm-button' onClick={null}>Submit Challenge</button>
            </div>}

            {hideUI && openCommitUI &&
            <div>
                <h3>Challenge Response: </h3>

                <p>
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </p>
                <button className='confirm-button' onClick={null}>Submit Response</button>
            </div>}

            {hideUI && revealCardUI &&
            <div>
                <h3>Reveal Secret Card: </h3>
                <p>Enter password and card below.</p>
                <p>If the password and card do not match your original challenge, you will be issued a warning.</p>
                <p>If, on your second attempt, you still cannot produce the correct password and card from your original challenge, you will automatically lose.</p>
                <p>Password:
                <input type="text" maxLength="20" value={nonceInput} onChange={(e) => setNonceInput(e.target.value)}></input>
                </p>
                <p>
                
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </p>
                <button className='confirm-button' onClick={null}>Reveal Card</button>
            </div>}
        </div>
    )
}




export { ActionButtons };