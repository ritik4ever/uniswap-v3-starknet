#[derive(Copy, Drop, Serde, starknet::Store)]
struct Slot0 {
    sqrt_pricex96: u256,
    tick: i32,
}
#[starknet::contract]
pub mod UniswapV3Pool {
    use contracts::contract::interface::{
        IERC20Trait, IERC20TraitDispatcher, IERC20TraitDispatcherTrait, ITickTrait,
        IUniswapV3ManagerDispatcher, IUniswapV3ManagerDispatcherTrait, UniswapV3PoolTrait,
    };
    use contracts::libraries::erc20::ERC20;
    use contracts::libraries::position::Position::IPositionImpl;
    use contracts::libraries::position::{Key, Position};
    use contracts::libraries::tick::Tick;
    use contracts::libraries::tick::Tick::ITickImpl;
    use contracts::libraries::utils::math::scale_amount;
    use starknet::event::EventEmitter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
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
        Swap: Swap,
    }

    #[derive(Drop, starknet::Event)]
    struct Mint {
        sender: ContractAddress,
        upper_tick: i32,
        lower_tick: i32,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct Swap {
        sender: ContractAddress,
        recipient: ContractAddress,
        amount0: i128,
        amount1: i128,
        sqrt_pricex96: u256,
        liquidity: u256,
        tick: i32,
    }

    #[derive(Copy, Drop, Serde)]
    struct CallbackData {
        token0: ContractAddress,
        token1: ContractAddress,
        payer: ContractAddress,
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
        fn mint(ref self: ContractState, lower_tick: i32, upper_tick: i32, amount: u128, data: Array<felt252>) -> (u256, u256) {
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

            let manager_dispatcher = IUniswapV3ManagerDispatcher { contract_address: get_caller_address() };
            manager_dispatcher.mint_callback(1,1,data);

            self.emit(Mint { sender: get_caller_address(), upper_tick, lower_tick, amount });
            (1,1)
        }

        fn swap(
            ref self: ContractState, recipient: ContractAddress, callback_address: ContractAddress, data: Array<felt252>
        ) -> (i128, i128) {
            let caller = get_caller_address();
            let mut slot0 = self.slot0.read();

            // hardcoded values for now
            let next_tick = 85184;
            let next_price = 5604469350942327889444743441197;

            // ETH out (negative), USDC in (positive)
            let amount0 = -8396714242162444_i128;
            let amount1 = 42_i128;

            slot0.tick = next_tick;
            slot0.sqrt_pricex96 = next_price;
            self.slot0.write(slot0);

            // transfer output token (ETH)
            let token0_addr = self.token0.read();
            let mut erc20_0 = IERC20TraitDispatcher { contract_address: token0_addr };
            let decimals0 = erc20_0.get_decimals();
            let scaled_amount0 = scale_amount(-amount0, decimals0);
            erc20_0.transfer(recipient, scaled_amount0.try_into().unwrap());

            let token1_addr = self.token1.read();
            let mut erc20_1 = IERC20TraitDispatcher { contract_address: token1_addr };
            let decimals1 = erc20_1.get_decimals();
            let balance_before: u256 = erc20_1
                .balance_of(get_contract_address())
                .try_into()
                .unwrap();

            // execute callback to receive tokens
            let manager_dispatcher = IUniswapV3ManagerDispatcher {
                contract_address: callback_address,
            };
            manager_dispatcher.swap_callback(amount0, amount1, array![]);

            let balance_after: u256 = erc20_1
                .balance_of(get_contract_address())
                .try_into()
                .unwrap();
            let required_amount1 = scale_amount(amount1, decimals1);

            assert(
                balance_after - balance_before >= required_amount1, 'Insufficient USDC received',
            );

            self
                .emit(
                    Swap {
                        sender: caller,
                        recipient,
                        amount0,
                        amount1,
                        sqrt_pricex96: slot0.sqrt_pricex96,
                        liquidity: self.get_liquidity(),
                        tick: slot0.tick,
                    },
                );

            (amount0, amount1)
        }


        fn get_liquidity(self: @ContractState) -> u256 {
            self.liquidity.read()
        }

        fn is_tick_init(self: @ContractState, tick: i32) -> bool {
            Tick::unsafe_new_contract_state().is_init(tick)
        }
    }
}
