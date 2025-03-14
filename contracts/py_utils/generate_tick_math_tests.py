from utils import q96
import math

# Constants from the original Uniswap V3 implementation
MIN_TICK = -887272
MAX_TICK = 887272
MIN_SQRT_RATIO = 4295128739
MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342

def tick_to_sqrt_ratio(tick):
    """Calculates sqrt(1.0001^tick) * 2^96"""
    assert MIN_TICK <= tick <= MAX_TICK, f"Tick {tick} out of bounds"
    abs_tick = abs(tick)
    
    # Start with the base value
    ratio = 0xfffcb933bd6fad37aa2d162d1a594001 if abs_tick & 0x1 else 0x100000000000000000000000000000000
    
    # Apply each bit adjustment
    if abs_tick & 0x2: ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128
    if abs_tick & 0x4: ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128
    if abs_tick & 0x8: ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128
    if abs_tick & 0x10: ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128
    if abs_tick & 0x20: ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128
    if abs_tick & 0x40: ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128
    if abs_tick & 0x80: ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128
    if abs_tick & 0x100: ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128
    if abs_tick & 0x200: ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128
    if abs_tick & 0x400: ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128
    if abs_tick & 0x800: ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128
    if abs_tick & 0x1000: ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128
    if abs_tick & 0x2000: ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128
    if abs_tick & 0x4000: ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128
    if abs_tick & 0x8000: ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128
    if abs_tick & 0x10000: ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128
    if abs_tick & 0x20000: ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128
    if abs_tick & 0x40000: ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128
    if abs_tick & 0x80000: ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128
    
    # Invert if tick is positive
    if tick > 0:
        ratio = (2**256 - 1) // ratio
    
    # Convert to Q64.96
    sqrt_ratio_x96 = (ratio >> 32) + (1 if ratio % (1 << 32) else 0)
    
    return sqrt_ratio_x96

def sqrt_ratio_to_tick(sqrt_ratio_x96):
    """Calculates the greatest tick such that tick_to_sqrt_ratio(tick) <= sqrt_ratio_x96"""
    assert MIN_SQRT_RATIO <= sqrt_ratio_x96 < MAX_SQRT_RATIO, f"Sqrt ratio {sqrt_ratio_x96} out of bounds"
    
    # This is an approximation, as the full algorithm is complex to reproduce in Python
    price = (sqrt_ratio_x96 / q96) ** 2
    tick_low = math.floor(math.log(price, 1.0001))
    tick_high = tick_low + 1
    
    # Verify and adjust if needed
    if tick_to_sqrt_ratio(tick_high) <= sqrt_ratio_x96:
        return tick_high
    return tick_low

def format_tick_for_function_name(tick):
    """Format tick value for use in function name, avoiding invalid characters"""
    if tick < 0:
        return f"negative_{abs(tick)}"
    return str(tick)

def generate_tick_to_sqrt_ratio_test_cases():
    """Generate test cases for get_sqrt_ratio_at_tick"""
    test_cases = []
    
    # Test MIN_TICK
    test_cases.append({
        'name': f"min_tick",
        'tick': MIN_TICK,
        'expected': MIN_SQRT_RATIO
    })
    
    # Test MAX_TICK
    test_cases.append({
        'name': f"max_tick",
        'tick': MAX_TICK,
        'expected': MAX_SQRT_RATIO
    })
    
    # Test 0 tick
    test_cases.append({
        'name': f"zero_tick",
        'tick': 0,
        'expected': tick_to_sqrt_ratio(0)
    })
    
    # Test some common price levels
    for tick in [-100, 100, 1000, 10000, 50000, -50000]:
        test_cases.append({
            'name': f"tick_{format_tick_for_function_name(tick)}",
            'tick': tick,
            'expected': tick_to_sqrt_ratio(tick)
        })
    
    return test_cases

