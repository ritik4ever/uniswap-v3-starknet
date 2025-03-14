import math

q96 = 2**96

def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))

def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)

def calc_amount0(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * q96 * (pb - pa) / pa / pb)

def calc_amount1(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * (pb - pa) / q96)

def generate_calc_amount0_test_cases():
    """Generate test cases for calc_amount0"""
    test_cases = []
    
    # Case 1: Basic test with sqrt price ~1 and ~2
    price_a = 1.0
    price_b = 2.0
    liquidity = 1000000
    sqrtp_a = price_to_sqrtp(price_a)
    sqrtp_b = price_to_sqrtp(price_b)
    expected = calc_amount0(liquidity, sqrtp_a, sqrtp_b)
    test_cases.append({
        'name': 'basic_case',
        'sqrtp_a': sqrtp_a,
        'sqrtp_b': sqrtp_b,
        'liquidity': liquidity,
        'expected': expected
    })
    
    # Case 2: Inverted prices
    expected = calc_amount0(liquidity, sqrtp_b, sqrtp_a)
    test_cases.append({
        'name': 'inverted_case',
        'sqrtp_a': sqrtp_b,
        'sqrtp_b': sqrtp_a,
        'liquidity': liquidity,
        'expected': expected
    })
    
    # Case 3: ETH/USDC example with price range 1500-2500
    sqrtp_low = price_to_sqrtp(1500)
    sqrtp_high = price_to_sqrtp(2500)
    liquidity = 2 * 10**18  # 2 ETH worth
    expected = calc_amount0(liquidity, sqrtp_low, sqrtp_high)
    test_cases.append({
        'name': 'eth_usdc_range',
        'sqrtp_a': sqrtp_low,
        'sqrtp_b': sqrtp_high,
        'liquidity': liquidity,
        'expected': expected
    })
    
    return test_cases

def generate_calc_amount1_test_cases():
    """Generate test cases for calc_amount1"""
    test_cases = []
    
    # Case 1: Basic test with sqrt price ~1 and ~2
    price_a = 1.0
    price_b = 2.0
    liquidity = 1000000
    sqrtp_a = price_to_sqrtp(price_a)
    sqrtp_b = price_to_sqrtp(price_b)
    expected = calc_amount1(liquidity, sqrtp_a, sqrtp_b)
    test_cases.append({
        'name': 'basic_case',
        'sqrtp_a': sqrtp_a,
        'sqrtp_b': sqrtp_b,
        'liquidity': liquidity,
        'expected': expected
    })
    
    # Case 2: Inverted prices
    expected = calc_amount1(liquidity, sqrtp_b, sqrtp_a)
    test_cases.append({
        'name': 'inverted_case',
        'sqrtp_a': sqrtp_b,
        'sqrtp_b': sqrtp_a,
        'liquidity': liquidity,
        'expected': expected
    })
    
    # Case 3: ETH/USDC example with price range 1500-2500
    sqrtp_low = price_to_sqrtp(1500)
    sqrtp_high = price_to_sqrtp(2500)
    liquidity = 2 * 10**18  # 2 ETH worth
    expected = calc_amount1(liquidity, sqrtp_low, sqrtp_high)
    test_cases.append({
        'name': 'eth_usdc_range',
        'sqrtp_a': sqrtp_low,
        'sqrtp_b': sqrtp_high,
        'liquidity': liquidity,
        'expected': expected
    })
    
    return test_cases

