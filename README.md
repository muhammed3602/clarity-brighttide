# BrightTide
A decentralized fundraising platform for community projects with gamified donor rewards built on Stacks blockchain.

## Features
- Create fundraising campaigns with targets and deadlines
- Make donations to campaigns
- Earn donor rewards based on contribution levels
- Track campaign progress and status
- Withdraw funds once campaign goals are met

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new campaign
(contract-call? .brighttide create-campaign "Clean Beach Project" u10000 u100 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Make a donation
(contract-call? .brighttide donate u1 u500)

;; Check campaign status
(contract-call? .brighttide get-campaign-info u1)

;; Withdraw funds (once goal is met)
(contract-call? .brighttide withdraw-funds u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