def generate_sqrt_ratio_to_tick_test_cases():
    """Generate test cases for get_tick_at_sqrt_ratio"""
    test_cases = []
    
    # Test MIN_SQRT_RATIO
    test_cases.append({
        'name': f"min_sqrt_ratio",
        'sqrt_ratio_x96': MIN_SQRT_RATIO,
        'expected': MIN_TICK
    })
    
    # Test just under MAX_SQRT_RATIO
    test_cases.append({
        'name': f"near_max_sqrt_ratio",
        'sqrt_ratio_x96': MAX_SQRT_RATIO - 1,
        'expected': MAX_TICK
    })
    
    # Test 1.0 price (sqrt_ratio = 2^96)
    test_cases.append({
        'name': f"unit_price",
        'sqrt_ratio_x96': q96,
        'expected': 0
    })
    
    # Test some common price levels
    for tick in [-100, 100, 1000, 10000, 50000, -50000]:
        sqrt_ratio = tick_to_sqrt_ratio(tick)
        test_cases.append({
            'name': f"from_tick_{format_tick_for_function_name(tick)}",
            'sqrt_ratio_x96': sqrt_ratio,
            'expected': tick
        })
    
    return test_cases

def print_tick_to_sqrt_ratio_test_code(test_cases):
    """Generate Cairo test code for get_sqrt_ratio_at_tick function"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_sqrt_ratio_at_tick_{case['name']}() {{")
        print(f"    let tick = {case['tick']}_i32;")
        print(f"    let result = TickMath::get_sqrt_ratio_at_tick(tick);")
        print(f"")
        print(f"    println!(\"Result sqrt_ratio: {{}}\", result.value);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    assert(result.value == expected, 'get_sqrt_ratio_at_tick failed');")
        print(f"}}\n")

def print_sqrt_ratio_to_tick_test_code(test_cases):
    """Generate Cairo test code for get_tick_at_sqrt_ratio function"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_tick_at_sqrt_ratio_{case['name']}() {{")
        print(f"    let sqrt_ratio_x96 = FixedQ64x96 {{ value: {case['sqrt_ratio_x96']}_u256 }};")
        print(f"    let result = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio_x96);")
        print(f"")
        print(f"    println!(\"Result tick: {{}}\", result);")
        print(f"    let expected = {case['expected']}_i32;")
        print(f"    assert(result == expected, 'get_tick_at_sqrt_ratio failed');")
        print(f"}}\n")

def generate_roundtrip_test_cases():
    """Generate test cases for roundtrip conversion (tick → sqrt_ratio → tick)"""
    test_cases = []
    
    for tick in [MIN_TICK, -100000, -10000, -100, 0, 100, 10000, 100000, MAX_TICK]:
        sqrt_ratio = tick_to_sqrt_ratio(tick)
        test_cases.append({
            'name': f"roundtrip_tick_{format_tick_for_function_name(tick)}",
            'tick': tick,
            'sqrt_ratio_x96': sqrt_ratio
        })
    
    return test_cases

def print_roundtrip_test_code(test_cases):
    """Generate Cairo test code for roundtrip conversion"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_{case['name']}() {{")
        print(f"    // Test roundtrip: tick → sqrt_ratio → tick")
        print(f"    let original_tick = {case['tick']}_i32;")
        print(f"    let sqrt_ratio = TickMath::get_sqrt_ratio_at_tick(original_tick);")
        print(f"    let result_tick = TickMath::get_tick_at_sqrt_ratio(sqrt_ratio.clone());")
        print(f"")
        print(f"    println!(\"Original tick: {{}}, sqrt_ratio: {{}}, result tick: {{}}\", original_tick, sqrt_ratio.value, result_tick);")
        print(f"    assert(result_tick == original_tick, 'Roundtrip conversion failed');")
        print(f"}}\n")

def main():
    print("use contracts::libraries::math::tick_math::TickMath;\nuse contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};\n\n")
    print("// --- Cairo Test Code for get_sqrt_ratio_at_tick --- //")
    tick_cases = generate_tick_to_sqrt_ratio_test_cases()
    print_tick_to_sqrt_ratio_test_code(tick_cases)
    
    print("// --- Cairo Test Code for get_tick_at_sqrt_ratio --- //")
    sqrt_ratio_cases = generate_sqrt_ratio_to_tick_test_cases()
    print_sqrt_ratio_to_tick_test_code(sqrt_ratio_cases)
    
    print("// --- Cairo Test Code for roundtrip conversion --- //")
    roundtrip_cases = generate_roundtrip_test_cases()
    print_roundtrip_test_code(roundtrip_cases)

if __name__ == "__main__":
    main()
