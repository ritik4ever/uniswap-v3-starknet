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
}
