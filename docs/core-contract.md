# DeFree Smart Contracts

This directory contains the core smart contracts for the DeFree (Decentralized Freelance Platform) project.

## Contracts Overview

### 1. EscrowContract

Manages payment escrow between clients and freelancers.

Key features:

- Multi-token support (any ERC20 token supported by Treasury)
- Project state management (Created, WorkStarted, WorkCompleted, Disputed, Completed)
- Secure fund management with ReentrancyGuard
- Platform fee system (configurable up to 10%)
- 7-day minimum timeout period for dispute resolution
- Upgradeable contract architecture

### 2. TreasuryContract

Manages platform fees and supported tokens.

Key features:

- Multi-token support through whitelist system
- Safe token withdrawal mechanism
- Platform fee collection and management
- Upgradeable contract architecture
- Token balance tracking
- Owner-controlled token support list

## Deployment Order

The contracts should be deployed in the following order:

1. Deploy TreasuryContract

   - Initialize with owner address
   - Add supported tokens

2. Deploy EscrowContract
   - Initialize with Treasury contract address
   - Set initial platform fee (default 5%)
   - Set initial timeout period (default 7 days)

## Security Features

- ReentrancyGuard protection on all fund transfers
- Upgradeable contract architecture using OpenZeppelin
- Owner-controlled critical parameters
- SafeERC20 usage for token transfers
- Strict access control mechanisms
- Input validation and requirement checks
