# ChainBridge NFT Hub

A comprehensive cross-chain NFT marketplace built on the Stacks blockchain using Clarity smart contracts. This platform enables minting, trading, and bridging NFTs across multiple blockchain networks with built-in royalty distribution and referral systems.

## Features

### Core NFT Functionality
- **NFT Minting**: Create individual or batch mint NFTs with custom metadata
- **Marketplace Trading**: List, buy, and sell NFTs with automated fee distribution
- **Cross-Chain Bridging**: Bridge NFTs from Ethereum, Solana, Polygon, and Binance Smart Chain
- **Royalty System**: Automatic royalty payments to original creators (up to 25%)
- **Referral Program**: Earn rewards by referring new users to the platform

### Advanced Features
- **Batch Operations**: Mint and list multiple NFTs in a single transaction
- **User Restrictions**: Platform owner can restrict problematic users
- **Metadata Management**: Update NFT metadata post-minting
- **Analytics Tracking**: Monitor platform volume, fees, and royalty payments
- **Transaction History**: Complete audit trail for all NFT transfers

## Technical Specifications

### Platform Economics
- **Platform Fee**: 5% of sale price
- **Referral Bonus**: 1% of sale price
- **Maximum Royalty**: 25% of sale price
- **Supported Token Range**: 1 to 9,999,999

### Supported Blockchains
- Ethereum (`ethereum`)
- Solana (`solana`)
- Polygon (`polygon`)
- Binance Smart Chain (`binance`)

## Smart Contract Functions

### Public Functions

#### NFT Creation
```clarity
;; Mint a single NFT
(create-new-nft token-id royalty-rate metadata-info)

;; Batch mint multiple NFTs
(create-multiple-nfts token-id-list royalty-rate-list metadata-info-list)
```

#### Marketplace Operations
```clarity
;; List NFT for sale
(list-token-for-sale token-id asking-price)

;; Batch list multiple NFTs
(list-multiple-tokens-for-sale token-id-list price-list)

;; Remove listing
(remove-token-listing token-id)

;; Purchase NFT with optional referrer
(purchase-listed-nft token-id referrer-address)
```

#### Cross-Chain Bridging
```clarity
;; Bridge external NFT to Stacks
(bridge-external-nft blockchain-name external-token-id internal-token-id metadata-info)
```

#### Metadata Management
```clarity
;; Update NFT metadata (owner only)
(update-token-metadata token-id updated-metadata)
```

#### User Management
```clarity
;; Restrict user (platform owner only)
(add-user-to-restriction-list target-address)

;; Remove user restriction (platform owner only)
(remove-user-from-restriction-list target-address)
```

### Read-Only Functions

#### Token Information
```clarity
;; Get token metadata
(get-token-metadata token-id)

;; Get complete token information
(get-complete-token-info token-id)

;; Get transaction history
(get-token-transaction-history token-id)
```

#### Platform Analytics
```clarity
;; Get platform statistics
(get-platform-analytics)

;; Get user referral data
(get-user-referral-data user-address)
```

## Data Structures

### Metadata Format
```clarity
{
  display-name: (string-ascii 100),
  description-text: (string-ascii 500),
  image-uri: (string-ascii 200),
  trait-attributes: (list 20 {
    property: (string-ascii 50),
    property-value: (string-ascii 50)
  })
}
```

### Token Attributes
Each NFT can have up to 20 trait attributes, making it suitable for complex collectibles with multiple properties.

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u1 | ERR_UNAUTHORIZED_ACCESS | User lacks required permissions |
| u2 | ERR_INSUFFICIENT_FUNDS | Insufficient STX balance |
| u3 | ERR_INVALID_ROYALTY_RATE | Royalty rate exceeds 25% |
| u4 | ERR_TOKEN_NOT_EXISTS | Token ID doesn't exist |
| u5 | ERR_INVALID_TOKEN_ID | Token ID out of valid range |
| u6 | ERR_INVALID_PRICE_VALUE | Invalid price (must be > 0) |
| u7 | ERR_ITEM_ALREADY_LISTED | NFT already listed for sale |
| u8 | ERR_UNSUPPORTED_BLOCKCHAIN | Blockchain not supported |
| u9 | ERR_INVALID_METADATA_FORMAT | Metadata format invalid |
| u10 | ERR_ITEM_NOT_LISTED | NFT not currently listed |
| u11 | ERR_INVALID_EXTERNAL_TOKEN_ID | External token ID invalid |
| u12 | ERR_USER_RESTRICTED | User is restricted from trading |
| u13 | ERR_INVALID_REFERRER | Invalid referrer address |
| u14 | ERR_CANNOT_RESTRICT_OWNER | Cannot restrict platform owner |
| u15 | ERR_USER_NOT_RESTRICTED | User is not restricted |
| u16 | ERR_INVALID_USER_ADDRESS | Invalid user address |

## Usage Examples

### Minting an NFT
```clarity
(contract-call? .chainbridge-nft create-new-nft
  u12345
  u10  ;; 10% royalty
  {
    display-name: "Awesome NFT",
    description-text: "A unique digital collectible",
    image-uri: "https://example.com/nft.png",
    trait-attributes: (list 
      {property: "rarity", property-value: "legendary"}
      {property: "color", property-value: "gold"}
    )
  }
)
```

### Listing for Sale
```clarity
(contract-call? .chainbridge-nft list-token-for-sale
  u12345
  u1000000  ;; 1 STX
)
```

### Purchasing with Referral
```clarity
(contract-call? .chainbridge-nft purchase-listed-nft
  u12345
  (some 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)  ;; referrer
)
```

## Security Features

- **Ownership Verification**: All operations verify token ownership
- **User Restrictions**: Platform can restrict malicious users
- **Input Validation**: Comprehensive validation of all inputs
- **Protected Functions**: Critical functions restricted to platform owner
- **Safe Math**: Prevents overflow/underflow in calculations

## Deployment Requirements

### Prerequisites
- Stacks blockchain node access
- Clarity development environment
- Sufficient STX for contract deployment

### Constants Configuration
Update these constants before deployment:
- `PLATFORM_OWNER`: Set to your principal address
- `PLATFORM_FEE_PERCENTAGE`: Adjust platform fee (default 5%)
- `REFERRAL_BONUS_PERCENTAGE`: Adjust referral bonus (default 1%)

## Integration Guide

### Frontend Integration
This contract is designed to work with web3 frontends using the Stacks.js library. Key integration points:

1. **Wallet Connection**: Use Stacks wallet providers
2. **Transaction Signing**: Handle Clarity transaction signing
3. **Event Monitoring**: Monitor contract events for updates
4. **Error Handling**: Implement proper error handling for all error codes

### API Endpoints
The contract provides comprehensive read-only functions for building analytics dashboards and marketplace interfaces.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test thoroughly with Clarinet
4. Submit a pull request

