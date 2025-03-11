mod utils;
use contracts::contract::interface::{
    IERC20TraitDispatcher, IERC20TraitDispatcherTrait, IUniswapV3ManagerDispatcher,
    IUniswapV3ManagerDispatcherTrait, UniswapV3PoolTraitDispatcher,
    UniswapV3PoolTraitDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;
//use utils::get_token0_n_1;

#[derive(Drop)]
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

trait TestParamsT<T> {
    fn test1params() -> TestParams;
}

impl TestParamsImpl of TestParamsT<TestParams> {
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
}

fn deploy_contract(name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_mint_liquidity_using_params() {
    let params = TestParamsImpl::test1params();
    let test_address: ContractAddress = 0x1234.try_into().unwrap();

    let eth_calldata = array![
        test_address.into(), 'ETH'.into(), 18_u8.into(), 1000000.into(), 'ETH'.into(),
    ];
    let token0 = deploy_contract("ERC20", eth_calldata);
    let mut token0_dispatcher = IERC20TraitDispatcher { contract_address: token0 };

    let usdc_calldata = array![
        test_address.into(), 'USDC'.into(), 6_u8.into(), 1000000.into(), 'USDC'.into(),
    ];
    let token1 = deploy_contract("ERC20", usdc_calldata);
    let mut token1_dispatcher = IERC20TraitDispatcher { contract_address: token1 };

    let pool_calldata: Array<felt252> = array![
        token0.into(),
        token1.into(),
        params.cur_sqrtp.try_into().unwrap(),
        0.into(),
        params.cur_tick.into(),
    ];
    let pool_address = deploy_contract("UniswapV3Pool", pool_calldata);
    let mut pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_address };

    let manager_calldata = array![
        pool_address.into(), // pool address
        token0.into(), // token0 address
        token1.into() // token1 address
    ];
    let manager_address = deploy_contract("UniswapV3Manager", manager_calldata);
    let mut manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    token0_dispatcher.transfer(manager_address, 1000000);
    token1_dispatcher.transfer(manager_address, 1000000);

    let liquidity_before = pool_dispatcher.get_liquidity();
    println!("liquidity before: {:?}", liquidity_before);
    assert(liquidity_before == 0, 'Invalid liquidity before mint');

    manager_dispatcher
        .mint(
            params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![].into(),
        );

    let tick_inited = pool_dispatcher.is_tick_init(params.lower_tick);
    assert!(tick_inited == true);

    let liquidity_after = pool_dispatcher.get_liquidity();
    println!("liquidity after: {:?}", liquidity_after);
    assert(liquidity_after == params.liq.into(), 'Invalid liquidity after mint');
}

#[test]
fn test_swap() {
    let test_address: ContractAddress = 0x1234.try_into().unwrap();
    let recipient: ContractAddress = 0x222.try_into().unwrap();

    let eth_calldata = array![
        test_address.into(), 'ETH'.into(), 18_u8.into(), 1000000.into(), 'ETH'.into(),
    ];
    let eth_address = deploy_contract("ERC20", eth_calldata);
    let mut eth_token = IERC20TraitDispatcher { contract_address: eth_address };

    let usdc_calldata = array![
        test_address.into(), 'USDC'.into(), 6_u8.into(), 1000000.into(), 'USDC'.into(),
    ];
    let usdc_address = deploy_contract("ERC20", usdc_calldata);
    let mut usdc_token = IERC20TraitDispatcher { contract_address: usdc_address };

    let params = TestParamsImpl::test1params();

    let pool_calldata = array![
        eth_address.into(),
        usdc_address.into(),
        params.cur_sqrtp.try_into().unwrap(),
        0.into(),
        params.cur_tick.into(),
    ];
    let pool_address = deploy_contract("UniswapV3Pool", pool_calldata);
    let mut pool = UniswapV3PoolTraitDispatcher { contract_address: pool_address };

    let manager_calldata = array![
        pool_address.into(), // pool address
        eth_address.into(), // token0 address
        usdc_address.into() // token1 address
    ];
    let manager_address = deploy_contract("UniswapV3Manager", manager_calldata);
    let mut manager = IUniswapV3ManagerDispatcher { contract_address: manager_address };

    // transfer tokens to manager for callbacks
    eth_token.transfer(manager_address, 1000000);
    usdc_token.transfer(manager_address, 42);

    eth_token.transfer(pool_address, 1000000);
    usdc_token.transfer(pool_address, 1000000);

    manager
        .mint(
            params.lower_tick, params.upper_tick, params.liq.try_into().unwrap(), array![].into(),
        );

    let (amount0, amount1) = pool.swap(recipient, manager_address, array![].into());
    println!("amount0: {}", amount0);
    println!("amount1: {}", amount1);

    assert(amount0 == -8396714242162444_i128, 'Invalid ETH out');
    assert(amount1 == 42_i128, 'Invalid USDC in');
}
