use contracts::contract::interface::{
    IERC20TraitDispatcher, IERC20TraitDispatcherTrait, IUniswapV3ManagerDispatcher,
    IUniswapV3ManagerDispatcherTrait, UniswapV3PoolTraitDispatcher,
    UniswapV3PoolTraitDispatcherTrait,
};
use contracts::libraries::math::numbers::fixed_point::FixedQ64x96;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

/// TODO: Fix the pool swap function to make the tests pass
#[test]
#[ignore]
fn test_swap_exact_input_0_to_1() {
    // Standard token0 -> token1 swap
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::swap_exact_input_0_to_1_swap_test_values();

    // Set up test environment
    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position with liquidity
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);

    // Verify initial liquidity
    let liquidity_after_mint = pool_dispatcher.get_liquidity();
    assert(liquidity_after_mint > 0, 'Liquidity should be added');

    // Set recipient address
    let recipient: ContractAddress = 0x5678.try_into().unwrap();

    // Execute the swap (token0 for token1)
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    // Print results for debugging
    println!(
        "Swap 0 to 1 amounts: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    // Verify with 1% margin of error
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify swap direction (token0 in, token1 out)
    assert(amount0 > 0, 'Token0 should be positive (in)');
    assert(amount1 < 0, 'Token1 should be negative (out)');
}

#[test]
#[ignore]
fn test_swap_exact_input_1_to_0() {
    // Standard token1 -> token0 swap
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::swap_exact_input_1_to_0_swap_test_values();

    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    println!("Environment set up!");
    // Initialize position
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);
    println!("Liquidity provided.");
    let recipient: ContractAddress = 0x5678.try_into().unwrap();
    println!("Initiate swap...");
    // Execute the swap (token1 for token0)
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!(
        "Swap 1 to 0 amounts: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify swap direction (token1 in, token0 out)
    assert(amount0 < 0, 'Token0 should be negative (out)');
    assert(amount1 > 0, 'Token1 should be positive (in)');
}

#[test]
#[ignore]
fn test_small_swap_0_to_1() {
    // Small swap with minimal price impact
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::small_swap_0_to_1_swap_test_values();

    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);

    // Record initial state
    let initial_slot0 = pool_dispatcher.slot0();
    let initial_sqrt_price = initial_slot0.sqrt_pricex96;

    let recipient: ContractAddress = 0x5678.try_into().unwrap();

    // Execute a small swap
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!(
        "Small swap amounts: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify that price impact was small
    let final_slot0 = pool_dispatcher.slot0();
    let price_change = if final_slot0.sqrt_pricex96 > initial_sqrt_price {
        final_slot0.sqrt_pricex96 - initial_sqrt_price
    } else {
        initial_sqrt_price - final_slot0.sqrt_pricex96
    };

    // Price change should be small for small swaps
    let max_expected_change = initial_sqrt_price / 100; // 1% max change
    assert(price_change <= max_expected_change, 'Price impact too large');
}

#[test]
#[ignore]
fn test_large_swap_0_to_1() {
    // Large swap with significant price impact
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::large_swap_0_to_1_swap_test_values();

    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);

    // Record initial state
    let initial_slot0 = pool_dispatcher.slot0();

    let recipient: ContractAddress = 0x5678.try_into().unwrap();

    // Execute a large swap
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!(
        "Large swap amounts: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify significant price impact
    let final_slot0 = pool_dispatcher.slot0();
    assert(final_slot0.tick != initial_slot0.tick, 'Tick didnt change');

    // For zero_for_one=true, price should decrease
    assert(final_slot0.sqrt_pricex96 < initial_slot0.sqrt_pricex96, 'Price should decrease');
}

#[test]
#[ignore]
fn test_swap_near_price_bounds() {
    // Test swapping near the lower price bound
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::swap_near_lower_bound_swap_test_values();

    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);

    let recipient: ContractAddress = 0x5678.try_into().unwrap();

    // Execute swap near lower bound
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!(
        "Near lower bound swap: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify we're getting close to the lower bound
    let final_slot0 = pool_dispatcher.slot0();
    let tick_distance_to_lower = final_slot0.tick - params.lower_tick;
    assert(
        tick_distance_to_lower >= 0 && tick_distance_to_lower < 100, 'Should not cross lowr tick',
    );
}

