import React from "react";
import { useState, useEffect } from "react";



const TotalsComponent = (props) => {
    const [totalStars, setTotalStars] = useState(0);
    const [totalRock, setTotalRock] = useState(0);
    const [totalPaper, setTotalPaper] = useState(0);
    const [totalScissors, setTotalScissor] = useState(0);

    useEffect(() => {getTotals()});
    

    async function getTotal(id) {
        const result = await props.contract.totals(id);
        return parseInt(result);
    }

    async function getTotals() {
        setTotalStars(await getTotal(0));
        setTotalRock(await getTotal(1));
        setTotalPaper(await getTotal(2));
        setTotalScissor(await getTotal(3));
        }

    return (
        <div className="result" style={{position: 'fixed', bottom: 5, right:5 }}>
        {
            <div className="result">
            <h2>Totals:</h2>
            <p>Stars: {totalStars}</p>
            <p>Rock: {totalRock}</p>
            <p>Paper: {totalPaper}</p>
            <p>Scissors: {totalScissors}</p>
            </div>
        }
        </div>
    );
};

export {TotalsComponent}