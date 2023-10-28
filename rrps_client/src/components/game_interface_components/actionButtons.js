import React from "react";
import { useState, useEffect } from "react";

import { InfoDisplay } from './info_display_components/infoDisplay';
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

    useEffect(() => 
    {refreshInfo()}, 
    [
        props, hashCommit, openCommit, challenger,
        hideUI, hashCommitUI, openCommitUI, revealCardUI,
        transferRequestToThisOpponent, transferRequest, transferRequestFromThisOpponent, transferDetails,
    ]);

    async function refreshInfo () {
        getCommits();
        // getTransfers();
    }

    async function getCommits() {
        const outCommit = await props.contract.methods.getCommit(props.currentAddress, props.opponentPlayer).call({from: props.currentAddress});
        const inCommit = await props.contract.methods.getCommit(props.opponentPlayer, props.currentAddress).call({from: props.currentAddress});

        if (outCommit.exists && !inCommit.exists) {
            if (hashCommit !== true) {setHashCommit(true)};
            if (openCommit !== false) {setOpenCommit(false)};
            if (challenger !== outCommit.challenger) {setChallenger(outCommit.challenger)};
            if (challengee !== outCommit.challengee) {setChallengee(outCommit.challengee)};
        } 
        else if (!outCommit.exists && inCommit.exists) {
            if (hashCommit !== true)  {setHashCommit(true)};
            if (openCommit !== false)  {setOpenCommit(false)};
            if (challenger !== inCommit.challenger) {setChallenger(inCommit.challenger)};
            if (challengee !== inCommit.challengee) {setChallengee(inCommit.challengee)};
        }
        else if (outCommit.exists && inCommit.exists) {
            if (hashCommit !== true)  {setHashCommit(true)};
            if (openCommit !== true)  {setOpenCommit(true)};
            if (challenger !== outCommit.challenger) {setChallenger(outCommit.challenger)};
            if (challengee !== outCommit.challengee) {setChallengee(outCommit.challengee)};
        } else if (!outCommit.exists && !inCommit.exists) {
            if (hashCommit !== false)  {setHashCommit(false)};
            if (openCommit !== false)  {setOpenCommit(false)};
            if (challenger !== null) {setChallenger(null)};
            if (challengee !== null) {setChallengee(null)};
        }
    }

    async function getTransfers () {
        const outTransfer = await props.contract.methods.getTransferRequest(props.currentAddress).call({from: props.currentAddress});
        const inTransfer = await props.contract.methods.getTransferRequest(props.opponentPlayer).call({from: props.currentAddress});

        if (outTransfer.exists && outTransfer.requestee !== props.opponentPlayer) {
            setTransferRequest(true);
            setTransferRequestToThisOpponent(false);
        } else if (outTransfer.exists && outTransfer.requestee === props.opponentPlayer) {
            setTransferRequest(true);
            setTransferRequestToThisOpponent(true);
        } else if (!outTransfer.exists) { 
            setTransferRequest(false);
            setTransferRequestToThisOpponent(false);
        }

        if (inTransfer.exists && inTransfer.requestee === props.currentAddress) {
            setTransferRequestFromThisOpponent(true);
            setTransferDetails({id: inTransfer.id, amount: inTransfer.amount});
        } else {
            setTransferRequestFromThisOpponent(false);
            setTransferDetails({id: null, amount: null});
        }
    }

    async function startHashCommit () {
        setHideUI(true);
        setHashCommitUI(true);
    }

    async function startOpenCommit () {
        setHideUI(true);
        setOpenCommitUI(true);
    }

    async function startReveal () {
        setHideUI(true);
        setRevealCardUI(true);
    }

    async function issueHashCommit () {
        try{
            await props.contract.methods.challengeCommit(
                props.opponentPlayer,
                await getHash()
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        setHideUI(false);
        setHashCommitUI(false);
        refreshInfo();
    }

    async function getHash () {
        var hash = await props.contract.methods.hashCommit(tokenType,nonceInput).call({from: props.currentAddress});
        return hash;
    }

    async function withdrawChallenge () {
        try{
            await props.contract.methods.withdrawChallenge(
                props.opponentPlayer
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        refreshInfo();
    }

    async function issueOpenCommit () {
        try{
            await props.contract.methods.openCommit(
                props.opponentPlayer,
                tokenType
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        setHideUI(false);
        setHashCommitUI(false);
        refreshInfo();
    }

    async function issueReveal () {
        try{
            await props.contract.methods.reveal(
                props.opponentPlayer,
                tokenType,
                nonceInput
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        setHideUI(false);
        setRevealCardUI(false);
        refreshInfo();
    }

    async function timeOutWin () {
        try{
            await props.contract.methods.timeOutWin(
                props.opponentPlayer
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        setHideUI(false);
        refreshInfo();
    }

    return (
        <div>
            {!hideUI && <div>       
                {props.opponentPlayer && <div><h3>Select Action:</h3>

                {!hashCommit && !openCommit && <button className='choice-button' onClick={startHashCommit}>Issue Challenge</button>}
                
                {hashCommit &&  !openCommit && props.currentAddress === challenger && <button className='blocked-button'>Challenge Issued</button>}
                {hashCommit &&  !openCommit && props.currentAddress === challenger && <button className='danger-button' onClick={withdrawChallenge}>Withdraw Challenge</button>}
                {hashCommit &&   openCommit && props.currentAddress === challenger && <button className='choice-button' onClick={startReveal}>Reveal Card</button>}
                
                {hashCommit &&  !openCommit && props.currentAddress !== challenger && <button className='choice-button' onClick={startOpenCommit}>Accept Challenge</button>}
                {hashCommit &&   openCommit && props.currentAddress !== challenger && <button className='choice-button' onClick={timeOutWin}>Time Out Win</button>}
                
                {!transferRequestToThisOpponent && !transferRequest && <button className='choice-button' onClick={null}>Propose Transfer</button> }
                {!transferRequestToThisOpponent && transferRequest && <button className='danger-button' onClick={null}>Propose Transfer (Override)</button> }
                {transferRequestToThisOpponent && <button className='danger-button' onClick={null}>Cancel Proposed Transfer</button> }
                {transferRequestToThisOpponent && <button className='blocked-button' onClick={null}>Transfer Proposal Sent</button>}

                {transferRequestFromThisOpponent && <button className='choice-button' onClick={null}>Approve Transfer of {transferDetails.amount} {transferDetails.id} to Opponent</button>}
                {!transferRequestFromThisOpponent && <button className='blocked-button' onClick={null}>No Incoming Transfer Proposal</button>}
                </div>
                }</div>
            }
            <div>
            {hideUI && hashCommitUI &&
            <div>
                <h3>Issue Challenge: </h3>
                <p>Enter password and card below.</p>
                <p>Make sure you take note of the password and card used; you will need this information to reveal your card at the end of the challenge.</p>
                
                <p>Create password:
                <input type="text" maxLength="20" value={nonceInput} onChange={(e) => setNonceInput(e.target.value)}></input>
                </p>
                <div>
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </div>
                <button className='confirm-button' onClick={issueHashCommit}>Submit Challenge</button>
            </div>}
            </div>

            <div>
            {hideUI && openCommitUI &&
            <div>
                <h3>Challenge Response: </h3>

                <p>
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </p>
                <button className='confirm-button' onClick={issueOpenCommit}>Submit Response</button>
            </div>}
            </div>

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
                <button className='confirm-button' onClick={issueReveal}>Submit Reveal</button>
            </div>}



            <InfoDisplay 
                contract={props.contract} 
                currentAddress={props.currentAddress} 
                Ganache={props.Ganache} 
            />
        </div>
    )
}


export { ActionButtons };