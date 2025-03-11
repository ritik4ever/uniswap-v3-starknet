# WIP: AMM on Starknet based on Uniswap v3

## Project Overview
This project aims to implement Uniswap V3's concentrated liquidity AMM on Starknet using Cairo. While Uniswap V3 has been deployed on various EVM chains, implementing it on a ZK-rollup with a non-EVM virtual machine represents a cutting-edge technological challenge with significant implications for the DeFi ecosystem.

## Key Challenges

### Language Translation Complexity
- Many Solidity functions aren't directly supported in Cairo, requiring creative workarounds or complete rewrites
- Cairo's different programming paradigm requires rethinking implementation approaches rather than direct translation

### Mathematical Implementation
- Implementing Uniswap V3's concentrated liquidity math in Cairo requires deep understanding of both the formulas and Cairo's computational model
- Tick-based price ranges and bitmap implementations become even more complex in a non-EVM environment
- Fixed-point math libraries must be reimplemented from scratch in Cairo's unique numeric system

### Security Considerations
- Executing Uniswap V3 logic on a non-native VM introduces unique security risks not present in EVM implementations
- ZK-specific optimizations may introduce subtle differences in behavior compared to the original implementation
- Additional auditing and testing infrastructure must be developed specifically for this Cairo implementation

## Development Roadmap
1. **Core Pool Implementation** (Implemented with hardcoded values for now)
   - Basic swap functionality
   - Single-tick liquidity provision
   - Callback pattern implementation

2. **Tick Bitmap & Cross-Tick Swaps** (Upcoming)
   - Efficient tick tracking system
   - Cross-tick swap routing
   - Fee management

3. **Advanced Features** (Planned)
   - Multi-pool swap routing
   - Oracle functionality
   - Position NFTs

## Potential for a Development Book

This project could be adapted into a comprehensive development guide for implementing complex DeFi protocols on Starknet, similar to Jeiwan's Uniswap V3 Development Book. Such a book would:

- Guide developers through building a fully-functional Uniswap V3 clone on Starknet from scratch
- Follow a milestone-based approach, breaking down complex components into manageable learning modules
- Explore the mathematical foundations of concentrated liquidity AMMs while demonstrating their implementation in Cairo
- Serve as a bridge between EVM-based and Cairo-based development knowledge
- Highlight the unique challenges and advantages of ZK-rollup implementations

## Contributing
This project is open for contributions and feedback.
[DM](https://augvst1n.t.me/)
