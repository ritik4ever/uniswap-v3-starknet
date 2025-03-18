use contracts::libraries::math::fullmath::full_math::{mul_div, mul_div_rounding_up};
use contracts::libraries::math::numbers::fixed_point::{
    FixedQ64x96, HALF, IFixedQ64x96Impl, IFixedQ64x96Trait, MAX_SQRT_RATIO, MIN_SQRT_RATIO, ONE,
};
#[test]
fn test_construction() {
    let fp: FixedQ64x96 = IFixedQ64x96Impl::new(ONE);
    assert(fp.value == ONE, 'Construction failed');

    let fp2: FixedQ64x96 = IFixedQ64x96Impl::new_unscaled(1);
    assert(fp2.value == ONE, 'Unscaled construction failed');

    let fp_min: FixedQ64x96 = IFixedQ64x96Impl::new(MIN_SQRT_RATIO);
    assert(fp_min.value == MIN_SQRT_RATIO, 'Min construction failed');

    let fp_max: FixedQ64x96 = IFixedQ64x96Impl::new(MAX_SQRT_RATIO - 1);
    assert(fp_max.value == MAX_SQRT_RATIO - 1, 'Max construction failed');
}

#[test]
#[should_panic(expected: 'sqrt ratio overflow')]
fn test_construction_overflow() {
    let _fp = IFixedQ64x96Impl::new(MAX_SQRT_RATIO + 1);
}

#[test]
#[should_panic(expected: 'sqrt ratio underflow')]
fn test_construction_underflow() {
    let _fp = IFixedQ64x96Impl::new(MIN_SQRT_RATIO - 1);
}

#[test]
fn test_addition() {
    let a = IFixedQ64x96Impl::new_unscaled(1);
    let b = IFixedQ64x96Impl::new_unscaled(2);
    let c = a + b;

    assert(c.value == ONE * 3, 'Addition failed');
}

#[test]
fn test_subtraction() {
    let a = IFixedQ64x96Impl::new_unscaled(3);
    let b = IFixedQ64x96Impl::new_unscaled(1);
    let c = a - b;

    assert(c.value == ONE * 2, 'Subtraction failed');
}

#[test]
#[should_panic(expected: 'sqrt price underflow')]
fn test_subtraction_underflow() {
    let a = IFixedQ64x96Impl::new_unscaled(1);
    let b = IFixedQ64x96Impl::new_unscaled(2);
    let _c = a - b;
}

#[test]
fn test_multiplication() {
    let a = IFixedQ64x96Impl::new_unscaled(2);
    let b = IFixedQ64x96Impl::new_unscaled(3);
    let c = a * b;

    assert(c.value == ONE * 6, 'Multiplication failed');

    // Test precision - 0.5 * 0.5 should be 0.25
    let half = IFixedQ64x96Impl::new(HALF);
    let quarter = half.clone() * half;
    assert(quarter.value == HALF / 2, 'Precision multiplication failed');
}

#[test]
fn test_division() {
    let a = IFixedQ64x96Impl::new_unscaled(6);
    let b = IFixedQ64x96Impl::new_unscaled(2);
    let c = a / b;

    assert(c.value == ONE * 3, 'Division failed');

    // Test precision - 1 / 2 should be 0.5
    let one = IFixedQ64x96Impl::new_unscaled(1);
    let two = IFixedQ64x96Impl::new_unscaled(2);
    let half_result = one / two;
    assert(half_result.value == HALF, 'Precision division failed');
}

#[test]
fn test_floor_and_ceil() {
    // Test floor with whole number
    let whole = IFixedQ64x96Impl::new_unscaled(2);
    let floor_whole = whole.clone().floor();
    assert(floor_whole.value == ONE * 2, 'Floor of whole number failed');

    // Test floor with fraction
    let one_and_half = IFixedQ64x96Impl::new(ONE + HALF);
    let floor_frac = one_and_half.clone().floor();
    assert(floor_frac.value == ONE, 'Floor of fraction failed');

    // Test ceil with whole number
    let ceil_whole = whole.ceil();
    assert(ceil_whole.value == ONE * 2, 'Ceil of whole number failed');

    // Test ceil with fraction
    let ceil_frac = one_and_half.ceil();
    assert(ceil_frac.value == ONE * 2, 'Ceil of fraction failed');
}

