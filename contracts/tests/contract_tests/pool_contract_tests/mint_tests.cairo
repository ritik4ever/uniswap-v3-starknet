use contracts::contract::interface::{
    IERC20TraitDispatcher, IERC20TraitDispatcherTrait, IUniswapV3ManagerDispatcher,
    IUniswapV3ManagerDispatcherTrait, UniswapV3PoolTraitDispatcher,
    UniswapV3PoolTraitDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;


#[test]
fn test_mint_position_within_price_range() {
    let (params, expected_amount0, expected_amount1) = TestParamsImpl::in_range_mint_test_values();
    let (pool_address, manager_address, _token0, _token1) = setup_test_environment(params);

    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    let liquidity_before = pool_dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Initial liquidity should be 0');

    // Mint position
    let (amount0, amount1) = manager_dispatcher
        .mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![]);

    println!("Amount0 returned: {}, expected: {}", amount0, expected_amount0);
    println!("Amount1 returned: {}, expected: {}", amount1, expected_amount1);
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    let lower_tick_init = pool_dispatcher.is_tick_init(params.lower_tick);
    let upper_tick_init = pool_dispatcher.is_tick_init(params.upper_tick);
    assert(lower_tick_init, 'Lower tick not initialized');
    assert(upper_tick_init, 'Upper tick not initialized');

    let liquidity_after = pool_dispatcher.get_liquidity();
    assert(liquidity_after == params.liq.into(), 'Incorrect liquidity amount');
}

#[test]
fn test_mint_position_below_price_range() {
    let (params, expected_amount0, expected_amount1) =
        TestParamsImpl::below_range_mint_test_values();
    let (pool_address, manager_address, _token0, _token1) = setup_test_environment(params);

    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    let liquidity_before = pool_dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Initial liquidity should be 0');

    let (amount0, amount1) = manager_dispatcher
        .mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![]);

    println!("Below range - Amount0: {}, Amount1: {}", amount0, amount1);
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');
    assert(amount1 == 0, 'Should require no token1');

    let lower_tick_init = pool_dispatcher.is_tick_init(params.lower_tick);
    let upper_tick_init = pool_dispatcher.is_tick_init(params.upper_tick);
    assert(lower_tick_init, 'Lower tick not initialized');
    assert(upper_tick_init, 'Upper tick not initialized');

    let liquidity_after = pool_dispatcher.get_liquidity();
    assert(liquidity_after == 0, 'Pool liquidity should be 0');
}

#[test]
fn test_mint_position_above_price_range() {
    let (params, expected_amount0, expected_amount1) =
        TestParamsImpl::above_range_mint_test_values();
    let (pool_address, manager_address, _token0, _token1) = setup_test_environment(params);

    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    let liquidity_before = pool_dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Initial liquidity should be 0');

    let (amount0, amount1) = manager_dispatcher
        .mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![]);

    println!("Above range - Amount0: {}, Amount1: {}", amount0, amount1);
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');
    assert(amount0 == 0, 'Should require no token0');

    let lower_tick_init = pool_dispatcher.is_tick_init(params.lower_tick);
    let upper_tick_init = pool_dispatcher.is_tick_init(params.upper_tick);
    assert(lower_tick_init, 'Lower tick not initialized');
    assert(upper_tick_init, 'Upper tick not initialized');

    let liquidity_after = pool_dispatcher.get_liquidity();
    assert(liquidity_after == 0, 'Pool liquidity should be 0');
}

#[test]
fn test_mint_position_narrow_price_range() {
    let (params, expected_amount0, expected_amount1) =
        TestParamsImpl::narrow_range_mint_test_values();
    let (pool_address, manager_address, _token0, _token1) = setup_test_environment(params);

    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    let liquidity_before = pool_dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Initial liquidity should be 0');

    let (amount0, amount1) = manager_dispatcher
        .mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![]);

    println!("Narrow range - Amount0: {}, Amount1: {}", amount0, amount1);
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    assert(amount0 > 0 && amount1 > 0, 'Both tokens required');

    let lower_tick_init = pool_dispatcher.is_tick_init(params.lower_tick);
    let upper_tick_init = pool_dispatcher.is_tick_init(params.upper_tick);
    assert(lower_tick_init, 'Lower tick not initialized');
    assert(upper_tick_init, 'Upper tick not initialized');

    let liquidity_after = pool_dispatcher.get_liquidity();
    assert(liquidity_after == params.liq.into(), 'Incorrect liquidity amount');
}

