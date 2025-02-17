use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait};

use contracts::contract::interface::UniswapV3PoolTraitDispatcher;
use contracts::contract::interface::UniswapV3PoolTraitDispatcherTrait;

fn deploy_contract(name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_mint_liquidity() {
    let token0 = contract_address_const::<
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    >(); // STRK token address.
    let token1 = contract_address_const::<
        0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8
    >(); // USDC token address.

    let sqrt_pricex96_low = 1000;
    let sqrt_pricex96_high = 0;
    let init_tick = 10000; // within the allowed range (-887272, 887272)

    let calldata: Array<felt252> = array![
         token0.into(),
         token1.into(),
         sqrt_pricex96_low.into(),
         sqrt_pricex96_high.into(),
         init_tick.into()
    ];

    let pool_contract_address = deploy_contract("UniswapV3Pool", calldata);
    let mut dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_contract_address };

    let liquidity_before = dispatcher.get_liquidity();
    println!("liquidity before: {:?}", liquidity_before);
    assert(liquidity_before == 0, 'Invalid liquidity before mint1');

    let lower_tick: i32 = -500000;
    let upper_tick: i32 = 500000;
    let amount: u128 = 42;

    dispatcher.mint(lower_tick, upper_tick, amount);

    let liquidity_after = dispatcher.get_liquidity();
    println!("liquidity after: {:?}", liquidity_after);
    assert(liquidity_after == amount.into(), 'Invalid liquidity after mint');
}