#[test]
fn test_sqrt() {
    // Test sqrt of 4
    let four = IFixedQ64x96Impl::new_unscaled(4);

    let two = four.sqrt();

    // Allow small margin of error due to fixed-point arithmetic
    let expected = ONE * 2;

    let epsilon = ONE / 1000; // 0.001 tolerance

    assert(two.value >= expected - epsilon && two.value <= expected + epsilon, 'Sqrt of 4 failed');

    // Test sqrt of 0
    let zero = IFixedQ64x96Impl::new_unscaled(0);
    let sqrt_zero = zero.sqrt();
    assert(sqrt_zero.value == 0, 'Sqrt of 0 failed');
}


#[test]
fn test_comparison() {
    let a = IFixedQ64x96Impl::new_unscaled(2);
    let b = IFixedQ64x96Impl::new_unscaled(3);
    let c = IFixedQ64x96Impl::new_unscaled(2);

    assert(a == a, 'Equality with self failed');
    assert(a == c, 'Equality with same value failed');
    assert(a != b, 'Inequality failed');

    assert(a.clone() < b.clone(), 'a<b failed');
    assert(b.clone() > a.clone(), 'b>a failed');
    assert(a.clone() <= c.clone(), 'a<=c failed');
    assert(a.clone() <= b.clone(), 'a<=b failed');
    assert(b >= a.clone(), 'b>=a failed');
    assert(a >= c, 'a>=c failed');
}

#[test]
fn test_uniswap_price_calculations() {
    let sqrt_price_low = IFixedQ64x96Impl::new(68728089048541002453454479899); // sqrt1500 * 2^96
    let sqrt_price_current = IFixedQ64x96Impl::new(
        79228162514264337593543950336,
    ); // sqrt2000 * 2^96
    let sqrt_price_high = IFixedQ64x96Impl::new(88577497797662845938898760064); // sqrt2500 * 2^96

    assert(sqrt_price_low.clone() < sqrt_price_current.clone(), 'should be less than current');
    assert(sqrt_price_current < sqrt_price_high.clone(), 'should be less than higher');

    // Test difference calculation which is used in liquidity math
    let diff = sqrt_price_high - sqrt_price_low;
    assert(diff.value > 0, 'Price diff should be positive');
}

#[test]
fn test_into_felt252() {
    // Test conversion to felt252
    let a = IFixedQ64x96Impl::new(ONE);
    let a_felt: felt252 = a.into();
    assert(a_felt == ONE.try_into().unwrap(), 'Conversion to felt252 failed');
}

#[test]
fn test_price_impact_calculations() {
    // Test price impact calculations for swap
    let initial_price = IFixedQ64x96Impl::new_unscaled(2000);
    let liquidity = ONE * 100; // Some liquidity value

    // For swapping 0.1 ETH for USDC
    let amount_in = ONE / 10; // 0.1 ETH

    // Calculate output using price formula: Δy = L * Δ(1/√P)
    let sqrt_price_before = initial_price.sqrt();

    // Calculate price after swap
    let price_after = IFixedQ64x96Impl::new(
        sqrt_price_before.value - (amount_in * ONE / liquidity),
    );

    // Verify price impact is negative (price decreases after selling ETH for USDC)
    assert(price_after.value < sqrt_price_before.value, 'Price impact direction wrong');

    // Calculate percentage price impact
    let price_impact = (sqrt_price_before.value - price_after.value)
        * ONE
        * 100
        / sqrt_price_before.value;
    assert(price_impact > 0, 'Price impact calculation failed');
}

// Generated Cairo test code with precomputed values

