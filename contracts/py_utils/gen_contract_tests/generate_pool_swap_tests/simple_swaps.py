from py_utils.uniswap_v3_math import price_to_tick, price_to_sqrtp, calc_amount0, calc_amount1, q96
import math

def generate_simple_swap_tests():
    """Generate simplified swap test cases that minimize loop iterations for easier debugging"""
    
    test_cases = []
    
    # Case 1: Single-tick swap (no tick crossings) - token0 to token1
    current_price = 2000.0
    current_tick = price_to_tick(current_price)
    current_sqrt_price = price_to_sqrtp(current_price)
    lower_tick = price_to_tick(1900.0)
    upper_tick = price_to_tick(2100.0)
    liquidity = 1000000000000000000  # 1e18
    
    mint_amount0 = calc_amount0(liquidity, price_to_sqrtp(2000.0), price_to_sqrtp(2100.0))
    mint_amount1 = calc_amount1(liquidity, price_to_sqrtp(1900.0), price_to_sqrtp(2000.0))
    
    
    # The precomputed output value for comparison
    amount1_delta = -1996801996801996
    
    # Calculate the expected output value using our formula for comparison
    calculated_amount1 = calc_amount1(
        liquidity, 
        price_to_sqrtp(2000.0), 
        price_to_sqrtp(2000.0 - (0.001 * 2000.0 / liquidity))
    )
    
    # Log the ratio to identify scaling issues
    if amount1_delta != 0:
        ratio = calculated_amount1 / (-amount1_delta)
    
    test_cases.append({
        "name": "minimal_swap_0_to_1",
        "description": "Tiny swap token0→token1 - no tick crossings",
        "current_price": current_price,
        "current_tick": current_tick,
        "current_sqrt_price": current_sqrt_price,
        "lower_tick": lower_tick,
        "upper_tick": upper_tick,
        "liquidity": liquidity,
        "zero_for_one": True,
        "amount_specified": 1000000000000000,  # 0.001 ETH
        "sqrt_price_limit": price_to_sqrtp(1900.0),  # Won't hit this limit
        "mint_amount0": mint_amount0,
        "mint_amount1": mint_amount1,
        "amount0_delta": 1000000000000000,
        "amount1_delta": amount1_delta  # Precomputed output
    })
    
    # Case 2: Single-tick swap (no tick crossings) - token1 to token0
    # Similar detailed logging for Case 2
    test_cases.append({
        "name": "minimal_swap_1_to_0",
        "description": "Tiny swap token1→token0 - no tick crossings",
        "current_price": 2000.0,
        "current_tick": price_to_tick(2000.0),
        "current_sqrt_price": price_to_sqrtp(2000.0),
        "lower_tick": price_to_tick(1900.0),
        "upper_tick": price_to_tick(2100.0),
        "liquidity": 1000000000000000000,  # 1e18
        "zero_for_one": False,
        "amount_specified": 2000000,  # 2 USDC
        "sqrt_price_limit": price_to_sqrtp(2100.0),  # Won't hit this limit
        "mint_amount0": calc_amount0(1000000000000000000, price_to_sqrtp(2000.0), price_to_sqrtp(2100.0)),
        "mint_amount1": calc_amount1(1000000000000000000, price_to_sqrtp(1900.0), price_to_sqrtp(2000.0)),
        "amount0_delta": -999500,  # Precomputed output
        "amount1_delta": 2000000
    })
    
    # Case 3: Exact tick boundary swap (0→1)
    current_tick = price_to_tick(2000.0)
    target_tick = current_tick - 1  # One tick below current
    liquidity = 1000000000000000000
    current_sqrt_price = price_to_sqrtp(2000.0)
    target_sqrt_price = price_to_sqrtp(math.pow(1.0001, target_tick))
    
    # Calculate exact amount needed to reach the boundary
    exact_amount = calc_amount0(liquidity, target_sqrt_price, current_sqrt_price)
    
    # Calculate expected output amount
    expected_out = calc_amount1(liquidity, target_sqrt_price, current_sqrt_price)
    
    test_cases.append({
        "name": "exact_tick_boundary_0_to_1",
        "description": "Swap with exact amount to reach tick boundary (0→1)",
        "current_price": 2000.0,
        "current_tick": current_tick,
        "current_sqrt_price": current_sqrt_price,
        "lower_tick": target_tick,  # Position tick boundary exactly at target
        "upper_tick": current_tick + 10,
        "liquidity": liquidity,
        "zero_for_one": True,
        "amount_specified": int(exact_amount),
        "sqrt_price_limit": price_to_sqrtp(1900.0),
        "mint_amount0": calc_amount0(liquidity, current_sqrt_price, price_to_sqrtp(math.pow(1.0001, current_tick + 10))),
        "mint_amount1": calc_amount1(liquidity, price_to_sqrtp(math.pow(1.0001, target_tick)), current_sqrt_price),
        "amount0_delta": int(exact_amount),
        "amount1_delta": -int(calc_amount1(liquidity, target_sqrt_price, current_sqrt_price))
    })
    
    # Case 4: Perfect round numbers
    round_price = 1000.0
    round_liquidity = 10**18
    round_amount = 10**16
    
    # Calculate expected output
    expected_out = calc_amount1(round_liquidity, price_to_sqrtp(round_price), 
                                price_to_sqrtp(round_price * (1 - round_amount/round_liquidity)))
    
    test_cases.append({
        "name": "round_numbers_swap",
        "description": "Swap with nice round numbers for easy verification",
        "current_price": round_price,
        "current_tick": price_to_tick(round_price),
        "current_sqrt_price": price_to_sqrtp(round_price),
        "lower_tick": price_to_tick(900.0),
        "upper_tick": price_to_tick(1100.0),
        "liquidity": round_liquidity,
        "zero_for_one": True,
        "amount_specified": round_amount,
        "sqrt_price_limit": price_to_sqrtp(900.0),
        "mint_amount0": calc_amount0(round_liquidity, price_to_sqrtp(round_price), price_to_sqrtp(1100.0)),
        "mint_amount1": calc_amount1(round_liquidity, price_to_sqrtp(900.0), price_to_sqrtp(round_price)),
        "amount0_delta": round_amount,
        "amount1_delta": -9990009990009990  # Precomputed output
    })
    
    return test_cases

def print_swap_test_case(values):
    """Print a swap test case in Cairo-friendly format"""
    name = values["name"]
    direction = "token0_to_token1" if values["zero_for_one"] else "token1_to_token0"
    
    print(f"// Test case: {name}")
    print(f"// Description: {values['description']}")
    print(f"// Direction: {direction}")
    print(f"// Current tick: {values['current_tick']}")
    print(f"// Current price: {values['current_price']}")
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

def main():
    
    # Define the SwapTestParams struct
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
    
    # Generate simplified test cases
    test_cases = generate_simple_swap_tests()
    
    # Print each test case
    for case in test_cases:
        print_swap_test_case(case)
    

if __name__ == "__main__":
    main()