#[test]
fn test_mint_position_wide_price_range() {
    let (params, expected_amount0, expected_amount1) =
        TestParamsImpl::wide_range_mint_test_values();
    let (pool_address, manager_address, _token0, _token1) = setup_test_environment(params);

    let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };
    let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    let liquidity_before = pool_dispatcher.get_liquidity();
    assert(liquidity_before == 0, 'Initial liquidity should be 0');

    // Wide range around current price
    let (amount0, amount1) = manager_dispatcher
        .mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![]);

    println!("Wide range - Amount0: {}, Amount1: {}", amount0, expected_amount0);
    println!("Expected - Amount0: {}, Amount1: {}", expected_amount0, expected_amount1);
    assert(is_within_margin(amount0, expected_amount0, 1), 'Amount0 outside error margin');
    assert(is_within_margin(amount1, expected_amount1, 1), 'Amount1 outside error margin');

    assert(amount0 > 0 && amount1 > 0, 'Both tokens required');

    let lower_tick_init = pool_dispatcher.is_tick_init(params.lower_tick);
    let upper_tick_init = pool_dispatcher.is_tick_init(params.upper_tick);
    assert(lower_tick_init, 'Lower tick not initialized');
    assert(upper_tick_init, 'Upper tick not initialized');

    let liquidity_after = pool_dispatcher.get_liquidity();
    assert(liquidity_after == params.liq.into(), 'Incorrect liquidity amount');
}


//=================================================//
//                                                 //
//                  TEST SETUP                     //
//                                                 //
//=================================================//

/// Helper function to check if values are within an acceptable margin of error
fn is_within_margin(actual: u256, expected: u256, margin_percent: u8) -> bool {
    if expected == 0 {
        return actual == 0;
    }

    let margin = (expected * margin_percent.into()) / 100_u256;

    if actual > expected {
        actual - expected <= margin
    } else {
        expected - actual <= margin
    }
}


#[derive(Drop, Copy, Debug)]
struct TestParams {
    strk_balance: u128, // balance in strk (P = x/y)
    usdc_balance: u128, //balance in usdc 
    cur_tick: i32,
    lower_tick: i32,
    upper_tick: i32,
    liq: u128,
    cur_sqrtp: u256,
    mint_liquidity: bool,
}

#[generate_trait]
impl TestParamsImpl of TestParamsT {
    fn test1params() -> TestParams {
        TestParams {
            strk_balance: 1000000,
            usdc_balance: 225398,
            cur_tick: -15372,
            lower_tick: -15900,
            upper_tick: -14880,
            liq: 5670207847624059387904,
            cur_sqrtp: 36736587662821057944650860901,
            mint_liquidity: true,
        }
    }
    // Test case: in_range_mint
    // Price range: 2000.0 - 2500.0, current: 2250.0
    // Expected token amounts: 6134320414538772480 token0, 15382170198991540584448 token1

