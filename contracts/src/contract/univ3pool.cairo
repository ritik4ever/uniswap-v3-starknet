// should have: reserve 0, reserve 1, liquidity, position holders map, 

#[starknet::contract]
mod UniswapV3Pool {
    use starknet::storage::StoragePointerWriteAccess;
use contracts::contract::{position::Position, tick::Tick};
    use starknet::ContractAddress;
    use starknet::storage::{StorageMapWriteAccess, StorageMapReadAccess};

    const MIN_TICK: i32 = -887272;
    const MAX_TICK: i32 = -MIN_TICK;
    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        sqrt_pricex96: u256,
        tick: i32,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
    }
    #[constructor]
    fn constructor(ref self: ContractState, token0: ContractAddress, token1: ContractAddress, sqrt_pricex96: u256, tick: i32) {
        assert(tick >= MIN_TICK , 'Tick must be higher');
        assert(tick <= MAX_TICK , 'Tick must be lower');

        self.token0.write(token0);
        self.token1.write(token1);
        self.sqrt_pricex96.write(sqrt_pricex96);
        self.tick.write(tick);
    }
}