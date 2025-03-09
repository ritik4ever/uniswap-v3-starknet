// should have: reserve 0, reserve 1, liquidity, position holders map?,
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Slot0 {
    sqrt_pricex96: u256,
    tick: i32,
}
#[starknet::contract]
pub mod UniswapV3Pool {
    use contracts::contract::interface::{ITickTrait, UniswapV3PoolTrait, IERC20Trait};
    use contracts::libraries::erc20::ERC20;
    use contracts::libraries::position::Position::IPositionImpl;
    use contracts::libraries::position::{Key, Position};
    use contracts::libraries::tick::Tick;
    use contracts::libraries::tick::Tick::ITickImpl;
    use starknet::event::EventEmitter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
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
        Mint: Mint,
    }

    #[derive(Drop, starknet::Event)]
    struct Mint {
        sender: ContractAddress,
        upper_tick: i32,
        lower_tick: i32,
        amount: u128,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token0: ContractAddress,
        token1: ContractAddress,
        sqrt_pricex96: u256,
        tick: i32,
    ) {
        assert(tick > MIN_TICK, 'Tick must be higher');
        assert(tick < MAX_TICK, 'Tick must be lower');

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
            tick_state.update(lower_tick, amount);
            tick_state.update(upper_tick, amount);
            position_state.update(key, amount);

            let new_liq = position_state.get(key).liq;
            self.liquidity.write(new_liq.into());
            self.emit(Mint { sender: get_caller_address(), upper_tick, lower_tick, amount });
        }

        fn swap(ref self: ContractState) -> (u128, u128) {
            let caller = get_caller_address();
            let mut slot0 = self.slot0.read();

            let next_tick = 85184;
            let next_price = 5604469350942327889444743441197;

            let amount0 =
                -8396714242162444; // ETH, needs to be divided by 10^18 (decimals) to be -0.008396714242162444
            let amount1 = 42; // 42 usdc scaled

            slot0.tick = next_tick;
            slot0.sqrt_pricex96 = next_price;

            let mut erc20 = ERC20::unsafe_new_contract_state();

            erc20.transfer(caller, amount0);

            (1, 1)
        }

        fn get_liquidity(self: @ContractState) -> u256 {
            self.liquidity.read()
        }

        fn is_tick_init(self: @ContractState, tick: i32) -> bool {
            Tick::unsafe_new_contract_state().is_init(tick)
        }
    }
}