def print_cairo_test_code(test_cases, function_name):
    """Generate Cairo test code from test cases"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_{function_name}_{case['name']}() {{")
        print(f"    // Create sqrt prices")
        print(f"    let sqrt_price_a = IFixedQ64x96Impl::new({case['sqrtp_a']}_u256);")
        print(f"    let sqrt_price_b = IFixedQ64x96Impl::new({case['sqrtp_b']}_u256);")
        print(f"    let liquidity = {case['liquidity']}_u128;")
        print(f"")
        print(f"    let result = LiquidityMath::{function_name}(sqrt_price_a, sqrt_price_b, liquidity);")
        print(f"")
        print(f"    println!(\"Result: {{}}\", result);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    let tolerance = expected / 100_u256; // 1% tolerance")
        print(f"    assert(result >= expected - tolerance && result <= expected + tolerance, \'{function_name} incorrect\');")
        print(f"}}\n")

def generate_swap_test_case():
    """Generate a test case for swap calculation"""
    eth = 10**18
    current_sqrtp = 5602277097478614198912276234240
    liquidity = 1517882343751509868544
    amount_in = 42 * eth  # 42 USDC
    
    price_diff = (amount_in * q96) // liquidity
    price_next = current_sqrtp + price_diff
    
    amount_in_calculated = calc_amount1(liquidity, price_next, current_sqrtp)
    amount_out_calculated = calc_amount0(liquidity, price_next, current_sqrtp)
    
    print(f"#[test]")
    print(f"fn test_swap_calculation() {{")
    print(f"    // Test swapping 42 USDC for ETH")
    print(f"    let current_sqrtp = FixedQ64x96 {{ value: {current_sqrtp}_u256 }};")
    print(f"    let liquidity = {liquidity}_u128;")
    print(f"    let amount_in = {amount_in}_u128;  // 42 USDC")
    print(f"")
    print(f"    // Calculate price impact")
    print(f"    let price_diff = (amount_in.into() * ONE) / liquidity.into();")
    print(f"    let price_next = FixedQ64x96 {{ value: current_sqrtp.value + price_diff }};")
    print(f"")
    print(f"    // Verify expected values")
    print(f"    let expected_price_next = {price_next}_u256;")
    print(f"    println!(\"Price next: {{}}, Expected: {{}}\", price_next.value, expected_price_next);")
    print(f"    assert(price_next.value >= expected_price_next - 100 && price_next.value <= expected_price_next + 100, \'Price calculation incorrect\');")
    print(f"")
    print(f"    // Calculate amounts")
    print(f"    let amount_in_calculated = LiquidityMath::calc_amount1_delta(current_sqrtp, price_next, liquidity);")
    print(f"    let amount_out_calculated = LiquidityMath::calc_amount0_delta(current_sqrtp, price_next, liquidity);")
    print(f"")
    print(f"    // Verify calculated amounts")
    print(f"    let expected_amount_in = {amount_in_calculated}_u256;  // 42 USDC")
    print(f"    let expected_amount_out = {amount_out_calculated}_u256;  // ~0.0084 ETH")
    print(f"    println!(\"Amount in calculated: {{}}, Expected: {{}}\", amount_in_calculated, expected_amount_in);")
    print(f"    println!(\"Amount out calculated: {{}}, Expected: {{}}\", amount_out_calculated, expected_amount_out);")
    print(f"")
    print(f"    let tolerance_in = expected_amount_in / 100_u256;  // 1% tolerance")
    print(f"    let tolerance_out = expected_amount_out / 100_u256;  // 1% tolerance")
    print(f"    assert(amount_in_calculated >= expected_amount_in - tolerance_in && amount_in_calculated <= expected_amount_in + tolerance_in, \'Amount in calculation incorrect\');")
    print(f"    assert(amount_out_calculated >= expected_amount_out - tolerance_out && amount_out_calculated <= expected_amount_out + tolerance_out, \'Amount out calculation incorrect\');")
    print(f"}}")

def print_test_values():
    """Print exact test values for all test cases"""
    # Basic test values
    price_a = 1.0
    price_b = 2.0
    liquidity = 1000000
    sqrtp_a = price_to_sqrtp(price_a)
    sqrtp_b = price_to_sqrtp(price_b)
    
    print("// Test values for basic case:")
    print(f"// sqrtp_a = {sqrtp_a}")
    print(f"// sqrtp_b = {sqrtp_b}")
    print(f"// liquidity = {liquidity}")
    print(f"// expected_amount0 = {calc_amount0(liquidity, sqrtp_a, sqrtp_b)}")
    print(f"// expected_amount1 = {calc_amount1(liquidity, sqrtp_a, sqrtp_b)}")
    print()
    
    # ETH/USDC example
    sqrtp_low = price_to_sqrtp(1500)
    sqrtp_high = price_to_sqrtp(2500)
    liquidity = 2 * 10**18  # 2 ETH worth
    
    print("// Test values for ETH/USDC range:")
    print(f"// sqrtp_low = {sqrtp_low}")
    print(f"// sqrtp_high = {sqrtp_high}")
    print(f"// liquidity = {liquidity}")
    print(f"// expected_amount0 = {calc_amount0(liquidity, sqrtp_low, sqrtp_high)}")
    print(f"// expected_amount1 = {calc_amount1(liquidity, sqrtp_low, sqrtp_high)}")
