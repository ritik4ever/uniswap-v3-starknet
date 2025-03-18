from uniswap_v3_math import price_to_tick, price_to_sqrtp, calc_amount0, calc_amount1, q96

def generate_mint_test_values(current_price, lower_price, upper_price, liquidity_amount):
    """
    Generates expected values for mint test from given parameters.
    Returns a dictionary with all necessary test values.
    """
    # Convert prices to ticks and sqrt prices
    current_tick = price_to_tick(current_price)
    lower_tick = price_to_tick(lower_price)
    upper_tick = price_to_tick(upper_price)
    
    # Ensure ticks are on spacing boundaries (assuming tick spacing of 1 for simplicity)
    # If using other tick spacing, adjust accordingly
    tick_spacing = 1
    lower_tick = (lower_tick // tick_spacing) * tick_spacing
    upper_tick = (upper_tick // tick_spacing) * tick_spacing
    
    current_sqrt_price = price_to_sqrtp(current_price)
    lower_sqrt_price = price_to_sqrtp(lower_price)
    upper_sqrt_price = price_to_sqrtp(upper_price)
    
    # Calculate expected token amounts based on current price position
    amount0 = 0
    amount1 = 0
    
    if current_tick < lower_tick:
        # Current price is below range, only token0 needed
        amount0 = calc_amount0(liquidity_amount, lower_sqrt_price, upper_sqrt_price)
        amount1 = 0
    elif current_tick < upper_tick:
        # Current price is in range, both tokens needed
        amount0 = calc_amount0(liquidity_amount, current_sqrt_price, upper_sqrt_price)
        amount1 = calc_amount1(liquidity_amount, lower_sqrt_price, current_sqrt_price)
    else:
        # Current price is above range, only token1 needed
        amount0 = 0
        amount1 = calc_amount1(liquidity_amount, lower_sqrt_price, upper_sqrt_price)
    
    # Format and return all test values
    return {
        "current_price": current_price,
        "lower_price": lower_price,
        "upper_price": upper_price,
        "current_tick": current_tick,
        "lower_tick": lower_tick,
        "upper_tick": upper_tick,
        "current_sqrt_price": current_sqrt_price,
        "lower_sqrt_price": lower_sqrt_price,
        "upper_sqrt_price": upper_sqrt_price,
        "liquidity": liquidity_amount,
        "amount0": amount0,
        "amount1": amount1
    }

def print_test_case(name, values):
    """Pretty prints a test case in a Cairo-friendly format"""
    print(f"// Test case: {name}")
    print(f"// Price range: {values['lower_price']} - {values['upper_price']}, " 
          f"current: {values['current_price']}")
    print(f"// Expected token amounts: {values['amount0']} token0, {values['amount1']} token1")
    print(f"""
fn {name}_test_values() -> (TestParams, u256, u256) {{
    let params = TestParams {{
        strk_balance: {int(values['amount0'] * 1.1)}, // 10% buffer
        usdc_balance: {int(values['amount1'] * 1.1)}, // 10% buffer
        cur_tick: {values['current_tick']},
        lower_tick: {values['lower_tick']},
        upper_tick: {values['upper_tick']},
        liq: {values['liquidity']},
        cur_sqrtp: {values['current_sqrt_price']},
        mint_liquidity: true,
    }};
    
    // Expected mint return values
    let expected_amount0 = {values['amount0']}_u256;
    let expected_amount1 = {values['amount1']}_u256;
    
    (params, expected_amount0, expected_amount1)
}}
""")

# Generate test cases
test_cases = [
    # Test case 1: Current price within range
    ("in_range_mint", generate_mint_test_values(
        current_price=2250.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904
    )),
    
    # Test case 2: Current price below range
    ("below_range_mint", generate_mint_test_values(
        current_price=1900.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904
    )),
    
    # Test case 3: Current price above range
    ("above_range_mint", generate_mint_test_values(
        current_price=2600.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904
    )),
    
    # Test case 4: Small price range
    ("narrow_range_mint", generate_mint_test_values(
        current_price=2250.0,
        lower_price=2225.0,
        upper_price=2275.0,
        liquidity_amount=5670207847624059387904
    )),
    
    # Test case 5: Wide price range
    ("wide_range_mint", generate_mint_test_values(
        current_price=2250.0,
        lower_price=1500.0,
        upper_price=3000.0,
        liquidity_amount=5670207847624059387904
    ))
]

# Print all test cases
for name, values in test_cases:
    print_test_case(name, values)
