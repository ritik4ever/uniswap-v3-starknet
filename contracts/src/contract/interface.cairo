#[starknet::interface]
pub trait UniswapV3PoolTrait<TContractState> {
    fn mint(ref self: TContractState, lower_tick: i32, upper_tick: i32, amount: u128) -> (u256,u256);
}