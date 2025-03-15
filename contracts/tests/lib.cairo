#[cfg(test)]
mod test_contract {
    mod test_contract;
    mod utils;
}

#[cfg(test)]
mod math_tests {
    mod fullmath_test;
    mod liquidity_math_test;
    mod sqrtprice_math_test;
    mod tick_math_test;
    mod number {
        mod fixed_point_test;
    }
}
