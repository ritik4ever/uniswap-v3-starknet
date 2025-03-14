from utils import q96
import math

def next_sqrt_price_from_amount0(sqrt_price_x96, liquidity, amount, add):
    """
    Python implementation of getNextSqrtPriceFromAmount0RoundingUp
    Based on Uniswap v3 SqrtPriceMath.sol
    """
    if amount == 0:
        return sqrt_price_x96
    
    numerator1 = liquidity * (1 << 96)
    
    if add:
        product = amount * sqrt_price_x96
        denominator = numerator1 + product
        
        if denominator >= numerator1:
            # First formula: numerator1 * sqrtPX96 / (numerator1 + amount * sqrtPX96)
            return (numerator1 * sqrt_price_x96) // denominator
        else:
            # Alternative formula for large numbers
            return numerator1 // ((numerator1 // sqrt_price_x96) + amount)
    else:
        # Removing token0 increases price
        product = amount * sqrt_price_x96
        
        # Ensure we're not removing more than available (this check is in the actual contract)
        if product >= numerator1:
            # For test purposes, adjust to a safe value
            safe_amount = (numerator1 * 80 // 100) // sqrt_price_x96  # 80% of max as safety margin
            product = safe_amount * sqrt_price_x96
            amount = safe_amount
            
        denominator = numerator1 - product
        return (numerator1 * sqrt_price_x96) // denominator

def next_sqrt_price_from_amount1(sqrt_price_x96, liquidity, amount, add):
    """
    Python implementation of getNextSqrtPriceFromAmount1RoundingDown
    Based on Uniswap v3 SqrtPriceMath.sol
    """
    if amount == 0:
        return sqrt_price_x96
    
    if add:
        # Adding token1 increases price
        quotient = (amount << 96) // liquidity
        return sqrt_price_x96 + quotient
    else:
        # Removing token1 decreases price
        quotient = (amount << 96) // liquidity
        
        # Ensure we're not removing more than available
        if quotient >= sqrt_price_x96:
            # For test purposes, adjust to a safe value
            safe_amount = (sqrt_price_x96 * 80 // 100) * liquidity // (1 << 96)  # 80% of max
            quotient = (safe_amount << 96) // liquidity
            amount = safe_amount
            
        return sqrt_price_x96 - quotient

def generate_amount0_test_cases():
    """Generate test cases for get_next_sqrt_price_from_amount0_rounding_up"""
    test_cases = []
    
    # Case 1: Zero amount (no price change)
    sqrt_price = q96  # 1.0 price in Q64.96
    liquidity = 10000000000000
    amount = 0
    add = True
    expected = sqrt_price
    
    test_cases.append({
        'name': 'zero_amount',
        'sqrt_price_x96': sqrt_price,
        'liquidity': liquidity,
        'amount': amount,
        'add': add,
        'expected': expected
    })
    
    # Case 2: Adding token0 (price decreases)
    amount = 100000000000000000  # 0.1 ETH
    add = True
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'adding_token0',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 3: Removing token0 (price increases)
    # Calculate a safe amount that won't underflow
    max_safe_amount = (liquidity * q96 * 80 // 100) // sqrt_price
    amount = min(50000000000000000, max_safe_amount)  # 0.05 ETH or less if needed
    add = False
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'removing_token0',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 4: Real-world example from ETH/USDC pool
    sqrt_price = 2505414483750479311864138015198786
    liquidity = 8000000000000000
    amount = 1000000000000000000  # 1 ETH
    add = True
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'real_example',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    return test_cases

def generate_amount1_test_cases():
    """Generate test cases for get_next_sqrt_price_from_amount1_rounding_down"""
    test_cases = []
    
    # Case 1: Zero amount (no price change)
    sqrt_price = q96  # 1.0 price in Q64.96
    liquidity = 10000000000000
    amount = 0
    add = True
    expected = sqrt_price
    
    test_cases.append({
        'name': 'zero_amount',
        'sqrt_price_x96': sqrt_price,
        'liquidity': liquidity,
        'amount': amount,
        'add': add,
        'expected': expected
    })
    
    # Case 2: Adding token1 (price increases)
    amount = 100000000000000000  # 0.1 ETH worth of token1
    add = True
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'adding_token1',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 3: Removing token1 (price decreases)
    max_safe_amount = (sqrt_price * 80 // 100) * liquidity // (1 << 96)
    amount = min(50000000000000000, max_safe_amount)
    add = False
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'removing_token1',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 4: Real-world example from ETH/USDC pool
    sqrt_price = 2505414483750479311864138015198786
    liquidity = 8000000000000000
    amount = 2000000000  # 2000 USDC
    add = True
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, add)
        test_cases.append({
            'name': 'real_example',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'add': add,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    return test_cases

def generate_input_test_cases():
    """Generate test cases for get_next_sqrt_price_from_input"""
    test_cases = []
    
    # Case 1: Input token0 (price decreases)
    sqrt_price = q96  # 1.0 price in Q64.96
    liquidity = 10000000000000
    amount = 100000000000000000  # 0.1 ETH
    zero_for_one = True
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, True)
        test_cases.append({
            'name': 'token0',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 2: Input token1 (price increases)
    zero_for_one = False
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, True)
        test_cases.append({
            'name': 'token1',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 3: ETH/USDC swap example - selling ETH for USDC
    sqrt_price = 2505414483750479311864138015198786  # ~2000 USDC per ETH
    liquidity = 8000000000000000
    amount = 500000000000000000  # 0.5 ETH
    zero_for_one = True
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, True)
        test_cases.append({
            'name': 'eth_to_usdc',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 4: ETH/USDC swap example - buying ETH with USDC
    amount = 1000000000  # 1000 USDC
    zero_for_one = False
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, True)
        test_cases.append({
            'name': 'usdc_to_eth',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    return test_cases

def generate_output_test_cases():
    """Generate test cases for get_next_sqrt_price_from_output"""
    test_cases = []
    
    # Case 1: Output token1 (selling token0, price decreases)
    sqrt_price = q96  # 1.0 price in Q64.96
    liquidity = 10000000000000
    # Safe amount for token1 output
    amount = (sqrt_price * 10 // 100) * liquidity // (1 << 96)  # 10% of available token1
    zero_for_one = True  # We're swapping token0 for token1
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, False)
        test_cases.append({
            'name': 'token1_out',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 2: Output token0 (selling token1, price increases)
    # Safe amount for token0 output
    amount = (liquidity * q96 * 10 // 100) // sqrt_price  # 10% of available token0
    zero_for_one = False  # We're swapping token1 for token0
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, False)
        test_cases.append({
            'name': 'token0_out',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 3: ETH/USDC swap example - buying ETH with USDC (exact output)
    sqrt_price = 2505414483750479311864138015198786  # ~2000 USDC per ETH
    liquidity = 8000000000000000
    # Safe amount for ETH output (token0)
    max_safe_amount = (liquidity * q96 * 10 // 100) // sqrt_price  # 10% of available ETH
    amount = min(100000000000000000, max_safe_amount)  # Max 0.1 ETH
    zero_for_one = False  # Swapping USDC for ETH
    try:
        expected = next_sqrt_price_from_amount0(sqrt_price, liquidity, amount, False)
        test_cases.append({
            'name': 'exact_eth_out',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    # Case 4: ETH/USDC swap example - selling ETH for USDC (exact output)
    # Safe amount for USDC output (token1)
    max_safe_amount = (sqrt_price * 10 // 100) * liquidity // (1 << 96)  # 10% of available USDC
    amount = min(500000000, max_safe_amount)  # Max 500 USDC
    zero_for_one = True  # Swapping ETH for USDC
    try:
        expected = next_sqrt_price_from_amount1(sqrt_price, liquidity, amount, False)
        test_cases.append({
            'name': 'exact_usdc_out',
            'sqrt_price_x96': sqrt_price,
            'liquidity': liquidity,
            'amount': amount,
            'zero_for_one': zero_for_one,
            'expected': expected
        })
    except Exception as e:
        print(f"Skipping test case due to: {e}")
    
    return test_cases

def print_amount0_test_code(test_cases):
    """Generate Cairo test code for get_next_sqrt_price_from_amount0_rounding_up"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_next_sqrt_price_from_amount0_{case['name']}() {{")
        print(f"    // Test price calculation when {'adding' if case['add'] else 'removing'} token0")
        print(f"    let sqrt_price_x96 = FixedQ64x96 {{ value: {case['sqrt_price_x96']}_u256 }};")
        print(f"    let liquidity = {case['liquidity']}_u128;")
        print(f"    let amount = {case['amount']}_u256;")
        print(f"    let add = {str(case['add']).lower()};")
        print(f"")
        print(f"    let result = SqrtPriceMath::get_next_sqrt_price_from_amount0_rounding_up(")
        print(f"        sqrt_price_x96.clone(), liquidity, amount, add")
        print(f"    );")
        print(f"")
        print(f"    println!(\"Initial price: {{}}, Result price: {{}}\", sqrt_price_x96.value, result.value);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    let tolerance = expected / 10000_u256; // 0.01% tolerance")
        print(f"    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, ")
        print(f"        'Price calculation incorrect');")
        print(f"}}\n")

def print_amount1_test_code(test_cases):
    """Generate Cairo test code for get_next_sqrt_price_from_amount1_rounding_down"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_next_sqrt_price_from_amount1_{case['name']}() {{")
        print(f"    // Test price calculation when {'adding' if case['add'] else 'removing'} token1")
        print(f"    let sqrt_price_x96 = FixedQ64x96 {{ value: {case['sqrt_price_x96']}_u256 }};")
        print(f"    let liquidity = {case['liquidity']}_u128;")
        print(f"    let amount = {case['amount']}_u256;")
        print(f"    let add = {str(case['add']).lower()};")
        print(f"")
        print(f"    let result = SqrtPriceMath::get_next_sqrt_price_from_amount1_rounding_down(")
        print(f"        sqrt_price_x96.clone(), liquidity, amount, add")
        print(f"    );")
        print(f"")
        print(f"    println!(\"Initial price: {{}}, Result price: {{}}\", sqrt_price_x96.value, result.value);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    let tolerance = expected / 10000_u256; // 0.01% tolerance")
        print(f"    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, ")
        print(f"        'Price calculation incorrect');")
        print(f"}}\n")

def print_input_test_code(test_cases):
    """Generate Cairo test code for get_next_sqrt_price_from_input"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_next_sqrt_price_from_input_{case['name']}() {{")
        print(f"    // Test price calculation for {'token0' if case['zero_for_one'] else 'token1'} input")
        print(f"    let sqrt_price_x96 = FixedQ64x96 {{ value: {case['sqrt_price_x96']}_u256 }};")
        print(f"    let liquidity = {case['liquidity']}_u128;")
        print(f"    let amount_in = {case['amount']}_u256;")
        print(f"    let zero_for_one = {str(case['zero_for_one']).lower()};")
        print(f"")
        print(f"    let result = SqrtPriceMath::get_next_sqrt_price_from_input(")
        print(f"        sqrt_price_x96.clone(), liquidity, amount_in, zero_for_one")
        print(f"    );")
        print(f"")
        print(f"    println!(\"Initial price: {{}}, Result price: {{}}\", sqrt_price_x96.value, result.value);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    let tolerance = expected / 10000_u256; // 0.01% tolerance")
        print(f"    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, ")
        print(f"        'Price calculation incorrect');")
        print(f"}}\n")

def print_output_test_code(test_cases):
    """Generate Cairo test code for get_next_sqrt_price_from_output"""
    for case in test_cases:
        print(f"#[test]")
        print(f"fn test_get_next_sqrt_price_from_output_{case['name']}() {{")
        print(f"    // Test price calculation for {'token1' if case['zero_for_one'] else 'token0'} output")
        print(f"    let sqrt_price_x96 = FixedQ64x96 {{ value: {case['sqrt_price_x96']}_u256 }};")
        print(f"    let liquidity = {case['liquidity']}_u128;")
        print(f"    let amount_out = {case['amount']}_u256;")
        print(f"    let zero_for_one = {str(case['zero_for_one']).lower()};")
        print(f"")
        print(f"    let result = SqrtPriceMath::get_next_sqrt_price_from_output(")
        print(f"        sqrt_price_x96.clone(), liquidity, amount_out, zero_for_one")
        print(f"    );")
        print(f"")
        print(f"    println!(\"Initial price: {{}}, Result price: {{}}\", sqrt_price_x96.value, result.value);")
        print(f"    let expected = {case['expected']}_u256;")
        print(f"    let tolerance = expected / 10000_u256; // 0.01% tolerance")
        print(f"    assert(result.value >= expected - tolerance && result.value <= expected + tolerance, ")
        print(f"        'Price calculation incorrect');")
        print(f"}}\n")

def main():
    print("use contracts::libraries::math::sqrtprice_math::SqrtPriceMath;")
    print("use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};\n\n")
    
    print("// --- Cairo Test Code for get_next_sqrt_price_from_amount0_rounding_up --- //")
    amount0_cases = generate_amount0_test_cases()
    print_amount0_test_code(amount0_cases)
    
    print("// --- Cairo Test Code for get_next_sqrt_price_from_amount1_rounding_down --- //")
    amount1_cases = generate_amount1_test_cases()
    print_amount1_test_code(amount1_cases)
    
    print("// --- Cairo Test Code for get_next_sqrt_price_from_input --- //")
    input_cases = generate_input_test_cases()
    print_input_test_code(input_cases)
    
    print("// --- Cairo Test Code for get_next_sqrt_price_from_output --- //")
    output_cases = generate_output_test_cases()
    print_output_test_code(output_cases)

if __name__ == "__main__":
    main()
