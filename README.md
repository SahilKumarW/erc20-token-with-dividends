# ERC20 Token with Dividends

Mintable/burnable ERC-20 token backed 1:1 by ETH with pro-rata dividend distribution

## Overview
A mintable/burnable ERC-20 token that is backed 1:1 by ETH (similar to Wrapped ETH) with automatic pro-rata dividend distribution to token holders.

## Features

### Token Operations
- **Mint**: Deposit ETH to mint an equal amount of tokens (1 wei ETH = 1 token)
- **Burn**: Burn tokens to receive the equivalent amount of ETH back
- **Transfer**: Standard ERC-20 transfers with allowance/approval support

### Dividend System
- **Record Dividends**: Deposit ETH which is distributed proportionally to all current token holders
- **Withdraw Dividends**: Claim accumulated dividends even after transferring or burning tokens
- **Persistent Dividends**: Dividends earned while holding tokens remain claimable forever

### Holder Tracking
- Efficiently tracks current token holders using an array + mapping pattern
- Updates holder list on mint, burn, and transfer operations
- Uses swap-and-pop pattern for O(1) removal from holders array

## Technical Details

### Key Implementation Decisions
1. **Holder Tracking**: Array of addresses + mapping for O(1) membership checks
2. **Dividend Storage**: Separate mapping that persists after token transfers/burns
3. **Gas Optimization**: Loop through holders array for dividend distribution
4. **Security**: SafeMath for arithmetic operations

### Interfaces Implemented
- `IERC20` - Standard ERC-20 token interface
- `IMintableToken` - Minting and burning capabilities
- `IDividends` - Dividend distribution and withdrawal

## Testing

All 11 tests pass successfully:

```bash
$ npm run test

Contract: Token
  ✓ has default values
  ✓ can be minted
  ✓ can be burnt
  once minted
    ✓ can be transferred directly
    ✓ can be transferred indirectly
    can record dividends
      ✓ and disallows empty dividend
      ✓ and keeps track of holders when minting and burning
      ✓ and keeps track of holders when transferring
      ✓ and compounds the payouts
      ✓ and allows for withdrawals in-between payouts
      ✓ and allows for withdrawals even after holder relinquishes tokens

11 passing

## How to Run

### Prerequisites
- Node.js
- npm

### Installation
```bash
npm install

### Run Tests
```bash
npm run test

## License
MIT

## Author
Sahil
