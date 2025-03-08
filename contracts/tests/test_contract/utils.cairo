use starknet::ContractAddress;

/// Get STRK & USDC contract addresses
pub fn get_token0_n_1() -> (ContractAddress, ContractAddress) {
    let token0 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d.try_into().unwrap(); // STRK token address.
    let token1 = 0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8.try_into().unwrap(); // USDC token address.
    (token0, token1)
}