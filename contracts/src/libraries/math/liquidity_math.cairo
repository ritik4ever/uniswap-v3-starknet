pub mod LiquidityMath {
    use contracts::libraries::math::fullmath::full_math::mul_div_rounding_up;
    use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, ONE};

    /// Calculates the amount of token1 corresponding to a price range and liquidity amount
    /// [`sqrt_price_a_x96`] One of the boundary prices
    /// [`sqrt_price_b_x96`] The other boundary price
    /// [`liquidity`] The amount of provided liquidity
    /// @return [`amount1`] The amount of token1
    pub fn calc_amount1_delta(
        sqrt_price_a_x96: FixedQ64x96, sqrt_price_b_x96: FixedQ64x96, liquidity: u128,
    ) -> u256 {
        let (min_sqrt_price, max_sqrt_price) = if sqrt_price_a_x96.value > sqrt_price_b_x96.value {
            (sqrt_price_b_x96.value, sqrt_price_a_x96.value)
        } else {
            (sqrt_price_a_x96.value, sqrt_price_b_x96.value)
        };
    
        let u256_liquidity = u256 { low: liquidity, high: 0 };
    
        mul_div_rounding_up(u256_liquidity, max_sqrt_price - min_sqrt_price, ONE)
    }    

    pub fn calc_amount0_delta(
        sqrt_price_a_x96: FixedQ64x96, 
        sqrt_price_b_x96: FixedQ64x96, 
        liquidity: u128,
    ) -> u256 {
        let (lower_price, upper_price) = if sqrt_price_a_x96.value <= sqrt_price_b_x96.value {
            (sqrt_price_a_x96, sqrt_price_b_x96)
        } else {
            (sqrt_price_b_x96, sqrt_price_a_x96)
        };
    
        let price_diff_div = mul_div_rounding_up(
            upper_price.value - lower_price.value,
            ONE,
            upper_price.value
        );
        
        let result = mul_div_rounding_up(
            u256 { low: liquidity, high: 0 },
            price_diff_div,
            lower_price.value
        );
        
        result
    }
    
}
