use contracts::libraries::math::fullmath::full_math;

#[test]
fn test_mul_div_basic() {
    let result = full_math::mul_div(10_u256, 20_u256, 5_u256);
    assert_eq!(result, 40_u256);

    let result = full_math::mul_div(10_u256, 20_u256, 3_u256);
    assert_eq!(result, 66_u256);

    let result = full_math::mul_div(0_u256, 20_u256, 5_u256);
    assert_eq!(result, 0_u256);
}

#[test]
fn test_mul_div_large_numbers() {
    let a = 0xFFFFFFFFFFFFFFFF_u256; // Max u64
    let b = 2_u256;
    let denominator = 3_u256;

    let expected = (a * b) / denominator;
    let result = full_math::mul_div(a, b, denominator);
    assert_eq!(result, expected);
}

#[test]
#[should_panic(expected: 'division by zero')]
fn test_mul_div_division_by_zero() {
    // Should panic with 'division by zero'
    full_math::mul_div(10_u256, 20_u256, 0_u256);
}

#[test]
fn test_mul_div_rounding_up_basic() {
    // Simple case: (10 * 20) / 5 = 40
    let result = full_math::mul_div_rounding_up(10_u256, 20_u256, 5_u256);
    assert_eq!(result, 40_u256);

    let result = full_math::mul_div_rounding_up(10_u256, 20_u256, 3_u256);
    assert_eq!(result, 67_u256);

    let result = full_math::mul_div_rounding_up(9_u256, 3_u256, 3_u256);
    assert_eq!(result, 9_u256);
}

#[test]
#[should_panic(expected: 'division by zero')]
fn test_mul_div_rounding_up_division_by_zero() {
    full_math::mul_div_rounding_up(10_u256, 20_u256, 0_u256);
}

#[test]
fn test_div_rounding_up_basic() {
    let result = full_math::div_rounding_up(20_u256, 5_u256);
    assert_eq!(result, 4_u256);

    let result = full_math::div_rounding_up(21_u256, 5_u256);
    assert_eq!(result, 5_u256);

    let result = full_math::div_rounding_up(20_u256, 4_u256);
    assert_eq!(result, 5_u256);
}

#[test]
#[should_panic(expected: 'division by zero')]
fn test_div_rounding_up_division_by_zero() {
    full_math::div_rounding_up(10_u256, 0_u256);
}

#[test]
fn test_edge_cases() {
    let large = 0xffffffffffffffffffffffffffffffff_u256;
    let result = full_math::mul_div(large, 2_u256, 2_u256);
    assert_eq!(result, large);

    let result = full_math::mul_div_rounding_up(100_u256, 10_u256, 10_u256);
    assert_eq!(result, 100_u256);

    let result = full_math::div_rounding_up(9_u256, 5_u256);
    assert_eq!(result, 2_u256);
}

#[test]
fn test_mul_div_with_zero_numerator() {
    let result = full_math::mul_div(0_u256, 20_u256, 5_u256);
    assert_eq!(result, 0_u256);
}

#[test]
fn test_mul_div_rounding_up_edge_case() {
    let result = full_math::mul_div_rounding_up(11_u256, 2_u256, 2_u256);
    assert_eq!(result, 11_u256);

    let result = full_math::mul_div_rounding_up(9_u256, 2_u256, 2_u256);
    assert_eq!(result, 9_u256);
}

#[test]
fn test_div_rounding_up_with_zero() {
    let result = full_math::div_rounding_up(0_u256, 5_u256);
    assert_eq!(result, 0_u256);
}

#[test]
fn test_mul_div_with_larger_denominator() {
    let result = full_math::mul_div(10_u256, 20_u256, 100_u256);
    assert_eq!(result, 2_u256);
}

#[test]
fn test_mul_div_rounding_up_with_larger_denominator() {
    let result = full_math::mul_div_rounding_up(9_u256, 3_u256, 10_u256);
    assert_eq!(result, 3_u256);
}

#[test]
fn test_mul_div_with_max_u256_values() {
    let a = 0xFFFFFFFFFFFFFFFF_u256;
    let b = 0xFFFFFFFFFFFFFFFE_u256;
    let denominator = 2_u256;

    let expected = (a * b) / denominator;
    let result = full_math::mul_div(a, b, denominator);
    assert_eq!(result, expected);
}

#[test]
fn test_mul_div_rounding_up_with_max_u256() {
    let a = 0xFFFFFFFFFFFFFFFF_u256;
    let b = 0xFFFFFFFFFFFFFFFE_u256;
    let denominator = 2_u256;

    let expected = (a * b) / denominator;
    let result = full_math::mul_div_rounding_up(a, b, denominator);
    assert_eq!(result, expected);
}

#[test]
fn test_div_rounding_up_with_large_numbers() {
    let a = 0x123456789ABCDEF_u256;
    let denominator = 0x0000000000000002;
    let expected = (a + denominator - 1) / denominator;
    let result = full_math::div_rounding_up(a, denominator);
    assert_eq!(result, expected);
}

#[test]
fn test_div_rounding_up_max_value() {
    let a = u256 { low: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF_u128, high: 0 };
    let denominator = 3_u256;
    let div_result = a / denominator;
    let remainder = a % denominator;
    let expected = if remainder > 0_u256 {
        div_result + 1_u256
    } else {
        div_result
    };

    let result = full_math::div_rounding_up(a, denominator);
    assert_eq!(result, expected);
}

#[test]
fn test_div_rounding_up_rounding_behavior() {
    let a = 10_u256;
    let denominator = 3_u256;
    let result = full_math::div_rounding_up(a, denominator);
    assert_eq!(result, 4_u256); // 10/3 = 3.33... rounds to 4

    // Case with exact division
    let a = 10_u256;
    let denominator = 5_u256;
    let result = full_math::div_rounding_up(a, denominator);
    assert_eq!(result, 2_u256); // 10/5 = 2 exactly
}

#[test]
fn test_div_rounding_up_small_denominator() {
    // Testing division by 1
    let a = 0xFFFFFFFFFFFFFFFF_u256;
    let denominator = 1_u256;
    let result = full_math::div_rounding_up(a, denominator);
    assert_eq!(result, a);
}

#[test]
fn test_div_rounding_up_boundary_values() {
    // Test with odd/even values
    let result1 = full_math::div_rounding_up(7_u256, 2_u256);
    assert_eq!(result1, 4_u256); // 7/2 = 3.5 rounds to 4

    let result2 = full_math::div_rounding_up(8_u256, 2_u256);
    assert_eq!(result2, 4_u256); // 8/2 = 4 exactly
}
