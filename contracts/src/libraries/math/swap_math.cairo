pub mod SwapMath {
    use contracts::libraries::math::liquidity_math::LiquidityMath::{
        calc_amount0_delta, calc_amount1_delta,
    };
    use contracts::libraries::math::numbers::fixed_point::FixedQ64x96;
    use contracts::libraries::math::sqrtprice_math::SqrtPriceMath;
    const MAX_i128: i128 = 170_141_183_460_469_231_731_687_303_715_884_105_727;

    /// Computes the result of a swap step
    pub fn compute_swap_step(
        sqrt_ratio_current_x96: FixedQ64x96,
        sqrt_ratio_target_x96: FixedQ64x96,
        liquidity: u128,
        amount_remaining: i128,
        zero_for_one: bool,
    ) -> (FixedQ64x96, u256, u256) {
        let mut sqrt_ratio_next_x96: FixedQ64x96 = FixedQ64x96 { value: 0 };
        let mut amount_in: u256 = 0.into();
        let mut amount_out: u256 = 0.into();

        if zero_for_one {
            let next_sqrt_price = SqrtPriceMath::get_next_sqrt_price_from_input(
                sqrt_ratio_current_x96.clone(), liquidity, abs_i128(amount_remaining).into(), true,
            );

            sqrt_ratio_next_x96 =
                if next_sqrt_price.value < sqrt_ratio_target_x96.value {
                    next_sqrt_price
                } else {
                    sqrt_ratio_target_x96
                };

            // Keep full u256 result
            amount_in =
                calc_amount0_delta(
                    sqrt_ratio_current_x96.clone(), sqrt_ratio_next_x96.clone(), liquidity,
                );

            // Keep full u256 result
            amount_out =
                calc_amount1_delta(
                    sqrt_ratio_current_x96.clone(), sqrt_ratio_next_x96.clone(), liquidity,
                );
        } else {
            // For token1 to token0 swaps
            let next_sqrt_price = SqrtPriceMath::get_next_sqrt_price_from_input(
                sqrt_ratio_current_x96.clone(), liquidity, abs_i128(amount_remaining).into(), false,
            );

            sqrt_ratio_next_x96 =
                if next_sqrt_price.value > sqrt_ratio_target_x96.value {
                    next_sqrt_price
                } else {
                    sqrt_ratio_target_x96
                };

            // Keep full u256 result
            amount_in =
                calc_amount1_delta(
                    sqrt_ratio_current_x96.clone(), sqrt_ratio_next_x96.clone(), liquidity,
                );

            // Keep full u256 result with proper negation
            let out_amount = calc_amount0_delta(
                sqrt_ratio_current_x96, sqrt_ratio_next_x96.clone(), liquidity,
            );
            // Handle negation properly for u256
            amount_out = out_amount;
        }

        (sqrt_ratio_next_x96, amount_in, amount_out)
    }

    fn abs_i128(value: i128) -> u128 {
        if value < 0 {
            (-value).try_into().expect('abs_128<')
        } else {
            value.try_into().expect('abs_128else')
        }
    }
}
