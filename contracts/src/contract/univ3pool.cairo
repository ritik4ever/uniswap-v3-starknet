// should have: reserve 0, reserve 1, liquidity, position holders map, 

#[starknet::contract]
mod UniswapV3Pool {
    use starknet::storage::StoragePointerWriteAccess;
    use contracts::libraries::{position::Position, tick::Tick};
    use contracts::contract::interface::UniswapV3PoolTrait;
    use starknet::ContractAddress;
    use starknet::storage::{StorageMapWriteAccess, StorageMapReadAccess};

    const MIN_TICK: i32 = -887272;
    const MAX_TICK: i32 = -MIN_TICK;
    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Slot0 {
        sqrt_pricex96: u256,
        tick: i32,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
    }
    #[constructor]
    fn constructor(ref self: ContractState, token0: ContractAddress, token1: ContractAddress, sqrt_pricex96: u256, tick: i32) {
        assert(tick > MIN_TICK , 'Tick must be higher');
        assert(tick < MAX_TICK , 'Tick must be lower');

        self.token0.write(token0);
        self.token1.write(token1);
    }
    #[abi(embed_v0)]
    impl IUniswapV3PoolImpl of UniswapV3PoolTrait<ContractState> {
        fn mint(ref self: ContractState, lower_tick: i32, upper_tick: i32, amount: u128) -> (u256,u256) {
            assert!(lower_tick > MIN_TICK, "lower tick too low");
            assert!(upper_tick < MAX_TICK, "upper tick too high");
            assert!(lower_tick <= upper_tick, "lower tick must be lower or equal to upper tick");
            assert!(amount != 0, "liq amount must be > 0");


            (1,1)
        }
    }
}