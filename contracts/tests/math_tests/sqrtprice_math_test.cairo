use contracts::libraries::math::sqrtprice_math::SqrtPriceMath;
use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};


// --- Cairo Test Code for get_next_sqrt_price_from_amount0_rounding_up --- //
#[test]
fn test_get_next_sqrt_price_from_amount0_zero_amount() {
    // Test price calculation when adding token0
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 0_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 79228162514264337593543950336_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount0_adding_token0() {
    // Test price calculation when adding token0
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 100000000000000000_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 7922024049021531606193775_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount0_removing_token0() {
    // Test price calculation when removing token0
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 8000000000000_u256;
    let add = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 396140812571321687967719751680_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount0_real_example() {
    // Test price calculation when adding token0
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount = 1000000000000000000_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount0_rounding_up(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 633825139767628305526620771_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

// --- Cairo Test Code for get_next_sqrt_price_from_amount1_rounding_down --- //
#[test]
fn test_get_next_sqrt_price_from_amount1_zero_amount() {
    // Test price calculation when adding token1
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 0_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount1_rounding_down(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 79228162514264337593543950336_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount1_adding_token1() {
    // Test price calculation when adding token1
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 100000000000000000_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount1_rounding_down(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 792360853305157640273033047310336_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount1_removing_token1() {
    // Test price calculation when removing token1
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount = 7999999999999_u256;
    let add = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount1_rounding_down(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 15845632502860790334960216501_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_amount1_real_example() {
    // Test price calculation when adding token1
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount = 2000000000_u256;
    let add = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_amount1_rounding_down(
        sqrt_price_x96.clone(), liquidity, amount, add
    );

    let expected = 2505414483770286352492704099597171_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

// --- Cairo Test Code for get_next_sqrt_price_from_input --- //
#[test]
fn test_get_next_sqrt_price_from_input_token0() {
    // Test price calculation for token0 input
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount_in = 100000000000000000_u256;
    let zero_for_one = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_input(
        sqrt_price_x96.clone(), liquidity, amount_in, zero_for_one
    );

    let expected = 7922024049021531606193775_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_input_token1() {
    // Test price calculation for token1 input
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount_in = 100000000000000000_u256;
    let zero_for_one = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_input(
        sqrt_price_x96.clone(), liquidity, amount_in, zero_for_one
    );

    let expected = 792360853305157640273033047310336_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_input_eth_to_usdc() {
    // Test price calculation for token0 input
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount_in = 500000000000000000_u256;
    let zero_for_one = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_input(
        sqrt_price_x96.clone(), liquidity, amount_in, zero_for_one
    );

    let expected = 1267649958842446079763463034_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_input_usdc_to_eth() {
    // Test price calculation for token1 input
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount_in = 1000000000_u256;
    let zero_for_one = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_input(
        sqrt_price_x96.clone(), liquidity, amount_in, zero_for_one
    );

    let expected = 2505414483760382832178421057397978_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

// --- Cairo Test Code for get_next_sqrt_price_from_output --- //
#[test]
fn test_get_next_sqrt_price_from_output_token1_out() {
    // Test price calculation for token1 output
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount_out = 999999999999_u256;
    let zero_for_one = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_output(
        sqrt_price_x96.clone(), liquidity, amount_out, zero_for_one
    );

    let expected = 71305346262845826650440981737_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_output_token0_out() {
    // Test price calculation for token0 output
    let sqrt_price_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let liquidity = 10000000000000_u128;
    let amount_out = 1000000000000_u256;
    let zero_for_one = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_output(
        sqrt_price_x96.clone(), liquidity, amount_out, zero_for_one
    );

    let expected = 88031291682515930659493278151_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}


// <!IMPORTANT!> TODO: Make this test pass by fixing the overflow handling! in the libraries/math/fullmath.cairo
#[test]
fn test_get_next_sqrt_price_from_output_exact_eth_out() {
    // Test price calculation for token0 output
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount_out = 25298221281_u256;
    let zero_for_one = false;

    let result = SqrtPriceMath::get_next_sqrt_price_from_output(
        sqrt_price_x96.clone(), liquidity, amount_out, zero_for_one
    );

    let expected = 2783793870829622859151062823560918_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}

#[test]
fn test_get_next_sqrt_price_from_output_exact_usdc_out() {
    // Test price calculation for token1 output
    let sqrt_price_x96 = FixedQ64x96 { value: 2505414483750479311864138015198786_u256 };
    let liquidity = 8000000000000000_u128;
    let amount_out = 500000000_u256;
    let zero_for_one = true;

    let result = SqrtPriceMath::get_next_sqrt_price_from_output(
        sqrt_price_x96.clone(), liquidity, amount_out, zero_for_one
    );

    let expected = 2505414483745527551706996494099190_u256;
    let tolerance = expected / 10000_u256; // 0.01% tolerance
    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, 
        'Price calculation incorrect');
}