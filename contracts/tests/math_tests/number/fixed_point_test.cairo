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
