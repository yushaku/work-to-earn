# Decentralized Freelance Platform (DeFree)

A blockchain-based freelancing platform that connects clients with freelancers powered by smart contracts.

## Features

### Off-Chain Components

- Job posting and management system
- Job discovery dashboard
- Proposal submission system
- Messaging system between clients and freelancers
- Search and filtering capabilities

### On-Chain Components

- NFT-based professional profiles

  - Skill badges
  - Reputation score
  - Work history
  - Verified credentials

- Smart Contract-based agreements
  - Escrow system
  - Dispute resolution mechanism
  - Automated payments
  - Project timeline management

## Core Smart Contracts Overview

### Escrow Contract

This is the core contract responsible for managing payments and locking funds in escrow. Key functions include:

- Initialization: When a client selects a freelancer, the contract is created with client, freelancer, amount (USDT), progress milestones, and duration.
- Locking: The client must transfer USDT into the contract, typically using ERC-20 for USDT.

**Status management**: The contract has states like:

- Initialization: Waiting for client to send funds.
- Funded: Client has sent USDT.
- Work completed: Platform or freelancer reports work completion (off-chain, but requires signal on chain).
- Approved: Client approves, funds are released to freelancer.
- Dispute: Client or freelancer initiates dispute, contract transitions to dispute resolution.

**Timeouts**: If no action (approve or dispute) is taken within a defined period, funds are automatically released to freelancer.

- Timeout mechanism: After 14 days without response, funds are automatically released to freelancer.
- Detail: Timeout helps protect freelancer from client delay or non-response, an important point to build trust in the system.

### Dispute Resolution Contract

This contract handles disputes between client and freelancer, ensuring fair and transparent decisions. Key functions include:

- Dispute initiation: From Escrow Contract, when client or freelancer calls dispute function, funds are held in Escrow Contract, and state transitions to "dispute".
- Decision: Can use a predefined arbitrator or complex mechanism like DAO voting. For simplicity, assume using arbitrator:

  - Arbitrator address is defined in the contract, only they can call decision function.
  - Decision can be: pay entire amount to freelancer, return to client, or split.
  - Interaction:
    - Receive request from Escrow Contract when dispute is initiated.
    - Call decision function in Escrow Contract to release funds based on decision.

### Reputation Contract

This contract manages reputation scores for freelancers and clients based on feedback after completion. Key functions include:

- Feedback storage: After completion, client and freelancer can leave feedback, which is stored on chain.
- Reputation calculation: Based on feedback, reputation scores are calculated.
- Display: Reputation scores are displayed when freelancers bid or clients select freelancers.
- Interaction:
  - After completion, client and freelancer can leave feedback, which is stored on chain.
  - Cung cấp dữ liệu cho Job Listing Contract để hiển thị uy tín khi đấu thầu.

## operation process

1. Post job and bidding (off-chain)

- Step 1: Client posts job description, budget, and deadline on off-chain interface.
- Step 2: Freelancer views job listings and submits a bid through off-chain interface, including experience and price.
- Step 3: Client views bids and selects suitable freelancer for the project.

2. Create Escrow contract (on-chain)

- Step 4: After selecting freelancer, the system creates an Escrow contract on blockchain, recording information such as client and freelancer addresses, token used (e.g. USDT), and project deadline.
- Step 5: The system calculates the total amount of money the client needs to deposit, including the service fee. For example, with a 1% client fee, the total deposit amount is 101 USDT (100 USDT for the project + 1 USDT fee).
- Step 6: Client deposits the money (101 USDT) into the Escrow contract via a digital wallet (e.g. MetaMask) on the system's interface.

3. Freelancer performs work

- Step 7: Freelancer starts working on the project, communicating with the client through the off-chain interface or third-party tools.
- Step 8: When completing a milestone, freelancer reports through the off-chain interface, the system records and notifies the client to review.

4. Client reviews or disputes

- Step 9: Client reviews the work result of the milestone. If satisfied, client clicks "Approve" on the interface, triggering the approve() function in the Escrow contract.
- Step 10: The contract automatically distributes the money:
  Freelancer receives 97 USDT (100 USDT minus 3% freelancer fee).
  Platform receives 4 USDT (1 USDT client fee + 3 USDT freelancer fee).
- Step 11: If client is not satisfied, they can initiate a dispute by calling the dispute function in the Escrow contract. The contract transitions to the dispute state, and the arbitrator will review and decide how to distribute the money.

5. Automatic payout after waiting period

- Step 12: If client does not respond (approve or dispute) within the specified time (e.g. 14 days), the contract will automatically payout according to the timeout mechanism: 97 USDT to freelancer and 4 USDT to the platform.

6. Update reputation (optional)

- Step 13: After completing a milestone or the entire project, client and freelancer can rate each other through the off-chain interface. The system can update the reputation score on the blockchain if integrated with the reputation contract.

7. Project completion

- Step 14: When all milestones are completed and the money is fully distributed, the project is marked as completed on the off-chain interface.
