#[starknet::contract]
mod SwapCallbackHandler {
    use contracts::contract::interface::{
        IERC20TraitDispatcher, IERC20TraitDispatcherTrait, IUniswapV3SwapCallback,
    };
    use contracts::libraries::utils::math::scale_amount;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        pool_address: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token0: ContractAddress,
        token1: ContractAddress,
        pool_address: ContractAddress,
    ) {
        self.token0.write(token0);
        self.token1.write(token1);
        self.pool_address.write(pool_address);
    }

    #[abi(embed_v0)]
    impl SwapCallbackImpl of IUniswapV3SwapCallback<ContractState> {
        fn swap_callback(
            ref self: ContractState, amount0_delta: i128, amount1_delta: i128, data: Array<felt252>,
        ) {
            let caller = get_caller_address();
            assert(caller == self.pool_address.read(), 'Only pool can call');

            // If amount1_delta is positive, we need to send USDC to pool
            if amount1_delta > 0 {
                let token1 = self.token1.read();
                let mut token1_dispatcher = IERC20TraitDispatcher { contract_address: token1 };

                let abs_amount = if amount1_delta < 0 {
                    -amount1_delta
                } else {
                    amount1_delta
                };

                token1_dispatcher.transfer(caller, abs_amount.into());
            }

            // If amount0_delta is positive, we need to send ETH to pool
            if amount1_delta > 0 {
                let token1 = self.token1.read();
                let mut token1_dispatcher = IERC20TraitDispatcher { contract_address: token1 };
                let decimals1 = token1_dispatcher.get_decimals();

                let scaled_amount = scale_amount(amount1_delta, decimals1);
                token1_dispatcher.transfer(caller, scaled_amount.try_into().unwrap());
            }
        }
    }
}
