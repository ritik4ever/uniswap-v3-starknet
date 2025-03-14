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
