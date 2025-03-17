#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Slot0 {
    pub sqrt_pricex96: u256,
    pub tick: i32,
}
#[starknet::contract]
pub mod UniswapV3Pool {
    use contracts::contract::interface::{
        IERC20TraitDispatcher, IERC20TraitDispatcherTrait, ITickTrait, ITickTraitDispatcher,
        ITickTraitDispatcherTrait, IUniswapV3ManagerDispatcher, IUniswapV3ManagerDispatcherTrait,
        IUniswapV3TickBitmap, IUniswapV3TickBitmapDispatcher, IUniswapV3TickBitmapDispatcherTrait,
        UniswapV3PoolTrait,
    };
    use contracts::contract::univ3tick_bitmap::TickBitmap;
    use contracts::libraries::math::liquidity_math::LiquidityMath::{
        calc_amount0_delta, calc_amount1_delta,
    };
    use contracts::libraries::math::numbers::fixed_point::{
        FixedQ64x96, MAX_SQRT_RATIO, MIN_SQRT_RATIO,
    };
    use contracts::libraries::math::swap_math::SwapMath;
    use contracts::libraries::math::tick_math::TickMath;
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
    const MAX_I128: i128 = 170_141_183_460_469_231_731_687_303_715_884_105_727;
    const MIN_I128: i128 = -MAX_I128;


    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        slot0: Slot0,
        liquidity: u256,
        tick_address: ContractAddress,
        bitmap_address: ContractAddress,
        position_address: ContractAddress,
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

    #[derive(Copy, Drop)]
    struct SwapState {
        amount_specified_remaining: i128,
        amount_calculated: i128,
        sqrt_price_x96: u256,
        tick: i32,
        liquidity: u128,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token0: ContractAddress,
        token1: ContractAddress,
        sqrt_pricex96: u256,
        tick: i32,
        tick_address: ContractAddress,
        bitmap_address: ContractAddress,
        position_address: ContractAddress,
    ) {
        assert(tick > MIN_TICK, 'Tick must be higher');
        assert(tick < MAX_TICK, 'Tick must be lower');

        let slot0 = Slot0 { sqrt_pricex96, tick };
        self.token0.write(token0);
        self.token1.write(token1);
        self.slot0.write(slot0);
        self.tick_address.write(tick_address);
        self.bitmap_address.write(bitmap_address);
        self.position_address.write(position_address);
    }
    #[abi(embed_v0)]
    impl IUniswapV3PoolImpl of UniswapV3PoolTrait<ContractState> {
        fn mint(
            ref self: ContractState,
            lower_tick: i32,
            upper_tick: i32,
            amount: u128,
            data: Array<felt252>,
        ) -> (u256, u256) {
            assert!(lower_tick > MIN_TICK, "lower tick too low");
            assert!(upper_tick < MAX_TICK, "upper tick too high");
            assert!(lower_tick <= upper_tick, "lower tick must be lower or equal to upper tick");
            assert!(amount != 0, "liq amount must be > 0");
            #[cairofmt::skip]
            // TODO: uncomment this when we have custom tick_spacing.
            // assert!(lower_tick % tick_spacing == 0 && upper_tick % tick_spacing == 0, "tick not divisible by spacing")

            let slot0 = self.slot0.read();
            let current_tick = slot0.tick;
            let current_sqrt_price = slot0.sqrt_pricex96;
            let current_sqrt_price_x96 = FixedQ64x96 { value: current_sqrt_price };

            let sqrt_price_lower_x96 = TickMath::get_sqrt_ratio_at_tick(lower_tick);
            let sqrt_price_upper_x96 = TickMath::get_sqrt_ratio_at_tick(upper_tick);

            let (amount0, amount1) = if current_tick < lower_tick {
                let amount0 = calc_amount0_delta(
                    sqrt_price_lower_x96, sqrt_price_upper_x96, amount,
                );
                (amount0, 0_u256)
            } else if current_tick < upper_tick {
                let amount0 = calc_amount0_delta(
                    current_sqrt_price_x96.clone(), sqrt_price_upper_x96, amount,
                );
                let amount1 = calc_amount1_delta(
                    sqrt_price_lower_x96, current_sqrt_price_x96, amount,
                );
                (amount0, amount1)
            } else {
                let amount1 = calc_amount1_delta(
                    sqrt_price_lower_x96, sqrt_price_upper_x96, amount,
                );
                (0_u256, amount1)
            };

            let key = Key { owner: get_caller_address(), lower_tick, upper_tick };
            let mut tick_state = Tick::unsafe_new_contract_state();
            let mut position_state = Position::unsafe_new_contract_state();
            let mut bitmap_state = TickBitmap::unsafe_new_contract_state();

            let tick_spacing = 1; // will be customisable later
            let liq_delta = amount.try_into().expect('liq_delta');

            let flipped_lower = tick_state.update(lower_tick, liq_delta, false);
            let flipped_upper = tick_state.update(upper_tick, liq_delta, true);

            if flipped_lower {
                bitmap_state.flip_tick(lower_tick, tick_spacing);
            }

            if flipped_upper {
                bitmap_state.flip_tick(upper_tick, tick_spacing);
            }

            position_state.update(key, amount);
            let new_liq = position_state.get(key).liq;

            if current_tick >= lower_tick && current_tick < upper_tick {
                self.liquidity.write(new_liq.into());
            }
            let amount0_u128: u128 = amount0.try_into().unwrap_or(0);
            let amount1_u128: u128 = amount1.try_into().unwrap_or(0);

            let manager_dispatcher = IUniswapV3ManagerDispatcher {
                contract_address: get_caller_address(),
            };

            manager_dispatcher.mint_callback(amount0_u128, amount1_u128, data);

            self.emit(Mint { sender: get_caller_address(), upper_tick, lower_tick, amount });

            (amount0, amount1)
        }


