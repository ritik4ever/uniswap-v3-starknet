mod SqrtPriceMath {
    use alexandria_math::const_pow::pow2_u256;
    use contracts::libraries::math::fullmath::full_math::{
        div_rounding_up, mul_div, mul_div_rounding_up,
    };
    use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};

    const MAX_u128: u128 = 340_282_366_920_938_463_463_374_607_431_768_211_455;
    /// Returns the next square root price given a token0 delta
    ///
    /// [`sqrt_pricex96`]: The starting sqrt price before accounting for the token0 delta
    ///
    /// [`liquidity`] The amount of usable liquidity
    ///
    /// [`amount`] The amount of token0 to add or remove from virtual reserves
    ///
    ///  [`add`] Whether to add or remove the amount of token0
    ///
    /// @return The price after adding or removing amount, depending on add
    fn get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_pricex96: FixedQ64x96, liquidity: u128, amount: u256, add: bool,
    ) -> FixedQ64x96 {
        if amount == 0 {
            return sqrt_pricex96;
        }
        let sqrt_price_value = sqrt_pricex96.value;
        let u256_liq = u256 { low: liquidity, high: 0 };
        let numerator = u256_liq * pow2_u256(96);
        let product = amount * sqrt_price_value;

        if add {
            // if adding token0, price decreases
            let denominator = numerator + product;
            if denominator >= numerator {
                return IFixedQ64x96Impl::new(
                    mul_div_rounding_up(numerator, sqrt_price_value, denominator),
                );
            }

            // less precise version if we cannot compute using the precise formula
            return IFixedQ64x96Impl::new(
                div_rounding_up(numerator, (numerator / sqrt_price_value) + amount),
            );
        } else {
            // if removing token0, price increases
            assert(product <= numerator, 'liquidity underflow');
            let denominator = numerator - product;
            return IFixedQ64x96Impl::new(
                mul_div_rounding_up(numerator, sqrt_price_value, denominator),
            );
        }
    }

    fn get_next_sqrt_price_from_amount1_rounding_down(
        sqrt_pricex96: FixedQ64x96, liquidity: u128, amount: u256, add: bool,
    ) -> FixedQ64x96 {
        if amount == 0 {
            return sqrt_pricex96;
        }

        let u256_liq = u256 { low: liquidity, high: 0 };
        let max = u256 { low: MAX_u128, high: 0 };

        if add {
            // if adding token1, price increases
            let quotient = if amount <= max {
                (amount * pow2_u256(96)) / u256_liq
            } else {
                mul_div(amount, pow2_u256(96), u256_liq)
            };
            return IFixedQ64x96Impl::new(sqrt_pricex96.value + quotient);
        } else {
            // if removing token1, price decreases
            let quotient = if amount <= max {
                div_rounding_up(amount * pow2_u256(96), u256_liq)
            } else {
                mul_div_rounding_up(amount, pow2_u256(96), u256_liq)
            };

            assert(sqrt_pricex96.value > quotient, 'price underflow');
            return IFixedQ64x96Impl::new(sqrt_pricex96.value - quotient);
        }
    }

    /// Gets the next sqrt price given an input amount of token0 or token1
    ///
    /// [`sqrt_pricex96`]: The starting price before accounting for the input amount
    ///
    /// [`liquidity`]: The amount of usable liquidity
    ///
    /// [`amount_in`]: How much of token0 or token1 is being swapped in
    ///
    /// [`zero_for_one`]: Whether the amount in is token0 or token1
    ///
    /// @return The price after adding the input amount to token0 or token1
    fn get_next_sqrt_price_from_input(
        sqrt_pricex96: FixedQ64x96, liquidity: u128, amount_in: u256, zero_for_one: bool,
    ) -> FixedQ64x96 {
        assert(sqrt_pricex96.value > 0, 'invalid sqrtPrice');
        assert(liquidity > 0, 'invalid liquidity');

        // If zero_for_one is true, we're swapping token0 for token1 (decreasing price)
        // Otherwise, we're swapping token1 for token0 (increasing price)
        if zero_for_one {
            get_next_sqrt_price_from_amount0_rounding_up(sqrt_pricex96, liquidity, amount_in, true)
        } else {
            get_next_sqrt_price_from_amount1_rounding_down(
                sqrt_pricex96, liquidity, amount_in, true,
            )
        }
    }

    /// Gets the next sqrt price given an output amount of token0 or token1
    ///
    /// [`sqrt_pricex96`]: The starting price before accounting for the output amount
    ///
    /// [`liquidity`]: The amount of usable liquidity
    ///
    /// [`amount_out`]: How much of token0 or token1 is being swapped out
    ///
    /// [`zero_for_one`]: Whether the amount out is token0 or token1
    ///
    /// @return The price after removing the output amount of token0 or token1
    fn get_next_sqrt_price_from_output(
        sqrt_pricex96: FixedQ64x96, liquidity: u128, amount_out: u256, zero_for_one: bool,
    ) -> FixedQ64x96 {
        assert(sqrt_pricex96.value > 0, 'invalid sqrtPrice');
        assert(liquidity > 0, 'invalid liquidity');
        assert(amount_out > 0, 'amount out must be > 0');

        // The routing here is inverted compared to the input function
        // If zero_for_one is true, we're swapping token0 for token1, so we're removing token1
        // Otherwise, we're swapping token1 for token0, so we're removing token0
        if zero_for_one {
            get_next_sqrt_price_from_amount1_rounding_down(
                sqrt_pricex96, liquidity, amount_out, false,
            )
        } else {
            get_next_sqrt_price_from_amount0_rounding_up(
                sqrt_pricex96, liquidity, amount_out, false,
            )
        }
    }
}