#[test]
#[ignore]
fn test_swap_near_upper_bound() {
    // Test swapping near the upper price bound
    let (params, expected_amount0, expected_amount1) =
        SwapTestsParamsImpl::swap_near_upper_bound_swap_test_values();

    let (_pool_address, manager_address, _token0, _token1, pool_dispatcher, manager_dispatcher) =
        setup_swap_test_environment(
        params,
    );

    // Initialize position
    manager_dispatcher.mint(params.lower_tick, params.upper_tick, params.liquidity, array![]);

    let recipient: ContractAddress = 0x5678.try_into().unwrap();

    // Execute swap near upper bound
    let (amount0, amount1) = pool_dispatcher
        .swap(
            recipient,
            manager_address,
            params.zero_for_one,
            params.amount_specified,
            FixedQ64x96 { value: params.sqrt_price_limit },
            array![],
        );

    println!(
        "Near upper bound swap: actual ({}, {}), expected ({}, {})",
        amount0,
        amount1,
        expected_amount0,
        expected_amount1,
    );

    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    // Verify we're getting close to the upper bound
    let final_slot0 = pool_dispatcher.slot0();
    let tick_distance_to_upper = params.upper_tick - final_slot0.tick;
    assert(
        tick_distance_to_upper >= 0 && tick_distance_to_upper < 100, 'should not cross upper tick',
    );
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
    // Test case: swap_exact_input_0_to_1
    // Direction: token0_to_token1
    // Price range: 2000.0 - 2500.0
    // Current price: 2250.0, Expected after swap: 2240.0
    // Swap amount specified: 100000000000000000
    // Expected token deltas: 100000000000000000 token0, -598357969382984908800 token1

    fn swap_exact_input_0_to_1_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 77190,
            cur_sqrt_price: 3758121725625718737136311599104_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: true,
            amount_specified: 100000000000000000,
            sqrt_price_limit: 3557335674144281403252895907840_u256,
            // For setting up the test
            mint_amount0: 6747752455992650752_u256,
            mint_amount1: 16920387218890695901184_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = 100000000000000000;
        let expected_amount1: i128 = -598357969382984908800;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: swap_exact_input_1_to_0
    // Direction: token1_to_token0
    // Price range: 2000.0 - 2500.0
    // Current price: 2250.0, Expected after swap: 2260.0
    // Swap amount specified: 200000000
    // Expected token deltas: -264758857429282688 token0, 200000000 token1

    fn swap_exact_input_1_to_0_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 77190,
            cur_sqrt_price: 3758121725625718737136311599104_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: false,
            amount_specified: 200000000,
            sqrt_price_limit: 3950300610608170909846701342720_u256,
            // For setting up the test
            mint_amount0: 6747752455992650752_u256,
            mint_amount1: 16920387218890695901184_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = -264758857429282688;
        let expected_amount1: i128 = 200000000;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: small_swap_0_to_1
    // Direction: token0_to_token1
    // Price range: 2000.0 - 2500.0
    // Current price: 2250.0, Expected after swap: 2249.0
    // Swap amount specified: 10000000000000000
    // Expected token deltas: 10000000000000000 token0, -59775881186217672704 token1

    fn small_swap_0_to_1_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 77190,
            cur_sqrt_price: 3758121725625718737136311599104_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: true,
            amount_specified: 10000000000000000,
            sqrt_price_limit: 3564474943465892917670334955520_u256,
            // For setting up the test
            mint_amount0: 6747752455992650752_u256,
            mint_amount1: 16920387218890695901184_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = 10000000000000000;
        let expected_amount1: i128 = -59775881186217672704;
        (params, expected_amount0, expected_amount1)
    }

    // Test case: large_swap_0_to_1
    // Direction: token0_to_token1
    // Price range: 2000.0 - 2500.0
    // Current price: 2250.0, Expected after swap: 2150.0
    // Swap amount specified: 1000000000000000000
    // Expected token deltas: 1000000000000000000 token0, -6044852230638060699648 token1

    fn large_swap_0_to_1_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 77190,
            cur_sqrt_price: 3758121725625718737136311599104_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: true,
            amount_specified: 1000000000000000000,
            sqrt_price_limit: 3485138714308689983956156678144_u256,
            // For setting up the test
            mint_amount0: 6747752455992650752_u256,
            mint_amount1: 16920387218890695901184_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = 1000000000000000000;
        let expected_amount1: i128 = -6044852230638060699648;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: swap_near_lower_bound
    // Direction: token0_to_token1
    // Price range: 2000.0 - 2500.0
    // Current price: 2010.0, Expected after swap: 2002.0
    // Swap amount specified: 50000000000000000
    // Expected token deltas: 50000000000000000 token0, -506400028622942568448 token1

    fn swap_near_lower_bound_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 76062,
            cur_sqrt_price: 3552038075264288218737897635840_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: true,
            amount_specified: 50000000000000000,
            sqrt_price_limit: 3363046521655583902066569904128_u256,
            // For setting up the test
            mint_amount0: 14376729898716356608_u256,
            mint_amount1: 696473853872133636096_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = 50000000000000000;
        let expected_amount1: i128 = -506400028622942568448;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: swap_near_upper_bound
    // Direction: token1_to_token0
    // Price range: 2000.0 - 2500.0
    // Current price: 2490.0, Expected after swap: 2498.0
    // Swap amount specified: 150000000
    // Expected token deltas: -182102116960741472 token0, 150000000 token1

    fn swap_near_upper_bound_swap_test_values() -> (SwapTestParams, i128, i128) {
        let params = SwapTestParams {
            // Initial setup - price and liquidity
            cur_tick: 78204,
            cur_sqrt_price: 3953477370760181392394227286016_u256,
            lower_tick: 76012,
            upper_tick: 78244,
            liquidity: 5670207847624059387904,
            // Swap parameters
            zero_for_one: false,
            amount_specified: 150000000,
            sqrt_price_limit: 4153097656989963452347448295424_u256,
            // For setting up the test
            mint_amount0: 250240116386462688_u256,
            mint_amount1: 32299739518164629716992_u256,
        };

        // Expected swap results
        let expected_amount0: i128 = -182102116960741472;
        let expected_amount1: i128 = 150000000;

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
