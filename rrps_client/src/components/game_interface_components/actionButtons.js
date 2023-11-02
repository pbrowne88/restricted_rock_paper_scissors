import React from "react";
import { useState, useEffect } from "react";

import { ToggleButtons, ToggleButtonsFour } from "./toggleButtons.js";
import NumericInput from 'react-numeric-input';

import {OpponentInventory} from '../info_display_components/opponentInventory.js';

const ActionButtons = function (props) {

    const [hashCommit, setHashCommit] = useState(false);
    const [openCommit, setOpenCommit] = useState(false);
    const [challenger, setChallenger] = useState(null);
    const [challengee, setChallengee] = useState(null);
    
    const [transferRequestToThisOpponent, setTransferRequestToThisOpponent] = useState(false);
    const [transferRequest, setTransferRequest] = useState(false); // This is a boolean that is true if player has any open transfer request
    const [transferRequestFromThisOpponent, setTransferRequestFromThisOpponent] = useState(false);
    const [transferDetails, setTransferDetails] = useState({id: 0, amount: 0});

    const [hideUI, setHideUI] = useState(false);
    const [hashCommitUI, setHashCommitUI] = useState(false);
    const [openCommitUI, setOpenCommitUI] = useState(false);
    const [revealCardUI, setRevealCardUI] = useState(false);
    const [transferRequestUI, setTransferRequestUI] = useState(false);

    const [nonceInput, setNonceInput] = useState('');

    const [tokenType, setTokenType] = React.useState(1);
    const [transferTokenType, setTransferTokenType] = React.useState(0);
    const [transferTokenAmount, setTransferTokenAmount] = React.useState(0);

    useEffect(() => 
    {refreshInfo()}, 
    [
        props, hashCommit, openCommit, challenger,
        hideUI, hashCommitUI, openCommitUI, revealCardUI,
        transferRequestToThisOpponent, transferRequest, transferRequestFromThisOpponent, transferDetails,
    ]);

    async function refreshInfo () {
        getCommits();
        getTransfers();
    }

    async function getCommits() {
        const outCommit = await props.contract.methods.getCommit(props.currentAddress, props.opponentPlayer).call({from: props.currentAddress});
        const inCommit = await props.contract.methods.getCommit(props.opponentPlayer, props.currentAddress).call({from: props.currentAddress});

        if (outCommit.exists && !inCommit.exists) {
            if (hashCommit !== true)                    {setHashCommit(true)};
            if (openCommit !== false)                   {setOpenCommit(false)};
            if (challenger !== outCommit.challenger)    {setChallenger(outCommit.challenger)};
            if (challengee !== outCommit.challengee)    {setChallengee(outCommit.challengee)};
        } 
        else if (!outCommit.exists && inCommit.exists) {
            if (hashCommit !== true)                    {setHashCommit(true)};
            if (openCommit !== false)                   {setOpenCommit(false)};
            if (challenger !== inCommit.challenger)     {setChallenger(inCommit.challenger)};
            if (challengee !== inCommit.challengee)     {setChallengee(inCommit.challengee)};
        }
        else if (outCommit.exists && inCommit.exists) {
            if (hashCommit !== true)                    {setHashCommit(true)};
            if (openCommit !== true)                    {setOpenCommit(true)};
            if (challenger !== outCommit.challenger)    {setChallenger(outCommit.challenger)};
            if (challengee !== outCommit.challengee)    {setChallengee(outCommit.challengee)};
        } 
        else if (!outCommit.exists && !inCommit.exists) {
            if (hashCommit !== false)                   {setHashCommit(false)};
            if (openCommit !== false)                   {setOpenCommit(false)};
            if (challenger !== null)                    {setChallenger(null)};
            if (challengee !== null)                    {setChallengee(null)};
        }
    }

    async function getTransfers () {
        const outTransfer = await props.contract.methods.getTransferRequest(props.currentAddress).call({from: props.currentAddress});
        const inTransfer = await props.contract.methods.getTransferRequest(props.opponentPlayer).call({from: props.currentAddress});

        const tokenList = ["Star", "Rock", "Paper", "Scissors"]
        const id = tokenList[parseInt(inTransfer.tokenType)];
        const amount = parseInt(inTransfer.amount);

        if (outTransfer.exists && outTransfer.requestee !== props.opponentPlayer) {
            if (transferRequest !== true)                   {setTransferRequest(true);}
            if (transferRequestToThisOpponent !== false)    {setTransferRequestToThisOpponent(false)};
        } else if (outTransfer.exists && outTransfer.requestee === props.opponentPlayer) {
            if (transferRequest !== true)                   {setTransferRequest(true);}
            if (transferRequestToThisOpponent !== true)     {setTransferRequestToThisOpponent(true);}
        } else if (!outTransfer.exists) { 
            if (transferRequest !== false)                  {setTransferRequest(false);}
            if (transferRequestToThisOpponent !== false)    {setTransferRequestToThisOpponent(false);}
        }

        if (inTransfer.exists && inTransfer.requestee === props.currentAddress) {
            if (transferRequestFromThisOpponent !== true)   {setTransferRequestFromThisOpponent(true);}
            if (transferDetails.id !== id || transferDetails.amount !== amount) {setTransferDetails({id: id, amount: amount});}
        } else {
            if (transferRequestFromThisOpponent !== false)   {setTransferRequestFromThisOpponent(false);}
            if (transferDetails.id !== null || transferDetails.amount !== null) {setTransferDetails({id: null, amount: null});}
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

    async function cancelAction () {
        setNonceInput('');
        setTokenType(1);
        setHideUI(false);
        setHashCommitUI(false);
        setOpenCommitUI(false);
        setRevealCardUI(false);
        setTransferRequestUI(false);
    }

    async function startTransferProposal () {
        setHideUI(true);
        setTransferRequestUI(true);
    }

    async function issueTransferProposal () {
        try{
            await props.contract.methods.requestTokenTake(
                props.opponentPlayer,
                transferTokenType,
                transferTokenAmount
            ).send({
            from: props.currentAddress,
            gas: 1000000,
            });
        }
        catch (error){
            console.error(error);
        }
        setHideUI(false);
        setTransferRequestUI(false);
    }
    
    async function handleTransferAmountChange (e) {
        if (e < 0) {
            setTransferTokenAmount(0);
        }
        else {
            setTransferTokenAmount(e);
        }
    }

    async function approveTransfer () {
        try{
            await props.contract.methods.approveTokenTake(
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
                
                {!transferRequestToThisOpponent && !transferRequest && <button className='choice-button' onClick={startTransferProposal}>Propose Transfer</button> }
                {!transferRequestToThisOpponent && transferRequest && <button className='danger-button' onClick={startTransferProposal}>Propose Transfer (Override)</button> }
                {transferRequestToThisOpponent && <button className='blocked-button'>Transfer Proposal Sent</button> }

                {transferRequestFromThisOpponent && <button className='choice-button' onClick={approveTransfer}>Approve Transfer of {transferDetails.amount} {transferDetails.id} Token(s) to Opponent</button>}
                {!transferRequestFromThisOpponent && <button className='blocked-button'>No Incoming Transfer Proposal</button>}
                </div>
                }</div>
            }

            {/* Hash Commit UI  */}
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
                <button className='choice-button' onClick={cancelAction}>Cancel</button>
            </div>}
            </div>

            {/* Open Commit UI  */}
            <div>
            {hideUI && openCommitUI &&
            <div>
                <h3>Challenge Response: </h3>

                <p>
                <ToggleButtons tokenType={tokenType} setTokenType={setTokenType} />
                </p>
                <button className='confirm-button' onClick={issueOpenCommit}>Submit Response</button>
                <button className='choice-button' onClick={cancelAction}>Cancel</button>
            </div>}
            </div>

            {/* Reveal Card UI  */}
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
                <button className='choice-button' onClick={cancelAction}>Cancel</button>
            </div>}

            {/* Transfer UI  */}
            {hideUI && transferRequestUI && <div>
                <h3>Propose Transfer:</h3>
                <p>In RRPS, all token transfer requests are requests to recieve tokens from another player. You cannot make a request to send tokens to another player.</p>
                <p>If the opponent approves the transfer request, the tokens will be deposited into your inventory.</p>
                <p>Note that you can only have one active transfer proposal at a time. If you propose a transfer to another player, it will override your current transfer proposal.</p>
                <p>Enter the token type you would like to request from the opponent below, as well as the number of tokens you would like to receieve.</p>
                <div>
                <ToggleButtonsFour tokenType={transferTokenType} setTokenType={setTransferTokenType} />
                </div>
                <div>&nbsp;</div>
                <div>
                <NumericInput min={0} onChange={(e) => handleTransferAmountChange(e)} />
                </div>
                <div>&nbsp;</div>
                <button className='confirm-button' onClick={issueTransferProposal}>Submit Request</button>
                <button className='choice-button' onClick={cancelAction}>Cancel</button>

                
            
            </div>}

            <OpponentInventory provider={props.provider} contract={props.contract} currentAddress={props.opponentPlayer}/>

        </div>
    )
}


export { ActionButtons };