        fn swap(
            ref self: ContractState,
            recipient: ContractAddress,
            callback_address: ContractAddress,
            zero_for_one: bool,
            amount_specified: i128,
            sqrt_price_limit_x96: FixedQ64x96,
            data: Array<felt252>,
        ) -> (i128, i128) {
            assert(amount_specified != 0, 'AS'); // Amount specified must be non-zero

            let slot0 = self.slot0.read();
            let current_sqrt_price = FixedQ64x96 { value: slot0.sqrt_pricex96 };

            if zero_for_one {
                assert(
                    sqrt_price_limit_x96.clone().value < current_sqrt_price.value
                        && sqrt_price_limit_x96.clone().value > MIN_SQRT_RATIO,
                    'SPL',
                );
            } else {
                assert(
                    sqrt_price_limit_x96.value > current_sqrt_price.value
                        && sqrt_price_limit_x96.value < MAX_SQRT_RATIO,
                    'SPL',
                );
            }

            let exact_input = amount_specified > 0;

            let mut state = SwapState {
                amount_specified_remaining: amount_specified,
                amount_calculated: 0,
                sqrt_price_x96: slot0.sqrt_pricex96,
                tick: slot0.tick,
                liquidity: self.liquidity.read().try_into().unwrap(),
            };

            // Reading addresses before creating dispatchers
            let bitmap_address = self.bitmap_address.read();
            let tick_address = self.tick_address.read();

            let mut bitmap_dispatcher = IUniswapV3TickBitmapDispatcher {
                contract_address: bitmap_address,
            };

            let mut tick_dispatcher = ITickTraitDispatcher { contract_address: tick_address };

            let tick_spacing = 1; // Will be customizable later

            // Track whether we had to clamp values to prevent underflow
            let mut clamped = false;

            while state.amount_specified_remaining != 0
                && state.sqrt_price_x96 != sqrt_price_limit_x96.value {
                let step_sqrt_price_start_x96 = state.sqrt_price_x96;

                let (mut next_tick, initialized) = bitmap_dispatcher
                    .next_initialized_tick_within_one_word(state.tick, tick_spacing, zero_for_one);

                if next_tick < MIN_TICK {
                    next_tick = MIN_TICK;
                } else if next_tick > MAX_TICK {
                    next_tick = MAX_TICK;
                }

                let next_sqrt_price_x96 = TickMath::get_sqrt_ratio_at_tick(next_tick);

                let target_sqrt_price_x96 = if (zero_for_one
                    && next_sqrt_price_x96.clone().value < sqrt_price_limit_x96.value)
                    || (!zero_for_one
                        && next_sqrt_price_x96.clone().value > sqrt_price_limit_x96.value) {
                    sqrt_price_limit_x96.value
                } else {
                    next_sqrt_price_x96.clone().value
                };

                let (new_sqrt_price_x96, amount_in, amount_out) = InternalImpl::process_swap_step(
                    FixedQ64x96 { value: state.sqrt_price_x96 },
                    FixedQ64x96 { value: target_sqrt_price_x96 },
                    state.liquidity,
                    state.amount_specified_remaining,
                    zero_for_one,
                );

                state.sqrt_price_x96 = new_sqrt_price_x96.value;

                if exact_input {
                    if amount_in > 0 && state.amount_specified_remaining < MIN_I128 + amount_in {
                        state.amount_specified_remaining = MIN_I128;
                        clamped = true;
                    } else {
                        state.amount_specified_remaining -= amount_in;
                    }

                    // check for overflow
                    if amount_out < 0 && state.amount_calculated < MIN_I128 - amount_out {
                        state.amount_calculated = MIN_I128;
                        clamped = true;
                    } else if amount_out > 0 && state.amount_calculated > MAX_I128 - amount_out {
                        state.amount_calculated = MAX_I128;
                        clamped = true;
                    } else {
                        state.amount_calculated += amount_out;
                    }
                } else {
                    // overflow check
                    if amount_out < 0 && state.amount_specified_remaining < MIN_I128 - amount_out {
                        state.amount_specified_remaining = MIN_I128;
                        clamped = true;
                    } else if amount_out > 0 && state.amount_specified_remaining > MAX_I128
                        - amount_out {
                        state.amount_specified_remaining = MAX_I128;
                        clamped = true;
                    } else {
                        state.amount_specified_remaining += amount_out;
                    }

                    // underflow check
                    if amount_in > 0 && state.amount_calculated < MIN_I128 + amount_in {
                        state.amount_calculated = MIN_I128;
                        clamped = true;
                    } else {
                        state.amount_calculated -= amount_in;
                    }
                }

                if state.sqrt_price_x96 == next_sqrt_price_x96.value {
                    if initialized {
                        let liquidity_net = tick_dispatcher.cross(next_tick);

                        let liquidity_delta = if zero_for_one {
                            -liquidity_net
                        } else {
                            liquidity_net
                        };

                        state
                            .liquidity =
                                if liquidity_delta > 0 {
                                    state.liquidity + liquidity_delta.try_into().unwrap()
                                } else {
                                    state.liquidity - (-liquidity_delta).try_into().unwrap()
                                };
                    }

                    state.tick = if zero_for_one {
                        next_tick - 1
                    } else {
                        next_tick
                    };
                } else if state.sqrt_price_x96 != step_sqrt_price_start_x96 {
                    state
                        .tick =
                            TickMath::get_tick_at_sqrt_ratio(
                                FixedQ64x96 { value: state.sqrt_price_x96 },
                            );
                }

                // If we had to clamp values and have performed updates, break the loop
                // to avoid further underflow/overflow issues
                if clamped {
                    break;
                }
            }

            let mut slot0 = self.slot0.read();
            slot0.tick = state.tick;
            slot0.sqrt_pricex96 = state.sqrt_price_x96;
            self.slot0.write(slot0);

            self.liquidity.write(state.liquidity.into());

            // calculate final amounts without potential overflow-causing operations
            let mut amount0 = 0;
            let mut amount1 = 0;

            if zero_for_one == exact_input {
                if state.amount_specified_remaining == MIN_I128 {
                    amount0 = amount_specified;
                } else if amount_specified < state.amount_specified_remaining {
                    amount0 = 0;
                } else {
                    amount0 = amount_specified - state.amount_specified_remaining;
                }
                amount1 = state.amount_calculated;
            } else {
                amount0 = state.amount_calculated;
                if state.amount_specified_remaining == MIN_I128 {
                    amount1 = amount_specified;
                } else if amount_specified < state.amount_specified_remaining {
                    amount1 = 0;
                } else {
                    amount1 = amount_specified - state.amount_specified_remaining;
                }
            }

            if amount0 < 0 {
                let token0_addr = self.token0.read();
                let mut erc20_0 = IERC20TraitDispatcher { contract_address: token0_addr };
                let decimals0 = erc20_0.get_decimals();
                let scaled_amount0 = scale_amount(-amount0, decimals0);
                erc20_0.transfer(recipient, scaled_amount0.try_into().unwrap());
            }

            if amount1 < 0 {
                let token1_addr = self.token1.read();
                let mut erc20_1 = IERC20TraitDispatcher { contract_address: token1_addr };
                let decimals1 = erc20_1.get_decimals();
                let scaled_amount1 = scale_amount(-amount1, decimals1);
                erc20_1.transfer(recipient, scaled_amount1.try_into().unwrap());
            }

            let balance_before0 = if amount0 > 0 {
                let token0_addr = self.token0.read();
                let erc20_0 = IERC20TraitDispatcher { contract_address: token0_addr };
                erc20_0.balance_of(get_contract_address()).try_into().unwrap()
            } else {
                0_u256
            };

            let balance_before1 = if amount1 > 0 {
                let token1_addr = self.token1.read();
                let erc20_1 = IERC20TraitDispatcher { contract_address: token1_addr };
                erc20_1.balance_of(get_contract_address()).try_into().unwrap()
            } else {
                0_u256
            };

            let manager_dispatcher = IUniswapV3ManagerDispatcher {
                contract_address: callback_address,
            };
            manager_dispatcher.swap_callback(amount0, amount1, data);

            if amount0 > 0 {
                let token0_addr = self.token0.read();
                let erc20_0 = IERC20TraitDispatcher { contract_address: token0_addr };
                let decimals0 = erc20_0.get_decimals();
                let balance_after0 = erc20_0.balance_of(get_contract_address()).try_into().unwrap();
                let required_amount0 = scale_amount(amount0, decimals0);
                assert(
                    balance_after0 - balance_before0 >= required_amount0,
                    'Insufficient token0 received',
                );
            }

            if amount1 > 0 {
                let token1_addr = self.token1.read();
                let erc20_1 = IERC20TraitDispatcher { contract_address: token1_addr };
                let decimals1 = erc20_1.get_decimals();
                let balance_after1 = erc20_1.balance_of(get_contract_address()).try_into().unwrap();
                let required_amount1 = scale_amount(amount1, decimals1);
                assert(
                    balance_after1 - balance_before1 >= required_amount1,
                    'Insufficient token1 received',
                );
            }

            self
                .emit(
                    Swap {
                        sender: get_caller_address(),
                        recipient,
                        amount0,
                        amount1,
                        sqrt_pricex96: state.sqrt_price_x96,
                        liquidity: state.liquidity.into(),
                        tick: state.tick,
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

        fn slot0(self: @ContractState) -> Slot0 {
            self.slot0.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn process_swap_step(
            sqrt_ratio_current_x96: FixedQ64x96,
            sqrt_ratio_target_x96: FixedQ64x96,
            liquidity: u128,
            amount_remaining: i128,
            zero_for_one: bool,
        ) -> (FixedQ64x96, i128, i128) {
            // Call the core swap math function
            let (new_sqrt_price, amount_in, amount_out) = SwapMath::compute_swap_step(
                sqrt_ratio_current_x96,
                sqrt_ratio_target_x96,
                liquidity,
                amount_remaining,
                zero_for_one,
            );
            let amount_out_u128: u128 = amount_out.try_into().expect('amtout128');
            let amount_in_u128: u128 = amount_in.try_into().expect('amtin128');
            let signed_amount_in = amount_in_u128.try_into().expect('signd_amt_in');
            let signed_amount_out = -(amount_out_u128.try_into().expect('signd_amt_out'));

            (new_sqrt_price, signed_amount_in, signed_amount_out)
        }

        /// Safely converts a u256 value to i128, handling potential overflows
        /// Since amount_out can conceptually be negative (though returned as positive u256),
        /// we interpret large values as negative based on context
        fn safe_u256_to_i128(value: u256) -> i128 {
            if value.high > 0 || value.low > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF_u128 {
                // If the value is too large for i128, we need to handle this case
                // This could happen in certain edge cases
                // Return MAX_I128 as a safety measure
                return 170_141_183_460_469_231_731_687_303_715_884_105_727; // MAX_I128
            }

            // For regular values, just convert directly as they're small enough to fit
            value.low.try_into().unwrap()
        }
    }
}