    fn in_range_mint_test_values() -> (TestParams, u256, u256) {
        let params = TestParams {
            strk_balance: 6747752455992650752, // 10% buffer
            usdc_balance: 16920387218890695901184, // 10% buffer
            cur_tick: 77190,
            lower_tick: 76012,
            upper_tick: 78244,
            liq: 5670207847624059387904,
            cur_sqrtp: 3758121725625718737136311599104,
            mint_liquidity: true,
        };

        // Expected mint return values
        let expected_amount0 = 6134320414538772480_u256;
        let expected_amount1 = 15382170198991540584448_u256;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: below_range_mint
    // Price range: 2000.0 - 2500.0, current: 1900.0
    // Expected token amounts: 13385544985920468992 token0, 0 token1

    fn below_range_mint_test_values() -> (TestParams, u256, u256) {
        let params = TestParams {
            strk_balance: 14724099484512516096, // 10% buffer
            usdc_balance: 0, // 10% buffer
            cur_tick: 75499,
            lower_tick: 76012,
            upper_tick: 78244,
            liq: 5670207847624059387904,
            cur_sqrtp: 3453475538820956351120541745152,
            mint_liquidity: true,
        };

        // Expected mint return values
        let expected_amount0 = 13385544985920468992_u256;
        let expected_amount1 = 0_u256;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: above_range_mint
    // Price range: 2000.0 - 2500.0, current: 2600.0
    // Expected token amounts: 0 token0, 29930988504399633973248 token1

    fn above_range_mint_test_values() -> (TestParams, u256, u256) {
        let params = TestParams {
            strk_balance: 0, // 10% buffer
            usdc_balance: 32924087354839600726016, // 10% buffer
            cur_tick: 78636,
            lower_tick: 76012,
            upper_tick: 78244,
            liq: 5670207847624059387904,
            cur_sqrtp: 4039859466863342524139596414976,
            mint_liquidity: true,
        };

        // Expected mint return values
        let expected_amount0 = 0_u256;
        let expected_amount1 = 29930988504399633973248_u256;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: narrow_range_mint
    // Price range: 2225.0 - 2275.0, current: 2250.0
    // Expected token amounts: 658619212501422720 token0, 1498404829171551830016 token1

    fn narrow_range_mint_test_values() -> (TestParams, u256, u256) {
        let params = TestParams {
            strk_balance: 724481133751565056, // 10% buffer
            usdc_balance: 1648245312088707170304, // 10% buffer
            cur_tick: 77190,
            lower_tick: 77078,
            upper_tick: 77301,
            liq: 5670207847624059387904,
            cur_sqrtp: 3758121725625718737136311599104,
            mint_liquidity: true,
        };

        // Expected mint return values
        let expected_amount0 = 658619212501422720_u256;
        let expected_amount1 = 1498404829171551830016_u256;

        (params, expected_amount0, expected_amount1)
    }

    // Test case: wide_range_mint
    // Price range: 1500.0 - 3000.0, current: 2250.0
    // Expected token amounts: 16015119237469530112 token0, 49355368441969035444224 token1

    fn wide_range_mint_test_values() -> (TestParams, u256, u256) {
        let params = TestParams {
            strk_balance: 17616631161216485376, // 10% buffer
            usdc_balance: 54290905286165940666368, // 10% buffer
            cur_tick: 77190,
            lower_tick: 73135,
            upper_tick: 80067,
            liq: 5670207847624059387904,
            cur_sqrtp: 3758121725625718737136311599104,
            mint_liquidity: true,
        };

        // Expected mint return values
        let expected_amount0 = 16015119237469530112_u256;
        let expected_amount1 = 49355368441969035444224_u256;

        (params, expected_amount0, expected_amount1)
    }
}

pub fn deploy_contract(name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

pub fn setup_test_environment(
    params: TestParams,
) -> (
    ContractAddress, // pool
    ContractAddress, // manager
    ContractAddress, // token0
    ContractAddress // token1
) {
    // Deploy tokens
    let test_address: ContractAddress = 0x1234.try_into().unwrap();

    // Deploy the two tokens
    let eth_calldata = array![
        test_address.into(), 'ETH'.into(), 18_u8.into(), params.strk_balance.into(), 'ETH'.into(),
    ];
    let eth_address = deploy_contract("ERC20", eth_calldata);

    let usdc_calldata = array![
        test_address.into(), 'USDC'.into(), 6_u8.into(), params.usdc_balance.into(), 'USDC'.into(),
    ];
    let usdc_address = deploy_contract("ERC20", usdc_calldata);

    let (token0, token1) = if eth_address < usdc_address {
        (eth_address, usdc_address)
    } else {
        (usdc_address, eth_address)
    };

    let pool_calldata: Array<felt252> = array![
        token0.into(),
        token1.into(),
        params.cur_sqrtp.try_into().unwrap(),
        0.into(),
        params.cur_tick.into(),
    ];
    let pool_address = deploy_contract("UniswapV3Pool", pool_calldata);

    let manager_calldata = array![pool_address.into(), token0.into(), token1.into()];
    let manager_address = deploy_contract("UniswapV3Manager", manager_calldata);

    let token0_dispatcher = IERC20TraitDispatcher { contract_address: token0 };
    let token1_dispatcher = IERC20TraitDispatcher { contract_address: token1 };

    token0_dispatcher.transfer(manager_address, params.strk_balance.into());
    token1_dispatcher.transfer(manager_address, params.usdc_balance.into());

    (pool_address, manager_address, token0, token1)
}

