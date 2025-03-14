pub mod SqrtPriceMath {
    use alexandria_math::const_pow::pow2_u256;
    use contracts::libraries::math::fullmath::full_math::{
        div_rounding_up, mul_div, mul_div_rounding_up,
    };
    use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};

    const MAX_u256: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
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
    pub fn get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_pricex96: FixedQ64x96, liquidity: u128, amount: u256, add: bool,
    ) -> FixedQ64x96 {
        if amount == 0 {
            return sqrt_pricex96;
        }
        
        let sqrt_price_value = sqrt_pricex96.value;
        let u256_liq = u256 { low: liquidity, high: 0 };
        let numerator = u256_liq * pow2_u256(96);
        
        if add {
            // if adding token0, price decreases
            // Use alternative formula to avoid overflow when amount or sqrt_price is large
            if amount > 0xffffffffffffffff_u256 || sqrt_price_value > 0xffffffffffffffff_u256 {
                // Use the division-based formula which is less likely to overflow
                return IFixedQ64x96Impl::new(
                    div_rounding_up(numerator, (numerator / sqrt_price_value) + amount),
                );
            } else {
                // Safe for smaller values - direct multiplication
                let product = amount * sqrt_price_value;
                let denominator = numerator + product;
                return IFixedQ64x96Impl::new(
                    mul_div_rounding_up(numerator, sqrt_price_value, denominator),
                );
            }
        } else {
            // if removing token0, price increases
            // For removal, use mul_div which handles overflow better
            let product = mul_div(amount, sqrt_price_value, 1);  // Calculate safely
            assert(product <= numerator, 'liquidity underflow');
            let denominator = numerator - product;
            return IFixedQ64x96Impl::new(
                mul_div_rounding_up(numerator, sqrt_price_value, denominator),
            );
        }
    }
    

    pub fn get_next_sqrt_price_from_amount1_rounding_down(
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
    pub fn get_next_sqrt_price_from_input(
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
    pub fn get_next_sqrt_price_from_output(
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
