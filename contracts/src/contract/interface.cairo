use contracts::libraries::position::{Key, Info};

#[starknet::interface]
pub trait UniswapV3PoolTrait<TContractState> {
    fn mint(ref self: TContractState, lower_tick: i32, upper_tick: i32, amount: u128);
    fn get_liquidity(self: @TContractState) -> u256;
    fn is_tick_init(self: @TContractState, tick: i32) -> bool;
    fn swap(ref self: TContractState) -> (u128, u128);
}

#[starknet::interface]
pub trait ITickTrait<TContractState> {
    fn update(ref self: TContractState, tick: i32, liq_delta: u128);
    fn is_init(self: @TContractState, tick: i32) -> bool;
}

#[starknet::interface]
pub trait IPositionTrait<TContractState> {
    fn update(ref self: TContractState, key: Key, liq_delta: u128);
    fn get(self: @TContractState, key: Key) -> Info;
}
