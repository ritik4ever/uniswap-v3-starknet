use contracts::libraries::math::tick_math::TickMath;
use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};


// --- Cairo Test Code for get_sqrt_ratio_at_tick --- //
#[test]
fn test_get_sqrt_ratio_at_tick_min_tick() {
    let tick = -887272_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 4295128739_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_max_tick() {
    let tick = 887271_i32; // MAX_TICK - 1
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 1461373636630004318706518188784493106690254656249_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_zero_tick() {
    let tick = 0_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 79228162514264337593543950336_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_negative_100() {
    let tick = -100_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 78833030112140176575862854579_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_100() {
    let tick = 100_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 79625275426524748796330556128_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_1000() {
    let tick = 1000_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 83290069058676223003182343270_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_10000() {
    let tick = 10000_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 130621891405341611593710811006_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_50000() {
    let tick = 50000_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 965075977353221155028623082916_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

#[test]
fn test_get_sqrt_ratio_at_tick_tick_negative_50000() {
    let tick = -50000_i32;
    let result = TickMath::get_sqrt_ratio_at_tick(tick);

    let expected = 6504256538020985011912221507_u256;
    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');
}

// --- Cairo Test Code for get_tick_at_sqrt_ratio --- //
#[test]
fn test_get_tick_at_sqrt_ratio_min_sqrt_ratio() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 4295128739_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = -887272_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_near_max_sqrt_ratio() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 1461446703485210103287273052203988822378723970341_u256 - 6895660000000000000000000000000000000000000 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 887272_i32 - 1;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_unit_price() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 79228162514264337593543950336_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 0_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_negative_100() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 78833030112140176575862854579_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = -100_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_100() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 79625275426524748796330556128_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 100_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_1000() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 83290069058676223003182343270_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 1000_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_10000() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 130621891405341611593710811006_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 10000_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_50000() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 965075977353221155028623082916_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = 50000_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

#[test]
fn test_get_tick_at_sqrt_ratio_from_tick_negative_50000() {
    let sqrt_ratio_x96 = FixedQ64x96 { value: 6504256538020985011912221507_u256 };
    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);

    let expected = -50000_i32;
    assert(result == expected, 'get_tick_at_sqrt_ratio failed');
}

// --- Cairo Test Code for roundtrip conversion --- //
#[test]
fn test_roundtrip_tick_negative_887272() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = -887272_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_negative_100000() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = -100000_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_negative_10000() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = -10000_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_negative_100() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = -100_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_0() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = 0_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_100() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = 100_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_10000() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = 10000_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_100000() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = 100000_i32;
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}

#[test]
fn test_roundtrip_tick_887271() {
    // Test roundtrip: tick → sqrt_ratio → tick
    let original_tick = 887271_i32; // MAX_TICK - 1
    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);
    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());

    assert(result_tick == original_tick, 'Roundtrip conversion failed');
}