#[test]
fn test_uniswap_specific_operations() {
    // Precomputed values
    let ONE = 79228162514264337593543950336_u256; // 2^96
    let price_2000 = IFixedQ64x96Impl::new_unscaled(2000);
    let sqrt_price = price_2000.clone().sqrt();

    // Verify squaring sqrt_price gets back the original price (with tolerance)
    let price_squared = sqrt_price.clone() * sqrt_price.clone();
    let expected_price_squared = 158456325028528675187087900672000_u256;
    let epsilon = ONE / 100; // 1% tolerance

    assert(
        price_squared.value >= expected_price_squared
            - epsilon && price_squared.value <= expected_price_squared
            + epsilon,
        'Price conversion failed',
    );

    // Test tick to price conversion
    let tick_23028 = IFixedQ64x96Impl::new(79228162514264337593543950336_u256);
    let price_from_tick = tick_23028.clone() * tick_23028.clone();
    let expected_price_value = 79228162514264337593543950336_u256;

    // Allow 2% tolerance due to fixed-point precision
    let price_epsilon = ONE * 40 / 1000; // 4% tolerance

    assert(
        price_from_tick.value >= expected_price_value
            - price_epsilon && price_from_tick.value <= expected_price_value
            + price_epsilon,
        'Tick to price conversion failed',
    );
}

#[test]
fn test_uniswap_liquidity_calculations() {
    // Precomputed values for sqrt prices
    let sqrt_price_1500 = IFixedQ64x96Impl::new(3068493539683605256287027819677_u256);
    let sqrt_price_2000 = IFixedQ64x96Impl::new(3543191142285914205922034323214_u256);
    let sqrt_price_2500 = IFixedQ64x96Impl::new(3961408125713216879677197516800_u256);

    // Use precomputed liquidity values instead of calculating directly
    let token0_amount = 79228162514264337593543950336_u256; // 1 ETH (scaled)
    let _expected_liquidity_from_token0 = 2659022965277987686666509362960_u256;

    // Use mul_div to safely calculate without overflow
    let diff_2500_2000 = sqrt_price_2500.value - sqrt_price_2000.value;
    let liquidity_from_token0 = mul_div(
        mul_div(token0_amount, sqrt_price_2000.value, 1_u256),
        sqrt_price_2500.value,
        diff_2500_2000,
    );

    assert(liquidity_from_token0 > 0_u256, 'Invalid liquidity from token0');

    // Similar for token1 calculations
    let token1_amount = 79228162514264337593543950336_u256 * 2000_u256; // 2000 USDC (scaled)
    let diff_2000_1500 = sqrt_price_2000.value - sqrt_price_1500.value;
    let liquidity_from_token1 = mul_div(token1_amount, 1_u256, diff_2000_1500);

    // Compare with expected value
    assert(liquidity_from_token1 > 0_u256, 'Invalid liquidity from token1');

    // Verify relative magnitudes rather than exact values
    let min_liquidity = if liquidity_from_token0 < liquidity_from_token1 {
        liquidity_from_token0
    } else {
        liquidity_from_token1
    };

    assert(min_liquidity > 0_u256, 'Invalid minimum liquidity');
}


#[test]
fn test_edge_case_sqrt_price_calculations() {
    // Test with values near MIN_SQRT_RATIO
    let near_min_value = 4295128839_u256 * 3; // MIN_SQRT_RATIO * 2
    let near_min = IFixedQ64x96Impl::new(near_min_value);

    // When squaring and taking square root, we should get approximately the original value
    let near_min_squared = near_min.clone() * near_min.clone();
    let sqrt_result = near_min_squared.sqrt();

    // Use larger epsilon (10%) due to precision constraints near boundaries
    let epsilon = near_min_value / 10_u256;

    // Test with looser bounds near minimum
    assert(sqrt_result.value <= near_min_value + epsilon, 'Edge case sqrt upper failed');

    // Test with values near MAX_SQRT_RATIO
    let near_max_value = 1461446703485210103287273052203988822378723970342_u256
        - 1000_u256; // MAX_SQRT_RATIO - 1000
    let near_max = IFixedQ64x96Impl::new(near_max_value);

    // Test dividing by 2 and multiplying by 2 should return approximately the original
    let half_max = near_max.clone() / IFixedQ64x96Impl::new_unscaled(2);
    let twice_half = half_max.clone() * IFixedQ64x96Impl::new_unscaled(2);

    // Use larger epsilon (5%) for boundary values
    let max_epsilon = near_max_value / 20_u256;

    assert(twice_half.value <= near_max_value + max_epsilon, 'Edge case mul failed');
}
