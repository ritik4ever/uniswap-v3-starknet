import math
from decimal import Decimal, getcontext

# Set precision high for decimal calculations
getcontext().prec = 40

# Constants
Q96 = 2**96
MAX_I128 = 2**127 - 1
MIN_SQRT_RATIO = 4295128739
MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342

def sqrt_price_to_price(sqrt_price_x96):
    """Convert sqrtPriceX96 to price"""
    price = (sqrt_price_x96 / Q96) ** 2
    return price

def price_to_sqrt_price(price):
    """Convert price to sqrtPriceX96"""
    sqrt_price = int(math.sqrt(price) * Q96)
    return sqrt_price

def calc_amount0_delta(sqrt_ratio_a, sqrt_ratio_b, liquidity):
    """Calculate amount of token0 given sqrt price range and liquidity"""
    if sqrt_ratio_a > sqrt_ratio_b:
        sqrt_ratio_a, sqrt_ratio_b = sqrt_ratio_b, sqrt_ratio_a
    
    numerator = liquidity * Q96 * (sqrt_ratio_b - sqrt_ratio_a)
    denominator = sqrt_ratio_b * sqrt_ratio_a
    
    return numerator // denominator

def calc_amount1_delta(sqrt_ratio_a, sqrt_ratio_b, liquidity):
    """Calculate amount of token1 given sqrt price range and liquidity"""
    if sqrt_ratio_a > sqrt_ratio_b:
        sqrt_ratio_a, sqrt_ratio_b = sqrt_ratio_b, sqrt_ratio_a
    
    return liquidity * (sqrt_ratio_b - sqrt_ratio_a) // Q96

