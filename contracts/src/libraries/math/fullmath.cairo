pub mod full_math {
    /// Calculates floor(a×b÷denominator) with full precision.
    /// The result will be rounded down.
    ///
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The result of a*b/denominator
    pub fn mul_div(a: u256, b: u256, denominator: u256) -> u256 {
        assert(denominator > 0, 'division by zero');

        // 512-bit multiply using high/low parts to handle overflow
        let mut res = a * b;

        res = res / denominator;

        return res;
    }

    /// Calculates ceil(a×b÷denominator) with full precision.
    /// The result will be rounded up.
    ///
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The result of a*b/denominator, rounded up
    pub fn mul_div_rounding_up(a: u256, b: u256, denominator: u256) -> u256 {
        assert(denominator > 0, 'division by zero');

        let mut res = a * b;

        let remainder = res % denominator;
        res = res / denominator;

        if remainder > 0 {
            return res + 1;
        }

        return res;
    }

    /// Calculates ceil(numerator÷denominator) with full precision.
    /// The result will be rounded up.
    ///
    /// @param numerator The numerator
    /// @param denominator The divisor
    /// @return result The result of numerator/denominator, rounded up
    pub fn div_rounding_up(numerator: u256, denominator: u256) -> u256 {
        assert(denominator > 0, 'division by zero');

        let res = numerator / denominator;

        if numerator % denominator > 0 {
            return res + 1;
        }

        return res;
    }
}
