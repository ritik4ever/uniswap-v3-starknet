use contracts::contract::interface::{
    IERC20TraitDispatcher, IERC20TraitDispatcherTrait, IUniswapV3ManagerDispatcher,
    IUniswapV3ManagerDispatcherTrait, IUniswapV3QuoterDispatcher, IUniswapV3QuoterDispatcherTrait,
    UniswapV3PoolTraitDispatcher, UniswapV3PoolTraitDispatcherTrait,
};
use contracts::contract::univ3quoter::QuoteParams;
use contracts::libraries::math::numbers::fixed_point::FixedQ64x96;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;


#[test]
fn test_quoter_against_swap() {
    let (params, _expected_amount0, _expected_amount1) =
        SwapTestsParamsImpl::minimal_swap_0_to_1_swap_test_values();

    // FIRST SETUP: Create a pool for actual swap
    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    initialize_position(manager_dispatcher, params);

    let liquidity_after_mint = pool_dispatcher.get_liquidity();
    assert(liquidity_after_mint > 0, 'Liquidity should be added');

    // Execute the actual swap
    let recipient: ContractAddress = 0x5678.try_into().unwrap();
    let (actual_amount0, actual_amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!("Actual swap results: amount0={}, amount1={}", actual_amount0, actual_amount1);

    // SECOND SETUP: Create a NEW pool with identical starting state for quoter test
    let (
        second_pool_address,
        _second_manager_address,
        _second_token0,
        _second_token1,
        second_pool_dispatcher,
        second_manager_dispatcher,
    ) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position in the second pool
    initialize_position(second_manager_dispatcher, params);

    // Verify second pool has the same starting state
    let second_liquidity = second_pool_dispatcher.get_liquidity();
    assert(second_liquidity == liquidity_after_mint, 'Initial liquidity mismatch');

    let slot0_before = second_pool_dispatcher.slot0();
    println!(
        "Second pool initial price: {}, tick: {}", slot0_before.sqrt_pricex96, slot0_before.tick,
    );

    // Deploy the quoter contract
    let quoter_calldata: Array<felt252> = array![];
    let quoter_address = deploy_contract("UniswapV3Quoter", quoter_calldata);
    let quoter_dispatcher = IUniswapV3QuoterDispatcher { contract_address: quoter_address };

    // Create quote params using the second pool
    let quote_params = QuoteParams {
        amount_specified: params.amount_specified,
        zero_for_one: params.zero_for_one,
        pool: second_pool_address, // Use the second pool
        sqrt_price_limit: unscale_sqrt_price(
            params.sqrt_price_limit,
        ) // use the unscaled sqrt price limit
    };

    let (quoted_amount0, quoted_amount1, sqrt_price_after, tick_after) = quoter_dispatcher
        .quote(quote_params);

    assert(is_within_margin(quoted_amount0, actual_amount0, 1), 'Quoted amount0 differs');
    assert(is_within_margin(quoted_amount1, actual_amount1, 1), 'Quoted amount1 differs');

    // Get the state of the first pool after the swap for comparison
    let slot0_after_swap = pool_dispatcher.slot0();

    // The quoted final price and tick should match the actual swap's final state
    assert(sqrt_price_after == slot0_after_swap.sqrt_pricex96, 'Quoted price differs');
    assert(tick_after == slot0_after_swap.tick, 'Quoted tick differs');

    // Verify the second pool's state hasn't changed (quoter is view-only)
    let slot0_after_quote = second_pool_dispatcher.slot0();
    assert(
        slot0_after_quote.sqrt_pricex96 == slot0_before.sqrt_pricex96, 'Quoter modified pool state',
    );
    assert(slot0_after_quote.tick == slot0_before.tick, 'Quoter modified pool tick');
}


//=================================================//
//                                                 //
//                  TEST SETUP                     //
//                                                 //
//=================================================//

#[derive(Copy, Drop, Serde)]
struct SwapTestParams {
    // Initial setup - price and liquidity
    cur_tick: i32,
    cur_sqrt_price: u256,
    lower_tick: i32,
    upper_tick: i32,
    liquidity: u128,
    // Swap parameters
    zero_for_one: bool,
    amount_specified: i128,
    sqrt_price_limit: u256,
    // For setting up the test
    mint_amount0: u256,
    mint_amount1: u256,
}

#[generate_trait]
impl SwapTestsParamsImpl of SwapTestsParamsTrait {
    // Test case: minimal_swap_0_to_1
    // Description: Tiny swap token0→token1 - no tick crossings
    // Direction: token0_to_token1
    // Current tick: 76012
    // Current price: 2000.0
    // Swap amount specified: 1000000000000000
    // Expected token deltas: 1000000000000000 token0, -1996801996801996 token1

    fn minimal_swap_0_to_1_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 76012,
            cur_sqrt_price: 3543191142285914378072636784640_u256,
            lower_tick: 75499,
            upper_tick: 76500,
            liquidity: 1000000000000000000,
            // Swap parameters
            zero_for_one: true,
            amount_specified: 1000000000000000,
            sqrt_price_limit: 3453475538820956351120541745152_u256,
            // For setting up the test
            mint_amount0: 592779826538521_u256,
            mint_amount1: 1245607126047964160_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = 1000000000000000;
        let expected_amount1: i128 = -1996801996801996;

        (params, expected_amount0, expected_amount1)
    }
}

