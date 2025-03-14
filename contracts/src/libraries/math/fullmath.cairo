pub mod full_math {
    const MAX_u256: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
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
        
        let quotient = a / denominator;
        let remainder = a % denominator;
        
        let mut res = quotient * b;
        
        if remainder > 0 {
            if b < MAX_u256 / remainder {
                let rem_term = (remainder * b) / denominator;
                res = res + rem_term;
                
                if (remainder * b) % denominator > 0 {
                    res = res + 1;
                }
            } else {
                // if large b, divide b first to avoid overflow
                let partial_b = b / denominator;
                let partial_product = remainder * partial_b;
                res = res + partial_product;
                
                let b_remainder = b % denominator;
                let rem_product = remainder * b_remainder;
                if rem_product > 0 {
                    res = res + rem_product / denominator;
                    if rem_product % denominator > 0 {
                        res = res + 1;
                    }
                }
            }
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
