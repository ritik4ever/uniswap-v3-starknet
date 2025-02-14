// should have: reserve 0, reserve 1, liquidity, position holders map, 
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Slot0 {
    sqrt_pricex96: u256,
    tick: i32,
}
#[starknet::contract]
mod UniswapV3Pool {
    use starknet::storage::StoragePointerWriteAccess;
    use contracts::contract::interface::UniswapV3PoolTrait;
    use contracts::libraries::tick::{Tick, Tick::ITickImpl};
    use contracts::libraries::position::{Key, Position, Position::IPositionImpl};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StorageMapWriteAccess, StorageMapReadAccess};
    use super::*;
    const MIN_TICK: i32 = -887272;
    const MAX_TICK: i32 = -MIN_TICK;
    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        slot0: Slot0,
        liquidity: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
    }
    #[constructor]
    fn constructor(ref self: ContractState, token0: ContractAddress, token1: ContractAddress, sqrt_pricex96: u256, tick: i32) {
        assert(tick > MIN_TICK , 'Tick must be higher');
        assert(tick < MAX_TICK , 'Tick must be lower');

        let slot0 = Slot0 { sqrt_pricex96, tick };
        self.token0.write(token0);
        self.token1.write(token1);
        self.slot0.write(slot0);
    }
    #[abi(embed_v0)]
    impl IUniswapV3PoolImpl of UniswapV3PoolTrait<ContractState> {
        fn mint(ref self: ContractState, lower_tick: i32, upper_tick: i32, amount: u128) {
            assert!(lower_tick > MIN_TICK, "lower tick too low");
            assert!(upper_tick < MAX_TICK, "upper tick too high");
            assert!(lower_tick <= upper_tick, "lower tick must be lower or equal to upper tick");
            assert!(amount != 0, "liq amount must be > 0");
            
            let key = Key { owner: get_caller_address(), lower_tick, upper_tick };
            let mut tick_state = Tick::unsafe_new_contract_state();
            let mut position_state = Position::unsafe_new_contract_state();
            let pos = IPositionImpl::get(@position_state, key);
            
            ITickImpl::update(ref tick_state, lower_tick, amount);
            ITickImpl::update(ref tick_state, upper_tick, amount);
            IPositionImpl::update(ref position_state, key, amount);

            self.liquidity.write(pos.liq.into());
        }
    }
}