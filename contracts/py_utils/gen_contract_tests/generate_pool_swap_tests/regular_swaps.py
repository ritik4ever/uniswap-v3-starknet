from py_utils.uniswap_v3_math import price_to_tick, price_to_sqrtp, calc_amount0, calc_amount1, q96
import math

def generate_swap_test_values(
    current_price,
    lower_price,
    upper_price,
    liquidity_amount,
    amount_in,
    zero_for_one,
    expected_price_after=None
):
    """
    Generate test parameters for a swap with pre-computed expected values.
    """
    # Convert prices to ticks and sqrt prices
    current_tick = price_to_tick(current_price)
    lower_tick = price_to_tick(lower_price)
    upper_tick = price_to_tick(upper_price)
    
    # Ensure ticks are on spacing boundaries
    tick_spacing = 1
    lower_tick = (lower_tick // tick_spacing) * tick_spacing
    upper_tick = (upper_tick // tick_spacing) * tick_spacing
    
    current_sqrt_price = price_to_sqrtp(current_price)
    lower_sqrt_price = price_to_sqrtp(lower_price)
    upper_sqrt_price = price_to_sqrtp(upper_price)
    
    # Calculate mint amounts needed to set up the test
    mint_amount0 = 0
    mint_amount1 = 0
    
    if current_tick < lower_tick:
        # Current price is below range, only token0 needed
        mint_amount0 = calc_amount0(liquidity_amount, lower_sqrt_price, upper_sqrt_price)
    elif current_tick < upper_tick:
        # Current price is in range, both tokens needed
        mint_amount0 = calc_amount0(liquidity_amount, current_sqrt_price, upper_sqrt_price)
        mint_amount1 = calc_amount1(liquidity_amount, lower_sqrt_price, current_sqrt_price)
    else:
        # Current price is above range, only token1 needed
        mint_amount1 = calc_amount1(liquidity_amount, lower_sqrt_price, upper_sqrt_price)
    
    # Convert to signed amount for the swap
    amount_specified = int(amount_in)
    
    # Estimate price after swap if not provided
    if expected_price_after is None:
        if zero_for_one:
            # Price decreases when swapping token0 for token1
            price_change_factor = 1 - amount_in / (liquidity_amount * math.sqrt(current_price) * 2)
            expected_price_after = current_price * max(price_change_factor, 0.5)
        else:
            # Price increases when swapping token1 for token0
            price_change_factor = 1 + amount_in / (liquidity_amount * 2)
            expected_price_after = current_price * min(price_change_factor, 2.0)
    
    expected_sqrt_price_after = price_to_sqrtp(expected_price_after)
    expected_tick_after = price_to_tick(expected_price_after)
    
    # Price limit for slippage protection
    if zero_for_one:
        # When swapping token0 for token1, price decreases
        sqrt_price_limit = price_to_sqrtp(expected_price_after * 0.9)
    else:
        # When swapping token1 for token0, price increases
        sqrt_price_limit = price_to_sqrtp(expected_price_after * 1.1)
    
    # Calculate expected token amounts
    if zero_for_one:
        # token0 -> token1
        # Token0 is positive (in), token1 is negative (out)
        amount0_delta = amount_specified
        amount1_delta = -int(calc_amount1(liquidity_amount, expected_sqrt_price_after, current_sqrt_price))
    else:
        # token1 -> token0
        # Token1 is positive (in), token0 is negative (out)
        amount1_delta = amount_specified
        amount0_delta = -int(calc_amount0(liquidity_amount, current_sqrt_price, expected_sqrt_price_after))
    
    return {
        "current_price": current_price,
        "expected_price_after": expected_price_after,
        "lower_price": lower_price,
        "upper_price": upper_price,
        "current_tick": current_tick,
        "expected_tick_after": expected_tick_after,
        "lower_tick": lower_tick,
        "upper_tick": upper_tick,
        "current_sqrt_price": current_sqrt_price,
        "expected_sqrt_price_after": expected_sqrt_price_after,
        "sqrt_price_limit": sqrt_price_limit,
        "liquidity": liquidity_amount,
        "mint_amount0": mint_amount0,
        "mint_amount1": mint_amount1,
        "zero_for_one": zero_for_one,
        "amount_specified": amount_specified,
        "amount0_delta": amount0_delta,
        "amount1_delta": amount1_delta
    }

def print_swap_test_case(name, values):
    """Pretty print a swap test case in Cairo-friendly format"""
    direction = "token0_to_token1" if values["zero_for_one"] else "token1_to_token0"
    
    print(f"// Test case: {name}")
    print(f"// Direction: {direction}")
    print(f"// Price range: {values['lower_price']} - {values['upper_price']}")
    print(f"// Current price: {values['current_price']}, Expected after swap: {values['expected_price_after']}")
    print(f"// Swap amount specified: {values['amount_specified']}")
    print(f"// Expected token deltas: {values['amount0_delta']} token0, {values['amount1_delta']} token1")
    
    print(f"""
fn {name}_swap_test_values() -> (SwapTestParams, i128, i128) {{
    let params = SwapTestParams {{
        // Initial setup - price and liquidity
        cur_tick: {values['current_tick']},
        cur_sqrt_price: {values['current_sqrt_price']}_u256,
        lower_tick: {values['lower_tick']},
        upper_tick: {values['upper_tick']},
        liquidity: {values['liquidity']},
        
        // Swap parameters
        zero_for_one: {'true' if values['zero_for_one'] else 'false'},
        amount_specified: {values['amount_specified']},
        sqrt_price_limit: {values['sqrt_price_limit']}_u256,
        
        // For setting up the test
        mint_amount0: {int(values['mint_amount0'] * 1.1)}_u256,
        mint_amount1: {int(values['mint_amount1'] * 1.1)}_u256,
    }};
    
    // Expected swap results
    let expected_amount0: i128 = {values['amount0_delta']};
    let expected_amount1: i128 = {values['amount1_delta']};
    
    (params, expected_amount0, expected_amount1)
}}
""")

# Define a new struct type for swap tests
print("""
#[derive(Copy, Drop, Serde)]
struct SwapTestParams {
    // Initial setup - price and liquidity
    cur_tick: i32,
    cur_sqrt_price: u256,
    lower_tick: i32,
    upper_tick: i32,
    liquidity: u128,
    
    // Swap parameters
    zero_for_one: bool,
    amount_specified: i128,
    sqrt_price_limit: u256,
    
    // For setting up the test
    mint_amount0: u256,
    mint_amount1: u256,
}
""")

# Generate test cases covering essential scenarios
test_cases = [
    # 1. Standard swap token0 for token1 
    ("swap_exact_input_0_to_1", generate_swap_test_values(
        current_price=2250.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=100000000000000000,  # 0.1 ETH
        zero_for_one=True,
        expected_price_after=2240.0
    )),
    
    # 2. Standard swap token1 for token0
    ("swap_exact_input_1_to_0", generate_swap_test_values(
        current_price=2250.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=200000000,  # 200 USDC
        zero_for_one=False,
        expected_price_after=2260.0
    )),
    
    # 3. Small swap - minimal price impact
    ("small_swap_0_to_1", generate_swap_test_values(
        current_price=2250.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=10000000000000000,  # 0.01 ETH
        zero_for_one=True,
        expected_price_after=2249.0
    )),
    
    # 4. Large swap - significant price impact
    ("large_swap_0_to_1", generate_swap_test_values(
        current_price=2250.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=1000000000000000000,  # 1 ETH
        zero_for_one=True,
        expected_price_after=2150.0
    )),
    
    # 5. Edge case - near lower price bound
    ("swap_near_lower_bound", generate_swap_test_values(
        current_price=2010.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=50000000000000000,  # 0.05 ETH
        zero_for_one=True,
        expected_price_after=2002.0
    )),
    
    # 6. Edge case - near upper price bound
    ("swap_near_upper_bound", generate_swap_test_values(
        current_price=2490.0,
        lower_price=2000.0,
        upper_price=2500.0,
        liquidity_amount=5670207847624059387904,
        amount_in=150000000,  # 150 USDC
        zero_for_one=False,
        expected_price_after=2498.0
    ))
]

# Print all test cases
for name, values in test_cases:
    print_swap_test_case(name, values)
