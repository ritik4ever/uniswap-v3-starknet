from utils import (
    generate_calc_amount0_test_cases,
    generate_calc_amount1_test_cases,
    print_cairo_test_code,
    generate_swap_test_case,
    print_test_values
)

def main():
    # Print exact values for test cases
    print(" // --- Exact Test Values --- //")
    print_test_values()
    print("// --- END --- //")

    # Generate and print Cairo test code
    print("\n // --- Cairo Test Code for calc_amount0_delta --- // ")
    print_cairo_test_code(generate_calc_amount0_test_cases(), "calc_amount0_delta")
    
    print("\n // --- Cairo Test Code for calc_amount1_delta --- // ")
    print_cairo_test_code(generate_calc_amount1_test_cases(), "calc_amount1_delta")
    
    print("\n // --- Cairo Test Code for swap calculation --- // ")
    generate_swap_test_case()

if __name__ == "__main__":
    main()