def get_next_sqrt_price_from_input(sqrt_ratio_x96, liquidity, amount, zero_for_one):
    """Calculate next sqrt price based on input amount"""
    if zero_for_one:
        # Adding token0
        if liquidity == 0:
            return 0
        
        numerator = liquidity * sqrt_ratio_x96
        product = amount * sqrt_ratio_x96
        
        if product // amount == sqrt_ratio_x96:
            denominator = liquidity + (product // Q96)
            return numerator // denominator
        else:
            denominator = liquidity + ((amount * sqrt_ratio_x96) // Q96)
            return numerator // denominator
    else:
        # Adding token1
        if liquidity == 0:
            return 0
        
        return sqrt_ratio_x96 + (amount * Q96) // liquidity

def compute_swap_step(sqrt_ratio_current_x96, sqrt_ratio_target_x96, liquidity, amount_remaining, zero_for_one):
    """Python version of compute_swap_step function"""
    if zero_for_one:
        next_sqrt_price = get_next_sqrt_price_from_input(
            sqrt_ratio_current_x96,
            liquidity,
            abs(amount_remaining),
            True
        )
        
        sqrt_ratio_next_x96 = min(next_sqrt_price, sqrt_ratio_target_x96) if next_sqrt_price > 0 else sqrt_ratio_target_x96
        
        amount_in = calc_amount0_delta(
            sqrt_ratio_current_x96,
            sqrt_ratio_next_x96,
            liquidity
        )
        
        amount_out = -calc_amount1_delta(
            sqrt_ratio_current_x96,
            sqrt_ratio_next_x96,
            liquidity
        )
    else:
        next_sqrt_price = get_next_sqrt_price_from_input(
            sqrt_ratio_current_x96,
            liquidity,
            abs(amount_remaining),
            False
        )
        
        sqrt_ratio_next_x96 = max(next_sqrt_price, sqrt_ratio_target_x96) if next_sqrt_price > 0 else sqrt_ratio_target_x96
        
        amount_in = calc_amount1_delta(
            sqrt_ratio_current_x96,
            sqrt_ratio_next_x96,
            liquidity
        )
        
        amount_out = -calc_amount0_delta(
            sqrt_ratio_current_x96,
            sqrt_ratio_next_x96,
            liquidity
        )
    
    return (sqrt_ratio_next_x96, amount_in, amount_out)

def generate_extended_test_cases():
    """Generate extended test cases for compute_swap_step"""
    test_cases = []
    
    # ====== ORIGINAL TEST CASES ======
    
    # Test Case 1: Small amount, token0 to token1
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**17  # 0.1 ETH input
    target_price = price * 0.99  # 1% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "small_amount_0_to_1",
        "description": "Small swap: 0.1 ETH for USDC (token0 to token1)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 2: Small amount, token1 to token0
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**5 * 10**6  # 100,000 USDC input
    target_price = price * 1.01  # 1% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "small_amount_1_to_0",
        "description": "Small swap: 100,000 USDC for ETH (token1 to token0)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # Test Case 3: Large amount, token0 to token1
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**18  # 1 ETH input (large relative to liquidity)
    target_price = price * 0.9  # 10% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "large_amount_0_to_1",
        "description": "Large swap: 1 ETH for USDC (token0 to token1)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 4: Large amount, token1 to token0
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**6 * 10**6  # 1,000,000 USDC input
    target_price = price * 1.1  # 10% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "large_amount_1_to_0",
        "description": "Large swap: 1,000,000 USDC for ETH (token1 to token0)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # ====== EXTENDED TEST CASES ======
    
    # === EDGE CASES ===
    
    # Test Case 5: Tiny amount, token0 to token1
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**10  # 0.00000001 ETH input (very small)
    target_price = price * 0.999  # 0.1% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "tiny_amount_0_to_1",
        "description": "Tiny swap: 0.00000001 ETH for USDC (token0 to token1)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 6: Tiny amount, token1 to token0
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**2  # 100 wei of USDC (very small)
    target_price = price * 1.0001  # 0.01% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "tiny_amount_1_to_0",
        "description": "Tiny swap: 100 wei USDC for ETH (token1 to token0)",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # Test Case 7: Very small liquidity
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**6  # Very small liquidity
    amount = 10**15  # 0.001 ETH input
    target_price = price * 0.5  # 50% price impact due to low liquidity
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "small_liquidity_0_to_1",
        "description": "Swap with very small liquidity: 0.001 ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 8: Zero liquidity handling (should result in immediate price impact)
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 0  # Zero liquidity
    amount = 10**15  # 0.001 ETH input
    target_price = price * 0.9  # Target doesn't matter, will hit it immediately
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "zero_liquidity_0_to_1",
        "description": "Swap with zero liquidity: 0.001 ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 9: Exact swap that hits target price (token0 to token1)
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    target_price = price * 0.95  # 5% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    # Calculate exact amount needed to hit target price
    amount = calc_amount0_delta(sqrt_price_x96, target_sqrt_price_x96, liquidity)
    
    test_cases.append({
        "name": "exact_target_0_to_1",
        "description": "Exact amount to hit target price: ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 10: Exact swap that hits target price (token1 to token0)
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    target_price = price * 1.05  # 5% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    # Calculate exact amount needed to hit target price
    amount = calc_amount1_delta(sqrt_price_x96, target_sqrt_price_x96, liquidity)
    
    test_cases.append({
        "name": "exact_target_1_to_0",
        "description": "Exact amount to hit target price: USDC for ETH",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # Test Case 11: Very large amount (should hit target price)
    price = 2000  # ETH price in USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**18  # 1 ETH worth of liquidity
    amount = 10**22  # Extremely large amount
    target_price = price * 0.8  # 20% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "huge_amount_0_to_1",
        "description": "Huge swap amount that should hit target: ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 12: Price near minimum sqrt ratio
    # For ETH/USDC, this would be an extremely low ETH price
    near_min_price = sqrt_price_to_price(MIN_SQRT_RATIO * 2)
    sqrt_price_x96 = MIN_SQRT_RATIO * 2
    liquidity = 10**18
    amount = 10**17
    target_sqrt_price_x96 = MIN_SQRT_RATIO + 1000
    
    test_cases.append({
        "name": "near_min_price_0_to_1",
        "description": "Swap near minimum price boundary: ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 13: Price near maximum sqrt ratio
    # For ETH/USDC, this would be an extremely high ETH price
    near_max_price = sqrt_price_to_price(MAX_SQRT_RATIO - 10000)
    sqrt_price_x96 = MAX_SQRT_RATIO - 10000
    liquidity = 10**18
    amount = 10**25  # Large USDC amount
    target_sqrt_price_x96 = MAX_SQRT_RATIO - 100
    
    test_cases.append({
        "name": "near_max_price_1_to_0",
        "description": "Swap near maximum price boundary: USDC for ETH",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # === REAL-WORLD EXAMPLES ===
    
    # Test Case 14: Realistic ETH/USDC swap
    price = 1850.75  # More precise ETH price
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 5 * 10**19  # 50 ETH worth of liquidity
    amount = 2 * 10**18  # 2 ETH
    target_price = price * 0.985  # 1.5% price impact
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "realistic_eth_usdc_0_to_1",
        "description": "Realistic ETH/USDC swap: 2 ETH for USDC",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 15: Stablecoin pair (small price movement)
    # USDC/DAI where price is very close to 1.0
    price = 1.001  # Slight premium for USDC
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**22  # Large liquidity as typical for stablecoin pairs
    amount = 10**8 * 10**6  # 100 million USDC
    target_price = 1.0005  # Tiny price movement
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "stablecoin_pair_0_to_1",
        "description": "Stablecoin pair swap: USDC/DAI with minimal price impact",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": True
    })
    
    # Test Case 16: High volatility token pair
    # Example: ETH/SHIB with large price movements
    price = 0.00005  # SHIB price in ETH
    sqrt_price_x96 = price_to_sqrt_price(price)
    liquidity = 10**16  # Lower liquidity
    amount = 10**20  # Large SHIB amount
    target_price = price * 1.2  # 20% price swing
    target_sqrt_price_x96 = price_to_sqrt_price(target_price)
    
    test_cases.append({
        "name": "high_volatility_pair_1_to_0",
        "description": "High volatility token pair: SHIB for ETH with large price impact",
        "sqrt_ratio_current_x96": sqrt_price_x96,
        "sqrt_ratio_target_x96": target_sqrt_price_x96,
        "liquidity": liquidity,
        "amount_remaining": amount,
        "zero_for_one": False
    })
    
    # Compute expected results for each test case
    for case in test_cases:
        result = compute_swap_step(
            case["sqrt_ratio_current_x96"],
            case["sqrt_ratio_target_x96"],
            case["liquidity"],
            case["amount_remaining"],
            case["zero_for_one"]
        )
        case["expected_sqrt_ratio_next_x96"] = result[0]
        case["expected_amount_in"] = result[1]
        case["expected_amount_out"] = result[2]
    
    return test_cases

def generate_cairo_tests(test_cases):
    """Generate Cairo test code from test cases - with u256 tolerance checks"""
    cairo_code = """// AUTO-GENERATED SWAP MATH TESTS
use contracts::libraries::math::swap_math::SwapMath;
use contracts::libraries::math::numbers::fixed_point::FixedQ64x96;

const MAX_I128: i128 = 170_141_183_460_469_231_731_687_303_715_884_105_727;

"""
    
    # Helper function for u256 tolerance checks
    cairo_code += """
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
    let tolerance_amount = if tolerance_amount == 0_u256 { 1_u256 } else { tolerance_amount };
    
    diff <= tolerance_amount
}
"""
    # Generate a separate test function for each test case
    for case in test_cases:
        function_name = f"test_compute_swap_step_{case['name']}"
        
        # Handle the expected amount_out value (which is negative in the model)
        # We need the absolute value for comparison since Cairo represents it as positive
        expected_amount_out = abs(case['expected_amount_out'])
        
        # Use a higher tolerance for edge cases
        tolerance = 5 if "small_liquidity" in case['name'] or "near_min_price" in case['name'] or "near_max_price" in case['name'] else 1
        
        cairo_code += f"""
#[test]
fn {function_name}() {{
    // {case['description']}
    let sqrt_ratio_current_x96 = FixedQ64x96 {{ value: {case['sqrt_ratio_current_x96']}_u256 }};
    let sqrt_ratio_target_x96 = FixedQ64x96 {{ value: {case['sqrt_ratio_target_x96']}_u256 }};
    let liquidity: u128 = {case['liquidity']};
    let amount_remaining: i128 = {case['amount_remaining']};
    let zero_for_one: bool = {'true' if case['zero_for_one'] else 'false'};
    
    let (sqrt_ratio_next_x96, amount_in, amount_out) = SwapMath::compute_swap_step(
        sqrt_ratio_current_x96,
        sqrt_ratio_target_x96,
        liquidity,
        amount_remaining,
        zero_for_one
    );
    
    // Print debug values
    println!("sqrt_ratio_next_x96: {{}} (expected: {{}})", 
             sqrt_ratio_next_x96.value, {case['expected_sqrt_ratio_next_x96']}_u256);
    println!("amount_in: {{}} (expected: {{}})", amount_in, {case['expected_amount_in']}_u256);
    println!("amount_out: {{}} (expected: {{}})", amount_out, {expected_amount_out}_u256);
    
    // Check sqrt_ratio_next_x96 with tolerance
    assert(
        is_within_tolerance(sqrt_ratio_next_x96.value, {case['expected_sqrt_ratio_next_x96']}_u256, {tolerance}),
        'incorrect sqrt_ratio_next_x96'
    );
    
    // Check amount_in with tolerance
    assert(
        is_within_tolerance(amount_in, {case['expected_amount_in']}_u256, {tolerance}), 
        'incorrect amount_in'
    );
    
    // Check amount_out with tolerance - using absolute value comparison
    assert(
        is_within_tolerance(amount_out, {expected_amount_out}_u256, {tolerance}), 
        'incorrect amount_out'
    );
}}
"""
    
    return cairo_code

def main():
    # Generate extended test cases
    test_cases = generate_extended_test_cases()
    
    # Generate Cairo test code with separate functions
    cairo_code = generate_cairo_tests(test_cases)
    
    # Print Cairo test code
    print(cairo_code)

if __name__ == "__main__":
    main()
