def position(tick):
    """Calculate the position in the bitmap from a tick index"""
    word_pos = tick // 256
    bit_pos = tick % 256
    
    # Handle negative ticks that aren't multiples of 256
    if tick < 0 and tick % 256 != 0:
        word_pos -= 1
        bit_pos = 255 - (((-tick) % 256) - 1)
    
    return (word_pos, bit_pos)

def calculate_mask(bit_pos):
    """Calculate a mask with a 1 at the bit position"""
    return 1 << bit_pos

def flip_bit(word, bit_pos):
    """Flip a bit in a word at the given position"""
    mask = calculate_mask(bit_pos)
    return word ^ mask

def find_next_initialized_tick(word, bit_pos, lte):
    """Find the next initialized tick within a word"""
    if lte:  # Less than or equal (searching right to left)
        if bit_pos == 255:
            mask = 2**256 - 1  # All bits set
        else:
            mask = (1 << (bit_pos + 1)) - 1
        
        masked_word = word & mask
        
        if masked_word != 0:
            # Find most significant bit
            msb = 0
            for i in range(256):
                if (masked_word >> i) & 1:
                    msb = i
            return (msb, True)
        return (255, False)  # No initialized tick found
    else:  # Greater than (searching left to right)
        if bit_pos == 255:
            mask = 0
        else:
            mask = (2**256 - 1) - ((1 << (bit_pos + 1)) - 1)
            
        masked_word = word & mask
        
        if masked_word != 0:
            # Find least significant bit
            lsb = 255
            for i in range(255, -1, -1):
                if (masked_word >> i) & 1:
                    lsb = i
            return (lsb, True)
        return (0, False)  # No initialized tick found

