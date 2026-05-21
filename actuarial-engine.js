/**
 * Calculates the fair premium for a parametric policy 
 * based on probability of event and protocol margin.
 */
function calculatePremium(coverageAmount, probabilityOfEvent, marginBps) {
    const basePremium = (BigInt(coverageAmount) * BigInt(Math.floor(probabilityOfEvent * 10000))) / 10000n;
    const protocolFee = (basePremium * BigInt(marginBps)) / 10000n;
    
    return basePremium + protocolFee;
}

module.exports = { calculatePremium };
