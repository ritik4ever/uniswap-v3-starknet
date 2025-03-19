use starknet::ContractAddress;

#[starknet::contract]
mod UniswapV3Quoter {
    use contracts::contract::interface::{
        IUniswapV3Quoter, UniswapV3PoolTraitDispatcher, UniswapV3PoolTraitDispatcherTrait,
    };
    use contracts::libraries::math::numbers::fixed_point::IFixedQ64x96Impl;
    use super::*;
    #[storage]
    pub struct Storage {}


    #[abi(embed_v0)]
    impl IUniswapV3QuoterImpl of IUniswapV3Quoter<ContractState> {
        /// Experimental view-only quoter function that simulates swaps without gas fees.
        ///
        /// # Cairo vs Solidity View Functions: Important Differences
        ///
        /// In Solidity/EVM:
        /// - View functions use STATICCALL opcode which prevents ANY state modifications
        /// - This includes state changes in both the current contract AND any other contracts it
        /// calls - This is why Uniswap V3's original Quoter couldn't be a view function:
        ///   it needed to call the Pool's swap function which modifies state, then catch the revert
        ///
        /// In Cairo/StarkNet:
        /// - View functions (using `self: @ContractState`) only prevent state modifications in the
        ///   current contract
        /// - Unlike Solidity, Cairo view functions CAN call non-view functions of other contracts
        /// - This allows us to call `simulate_swap` (a non-state-modifying function) from this view
        /// function
        ///
        /// # Benefits of This Approach
        ///
        /// 1. Gas-free quotes: Users don't pay for quote transactions
        /// 2. Better UX: Quotes can be requested without signing transactions
        /// 3. Same accuracy: Uses the exact same math as actual swaps
        ///
        /// Note: This works because we implemented `simulate_swap` in the Pool contract
        /// which replicates swap logic without modifying state.
        fn quote(self: @ContractState, params: QuoteParams) -> (i128, i128, u256, i32) {
            let pool_dispatcher = UniswapV3PoolTraitDispatcher { contract_address: params.pool };
            pool_dispatcher
                .simulate_swap(
                    params.zero_for_one,
                    params.amount_specified,
                    sqrt_price_limit_x96: IFixedQ64x96Impl::new_unscaled(params.sqrt_price_limit),
                )
        }
    }
}

#[derive(Drop, Serde)]
pub struct QuoteParams {
    pub amount_specified: i128,
    pub zero_for_one: bool,
    pub pool: ContractAddress,
    pub sqrt_price_limit: u256,
}