def generate_cairo_tests():
    """Generate Cairo test code for TickBitmap contract testing"""
    
    # Start with test code boilerplate
    code = """
#[test]
mod tick_bitmap_tests {
    use core::debug::PrintTrait;
    use contracts::contract::interface::IUniswapV3TickBitmap;
    use contracts::contract::interface::IUniswapV3TickBitmapDispatcher;
    use starknet::{ContractAddress, deploy_syscall, get_caller_address, get_contract_address, class_hash_to_felt252};
    use starknet::class_hash::declare;
    use core::result::ResultTrait;
    
    fn deploy_tick_bitmap() -> IUniswapV3TickBitmapDispatcher {
        // Declare the contract
        let contract = declare("TickBitmap").unwrap();
        
        // Deploy with empty calldata
        let (contract_address, _) = contract.deploy(@array![]).unwrap();
        
        // Return a dispatcher for the contract
        IUniswapV3TickBitmapDispatcher { contract_address }
    }
    
    #[test]
    fn test_setup() {
        // Simple test to ensure deployment works
        let dispatcher = deploy_tick_bitmap();
        // If we get here, the test passed
        assert(true, 'setup failed');
    }
"""
    
    # Test cases for flip_tick
    test_cases_flip = [
        # Format: (name, tick, tick_spacing, word_before, expected_word_after)
        ("simple_positive", 10, 1, 0, 1 << (10 % 256)),
        ("simple_negative", -10, 1, 0, 1 << (255 - 9)),  # -10/1 -> -10, word_pos=-1, bit_pos=246
        ("tick_spacing_2", 20, 2, 0, 1 << (10 % 256)),  # 20/2 -> 10
        ("tick_spacing_10", 100, 10, 0, 1 << (10 % 256)),  # 100/10 -> 10
        ("edge_zero", 0, 1, 0, 1),  # Bit position 0
        ("edge_word_boundary", 255, 1, 0, 1 << 255),  # Last bit in word
        ("flip_twice", 10, 1, 1 << (10 % 256), 0),  # Flipping twice returns to original
        ("multiple_flips", 20, 1, (1 << (10 % 256)) | (1 << (30 % 256)), (1 << (10 % 256)) | (1 << (30 % 256)) | (1 << (20 % 256))),
    ]
    
    # Generate test functions for flip_tick
    for name, tick, tick_spacing, word_before, word_after in test_cases_flip:
        word_pos, bit_pos = position(tick // tick_spacing)
        
        code += f"""
    #[test]
    fn test_flip_tick_{name}() {{
        let dispatcher = deploy_tick_bitmap();
        
        // Test for tick={tick}, tick_spacing={tick_spacing}
        // Word position: {word_pos}, bit position: {bit_pos}
        
        // Verify initial state (empty bitmap)
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word({tick}, {tick_spacing}, true);
        assert(!initialized, 'Tick should not be initialized');
        
        // Flip the tick
        dispatcher.flip_tick({tick}, {tick_spacing});
        
        // Verify tick is now initialized
        let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word({tick}, {tick_spacing}, true);
        assert(initialized, 'Tick should be initialized');
        assert(found_tick == {tick}, 'Wrong tick found');
        
        // Flip it again to clear
        dispatcher.flip_tick({tick}, {tick_spacing});
        
        // Verify it's uninitialized again
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word({tick}, {tick_spacing}, true);
        assert(!initialized, 'Tick should be uninitialized');
    }}
"""
    
    # Test cases for next_initialized_tick_within_one_word
    # We'll create more complex bitmap states and test both directions
    tick_spacing = 1  # Using tick_spacing=1 for simplicity
    
    # Format: (name, initial_ticks, test_tick, lte, expected_tick, expected_initialized)
    test_cases_next = [
        # Searching right to left (lte=true)
        ("single_tick_lte_match", [100], 100, True, 100, True),  # Exact match
        ("single_tick_lte_above", [100], 150, True, 100, True),  # Search below current
        ("single_tick_lte_below", [100], 50, True, -1, False),  # No match below
        
        # Searching left to right (lte=false)
        ("single_tick_gt_match", [100], 100, False, 100, True),  # Should not match exact (>)
        ("single_tick_gt_below", [100], 50, False, 100, True),  # Search above current
        ("single_tick_gt_above", [100], 150, False, 256, False),  # No match above
        
        # Multiple ticks
        ("multiple_ticks_lte", [50, 100, 150], 120, True, 100, True),
        ("multiple_ticks_gt", [50, 100, 150], 80, False, 100, True),
        
        # Word boundary cases
        ("word_boundary_low_lte", [0], 10, True, 0, True),
        ("word_boundary_high_gt", [255], 250, False, 255, True),
        
        # Negative ticks
        ("negative_tick_lte", [-100, -50], -75, True, -100, True),
        ("negative_tick_gt", [-100, -50], -75, False, -50, True),
    ]
    
    # Generate test functions for next_initialized_tick_within_one_word
    for name, initial_ticks, test_tick, lte, expected_tick, expected_initialized in test_cases_next:
        setup_code = ""
        for tick in initial_ticks:
            setup_code += f"""
        dispatcher.flip_tick({tick}, {tick_spacing});"""
        
        direction = "lte" if lte else "gt"
        code += f"""
    #[test]
    fn test_next_tick_{name}() {{
        let dispatcher = deploy_tick_bitmap();
        
        // Initialize the bitmap with specific ticks{setup_code}
        
        // Test finding next tick: start at {test_tick}, direction={direction}
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word({test_tick}, {tick_spacing}, {str(lte).lower()});
        
        // Expected: tick={expected_tick}, initialized={expected_initialized}
        assert(initialized == {str(expected_initialized).lower()}, 'Wrong initialized state');
        if (initialized) {{
            assert(next_tick == {expected_tick}, 'Wrong tick found');
        }}
    }}
"""
    
    # Special test cases for complex scenarios
    code += """
    #[test]
    fn test_complex_bitmap() {
        let dispatcher = deploy_tick_bitmap();
        
        // Initialize multiple ticks across different words
        dispatcher.flip_tick(0, 1);
        dispatcher.flip_tick(255, 1);
        dispatcher.flip_tick(256, 1);
        dispatcher.flip_tick(-1, 1);
        dispatcher.flip_tick(-256, 1);
        
        // Test finding next tick in different directions
        // Within word 0, from position 100
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 1, true);
        assert(initialized, 'Should find tick');
        assert(next_tick == 0, 'Should find tick 0');
        
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 1, false);
        assert(initialized, 'Should find tick');
        assert(next_tick == 255, 'Should find tick 255');
        
        // From position 300 (in word 1)
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(300, 1, true);
        assert(initialized, 'Should find tick');
        assert(next_tick == 256, 'Should find tick 256');
        
        // From position -100 (in word -1)
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-100, 1, true);
        assert(initialized, 'Should find tick');
        assert(next_tick == -256, 'Should find tick -256');
        
        let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-100, 1, false);
        assert(initialized, 'Should find tick');
        assert(next_tick == -1, 'Should find tick -1');
    }
    """
    
    # Close the module and return the full code
    code += "\n}\n"
    return code

if __name__ == "__main__":
    print(generate_cairo_tests())
