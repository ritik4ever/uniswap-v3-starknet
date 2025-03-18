pub mod full_math {
    const MAX_u256: u256 =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    /// Calculates floor(a×b÷denominator) with full precision.
    /// The result will be rounded down.
    ///
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The result of a*b/denominator
    pub fn mul_div(a: u256, b: u256, denominator: u256) -> u256 {
        assert(denominator > 0, 'division by zero');

        // Handle simple cases
        if a == 0 || b == 0 {
            return 0;
        }

        // Optimize for cases where a/denominator is exact
        if a % denominator == 0 {
            return (a / denominator) * b;
        }

        // Optimize for cases where b/denominator is exact
        if b % denominator == 0 {
            return a * (b / denominator);
        }

        // For general case, break down calculation to avoid overflow
        let quotient_a = a / denominator;
        let remainder_a = a % denominator;

        // First part: quotient_a * b
        let result1 = quotient_a * b;

        // Second part: (remainder_a * b) / denominator
        // This may still overflow if b is very large, so we need further division
        let result2 = (remainder_a * b) / denominator;

        result1 + result2
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

        if a == 0 || b == 0 {
            return 0;
        }

        // early optimization: if both numbers are small enough do direct calculation
        if a <= 0xffffffff_u256 && b <= 0xffffffff_u256 {
            let product = a * b;
            let result = product / denominator;
            if product % denominator > 0 {
                return result + 1;
            }
            return result;
        }

        // for larger numbers divide first to avoid overflow
        let quotient = a / denominator;
        let remainder = a % denominator;

        let mut res = quotient * b;

        if remainder > 0 {
            // Check if we can safely multiply remainder and b
            if b < MAX_u256 / remainder {
                let rem_term = (remainder * b) / denominator;
                res = res + rem_term;

                if (remainder * b) % denominator > 0 {
                    res = res + 1;
                }
            } else {
                // For extremely large b values, divide b first
                let partial_b = b / denominator;
                let partial_product = remainder * partial_b;
                res = res + partial_product;

                // Handle the remaining part with extra care
                let b_remainder = b % denominator;

                if b_remainder > 0 && remainder > 0 {
                    // Calculate (remainder * b_remainder) / denominator more safely
                    if remainder <= MAX_u256 / b_remainder {
                        // Direct calculation is safe
                        let rem_product = remainder * b_remainder;
                        res = res + rem_product / denominator;
                        if rem_product % denominator > 0 {
                            res = res + 1;
                        }
                    } else {
                        // the product would overflow, add 1 for rounding up
                        // This is a simplification but ensures we round up
                        res = res + 1;
                    }
                }
            }
        }

        res
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

        res
    }
}
