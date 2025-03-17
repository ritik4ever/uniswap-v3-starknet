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

    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, 647496913714050180118412835412_u256, 1),
        'incorrect sqrt_ratio_next_x96',
    );

    // Check amount_in with tolerance
    assert(is_within_tolerance(amount_in, 99999999999999999_u256, 1), 'incorrect amount_in');

    // Check amount_out with tolerance - use absolute value since amount_out is conceptually
    // negative
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

    // Check amount_out with tolerance - use absolute value since amount_out is conceptually
    // negative
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

    // Check amount_out with tolerance - use absolute value since amount_out is conceptually
    // negative
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

    // Check amount_out with tolerance - use absolute value since amount_out is conceptually
    // negative
    assert(is_within_tolerance(amount_out, 1040608139436854_u256, 1), 'incorrect amount_out');
}
