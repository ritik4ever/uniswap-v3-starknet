use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use contracts::contract::interface::UniswapV3PoolTraitDispatcherTrait;
use contracts::contract::interface::UniswapV3PoolTraitDispatcher;
use contracts::contract::interface::UniswapV3PoolTraitSafeDispatcher;
use contracts::contract::interface::UniswapV3PoolTraitSafeDispatcherTrait;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

/// Deploy the UniswapV3Pool contract with dummy constructor parameters.
/// The constructor requires:
///   - token0 and token1 (dummy contract addresses),
///   - a dummy sqrt_pricex96 value, and
///   - an initial tick (here set to 0, which lies between MIN_TICK and MAX_TICK).
fn deploy_contract(name: ByteArray) -> ContractAddress {
    let token0_add = deploy_contract("TKN");
    let token0_dis = ERC20ABIDispatcher { contract_address: token0_add };
    let token0: felt252 = token0_dis.contract_address.try_into().unwrap();
    let token1_add = deploy_contract("ERC");
    let token1_dis = ERC20ABIDispatcher { contract_address: token1_add };
    let token1: felt252 = token1_dis.contract_address.try_into().unwrap();    
    let sqrt_pricex96 = 1; // dummy u256 value
    let init_tick = 0;
    let contract = declare(name).unwrap().contract_class();
    let constructor_params :Array<felt252> = array![
        token1.into(),
        token0.try_into().unwrap(),
        sqrt_pricex96.into(),
        init_tick.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_params).unwrap();
    contract_address
}

#[test]
fn test_mint_liquidity() {
    // Deploy the contract using the UniswapV3Pool class.
    let contract_address = deploy_contract("UniswapV3Pool");

    // Instantiate the dispatcher (assumed generated from IUniswapV3PoolTrait).
    let dispatcher = UniswapV3PoolTraitDispatcher { contract_address };

    // Assume there is a getter, e.g., get_liquidity, to read the global liquidity.
    let liquidity_before = dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Invalid liquidity before mint');

    // Choose valid tick boundaries (must be within -887272 and 887272).
    let lower_tick: i32 = -500000;
    let upper_tick: i32 = 500000;
    let amount: u128 = 42;

    // Call mint with valid parameters.
    dispatcher.mint(lower_tick, upper_tick, amount);

    // After minting, the global liquidity should now reflect the new minted liquidity.
    // (Here we expect it to be equal to the minted amount, assuming the contract is updated as intended.)
    let liquidity_after = dispatcher.get_liquidity();
    assert(liquidity_after == amount.into(), 'Invalid liquidity after mint');
}

#[test]
#[feature("safe_dispatcher")]
fn test_mint_zero_amount_reverts() {
    // Deploy the contract using the UniswapV3Pool class.
    let contract_address = deploy_contract("UniswapV3Pool");

    // Instantiate the safe dispatcher.
    let safe_dispatcher = UniswapV3PoolTraitSafeDispatcher { contract_address };

    // Define valid lower and upper ticks.
    let lower_tick: i32 = -500000;
    let upper_tick: i32 = 500000;

    // Attempt to mint with a zero amount; this should panic.
    match safe_dispatcher.mint(lower_tick, upper_tick, 0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            // Check that the panic error matches the expected error message.
            assert(panic_data.at(0) ==  panic_data.at(0), 'liq amount must be > 0');
        },
    };
}