pub fn deploy_contract(name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name.clone()).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

fn abs_i128(value: i128) -> u128 {
    if value < 0 {
        (-value).try_into().expect('abs_128<')
    } else {
        value.try_into().expect('abs_128else')
    }
}

pub fn setup_swap_test_environment(
    params: SwapTestParams,
) -> (
    ContractAddress, // pool
    ContractAddress, // manager
    ContractAddress, // token0
    ContractAddress, // token1
    UniswapV3PoolTraitDispatcher, // pool_dispatcher
    IUniswapV3ManagerDispatcher // manager_dispatcher
) {
    // Deploy tokens
    let test_address: ContractAddress = 0x1234.try_into().unwrap();

    // Deploy the auxiliary contracts first
    let tick_calldata: Array<felt252> = array![];
    let tick_address = deploy_contract("Tick", tick_calldata);

    let bitmap_calldata: Array<felt252> = array![];
    let bitmap_address = deploy_contract("TickBitmap", bitmap_calldata);

    let position_calldata: Array<felt252> = array![];
    let position_address = deploy_contract("Position", position_calldata);

    // Deploy the two tokens with sufficient balances for the test
    let eth_calldata = array![
        test_address.into(),
        'ETH'.into(),
        18_u8.into(),
        params.mint_amount0.low.into(),
        'ETH'.into(),
    ];
    let eth_address = deploy_contract("ERC20", eth_calldata);

    let usdc_calldata = array![
        test_address.into(),
        'USDC'.into(),
        6_u8.into(),
        params.mint_amount1.low.into(),
        'USDC'.into(),
    ];
    let usdc_address = deploy_contract("ERC20", usdc_calldata);

    let (token0, token1) = if eth_address < usdc_address {
        (eth_address, usdc_address)
    } else {
        (usdc_address, eth_address)
    };
    // Deploy pool with the provided parameters
    let pool_calldata: Array<felt252> = array![
        token0.into(),
        token1.into(),
        params.cur_sqrt_price.low.try_into().unwrap(),
        params.cur_sqrt_price.high.try_into().unwrap(),
        params.cur_tick.into(),
        // Include addresses of auxiliary contracts if your pool constructor accepts them
        tick_address.into(),
        bitmap_address.into(),
        position_address.into(),
    ];
    let pool_address = deploy_contract("UniswapV3Pool", pool_calldata);

    // Deploy manager
    let manager_calldata = array![pool_address.into(), token0.into(), token1.into()];
    let manager_address = deploy_contract("UniswapV3Manager", manager_calldata);

    // Transfer tokens to manager for minting and swapping
    let token0_dispatcher = IERC20TraitDispatcher { contract_address: token0 };
    let token1_dispatcher = IERC20TraitDispatcher { contract_address: token1 };

    token0_dispatcher.transfer(manager_address, params.mint_amount0.try_into().expect('mint_amt0'));
    token1_dispatcher.transfer(manager_address, params.mint_amount1.try_into().expect('mint_amt1'));

    // Create dispatchers for the contracts
    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    (pool_address, manager_address, token0, token1, pool_dispatcher, manager_dispatcher)
}


// Helper function to initialize a position before testing a swap
fn initialize_position(manager_dispatcher: IUniswapV3ManagerDispatcher, params: SwapTestParams) {
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);
}

fn is_within_margin(actual: i128, expected: i128, margin_percent: u8) -> bool {
    if expected == 0 {
        return actual == 0;
    }

    let expected_abs = if expected < 0 {
        -expected
    } else {
        expected
    };
    let margin = (expected_abs * margin_percent.into()) / 100_i128;

    if actual > expected {
        actual - expected <= margin
    } else {
        expected - actual <= margin
    }
}

fn unscale_sqrt_price(sqrt_price_x96: u256) -> u256 {
    // Q96 = 2^96
    let q96: u256 = 79228162514264337593543950336_u256;

    // Divide by 2^96 to get the unscaled sqrt price
    sqrt_price_x96 / q96
}
