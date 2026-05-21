// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InsurancePool is ReentrancyGuard, Ownable {
    struct Policy {
        address insured;
        uint256 coverageAmount;
        uint256 expiry;
        bytes32 triggerId;
        bool claimed;
    }

    IERC20 public immutable paymentToken;
    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;
    
    uint256 public totalLiquidity;
    uint256 public lockedCapital;

    event PolicyCreated(uint256 indexed policyId, address indexed insured, uint256 coverage);
    event ClaimPaid(uint256 indexed policyId, address indexed recipient, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        paymentToken = IERC20(_token);
    }

    function provideLiquidity(uint256 _amount) external {
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        totalLiquidity += _amount;
    }

    function purchasePolicy(uint256 _coverage, uint256 _premium, bytes32 _triggerId, uint256 _duration) external {
        require(totalLiquidity - lockedCapital >= _coverage, "Insufficient pool solvency");
        
        paymentToken.transferFrom(msg.sender, address(this), _premium);
        
        uint256 policyId = policyCount++;
        policies[policyId] = Policy({
            insured: msg.sender,
            coverageAmount: _coverage,
            expiry: block.timestamp + _duration,
            triggerId: _triggerId,
            claimed: false
        });

        lockedCapital += _coverage;
        emit PolicyCreated(policyId, msg.sender, _coverage);
    }

    function triggerPayout(uint256 _policyId) external onlyOwner {
        Policy storage policy = policies[_policyId];
        require(!policy.claimed, "Already claimed");
        require(block.timestamp <= policy.expiry, "Policy expired");

        policy.claimed = true;
        lockedCapital -= policy.coverageAmount;
        totalLiquidity -= policy.coverageAmount;
        
        paymentToken.transfer(policy.insured, policy.coverageAmount);
        emit ClaimPaid(_policyId, policy.insured, policy.coverageAmount);
    }
}
