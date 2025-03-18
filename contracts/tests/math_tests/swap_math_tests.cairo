// AUTO-GENERATED SWAP MATH TESTS
use contracts::libraries::math::numbers::fixed_point::FixedQ64x96;
use contracts::libraries::math::swap_math::SwapMath;

const MAX_I128: i128 = 170_141_183_460_469_231_731_687_303_715_884_105_727;


// Helper function for u256 comparisons with tolerance
fn is_within_tolerance(actual: u256, expected: u256, tolerance_percent: u8) -> bool {
    // For high-precision values, compare with appropriate tolerance
    let diff = if actual > expected {
        actual - expected
    } else {
        expected - actual
    };

    // Calculate tolerance as percentage of expected
    let tolerance_amount = (expected * tolerance_percent.into()) / 100_u256;
    // Ensure at least 1 for very small values
    let tolerance_amount = if tolerance_amount == 0_u256 {
        1_u256
    } else {
        tolerance_amount
    };

    diff <= tolerance_amount
}

#[test]
fn test_compute_swap_step_small_amount_0_to_1() {
    // Small swap: 0.1 ETH for USDC (token0 to token1)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3525430673841938992644797497344_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 100000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 647496913714050180118412835412_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 99999999999999999_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 36548799526311364129_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_small_amount_1_to_0() {
    // Small swap: 100,000 USDC for ETH (token1 to token0)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3560863028183068750138491011072_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 100000000000;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3560863028183068750138491011072_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 223050558492666084_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 110971800498655_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_large_amount_0_to_1() {
    // Large swap: 1 ETH for USDC (token0 to token1)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3361366258487168519347365740544_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 1000000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 77495314600421591368627405183_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 999999999999999999_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 43743231165578585391_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_large_amount_1_to_0() {
    // Large swap: 1,000,000 USDC for ETH (token1 to token0)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3716130220787573499654546915328_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 1000000000000;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3716130220787573499654546915328_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 2182798048238502985_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 1040608139436854_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_tiny_amount_0_to_1() {
    // Tiny swap: 0.00000001 ETH for USDC (token0 to token1)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3541419103594290470242341617664_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 10000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3541419103594290470242341617664_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 11188732136248_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 22366272741777493_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_tiny_amount_1_to_0() {
    // Tiny swap: 100 wei USDC for ETH (token1 to token0)
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3543368297414260802378862166016_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 100;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3543368297414260802378862166016_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 2236012078590476_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 1117950143185_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_small_liquidity_0_to_1() {
    // Swap with very small liquidity: 0.001 ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 2505414483750479251915866636288_u256 };
    let liquidity: u128 = 1000000;
    let amount_remaining: i128 = 1000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 79228162512492742201_u256, 5),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 999999999999999_u256, 5), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 44721359_u256, 5), 'incorrect amount_out');
}

#[test]
#[should_panic(expected: 'invalid liquidity')]
fn test_compute_swap_step_zero_liquidity_0_to_1() {
    // Swap with zero liquidity: 0.001 ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3361366258487168519347365740544_u256 };
    let liquidity: u128 = 0;
    let amount_remaining: i128 = 1000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3361366258487168519347365740544_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 0_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 0_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_exact_target_0_to_1() {
    // Exact amount to hit target price: ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3453475538820956351120541745152_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 580893612058279;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3453475538820956351120541745152_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 580893612058279_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 1132370114589058118_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_exact_target_1_to_0() {
    // Exact amount to hit target price: USDC for ETH
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3630690518938791009824477806592_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 1104397399562600412;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 3630690518938791009824477806592_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 1104397399562600412_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 538890751398656_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_huge_amount_0_to_1() {
    // Huge swap amount that should hit target: ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3543191142285914378072636784640_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3169126500570573503741758013440_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 10000000000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 7922798535510336322461787_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 9999999999999999999999_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 44721259550219402398_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_near_min_price_0_to_1() {
    // Swap near minimum price boundary: ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 8590257478_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 4295129739_u256 };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 100000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 4295129739_u256, 5),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(
        is_within_tolerance(amount_in, 9223021059040194714162263759192066728_u256, 5),
        'incorrect amount_in',
    );

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 0_u256, 5), 'incorrect amount_out');
}

#[test]
#[should_panic(expected: 'sqrt ratio overflow')]
fn test_compute_swap_step_near_max_price_1_to_0() {
    // Swap near maximum price boundary: USDC for ETH
    let sqrt_ratio_current_x96 = FixedQ64x96 {
        value: 1461446703485210103287273052203988822378723960342_u256,
    };
    let sqrt_ratio_target_x96 = FixedQ64x96 {
        value: 1461446703485210103287273052203988822378723970242_u256,
    };
    let liquidity: u128 = 1000000000000000000;
    let amount_remaining: i128 = 10000000000000000000000000;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(
            sqrt_ratio_next_x96.value, 1461446703486002384912415695579924261882083960342_u256, 5,
        ),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(
        is_within_tolerance(amount_in, 10000000000000000000000000_u256, 5), 'incorrect amount_in',
    );

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 0_u256, 5), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_realistic_eth_usdc_0_to_1() {
    // Realistic ETH/USDC swap: 2 ETH for USDC
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 3408422807805231855983812149248_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 3382763049079169006825398861824_u256 };
    let liquidity: u128 = 50000000000000000000;
    let amount_remaining: i128 = 2000000000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 1252721835165081202800404475337_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 1999999999999999999_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 1360438576530179877998_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_stablecoin_pair_0_to_1() {
    // Stablecoin pair swap: USDC/DAI with minimal price impact
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 79267766696949822870343647232_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 79247967079631607932580265984_u256 };
    let liquidity: u128 = 10000000000000000000000;
    let amount_remaining: i128 = 100000000000000;
    let zero_for_one: bool = true;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 79247967079631607932580265984_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 2497190231813117171_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 2499063046508265273_u256, 1), 'incorrect amount_out');
}

#[test]
fn test_compute_swap_step_high_volatility_pair_1_to_0() {
    // High volatility token pair: SHIB for ETH with large price impact
    let sqrt_ratio_current_x96 = FixedQ64x96 { value: 560227709747861407246843904_u256 };
    let sqrt_ratio_target_x96 = FixedQ64x96 { value: 613698707936721050850557952_u256 };
    let liquidity: u128 = 10000000000000000;
    let amount_remaining: i128 = 100000000000000000000;
    let zero_for_one: bool = false;

    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one,
    );

    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 792282185370353123796846750203904_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 100000000000000000000_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - using absolute value comparison
    assert(is_within_tolerance(amount_out, 1414212562373802134_u256, 1), 'incorrect amount_out');
}
