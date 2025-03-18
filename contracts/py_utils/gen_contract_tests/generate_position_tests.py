def generate_position_tests():
    """Generate Cairo test code for the Position contract"""
    
    code = """
// Position Contract Tests - Auto-generated

use contracts::contract::interface::IPositionTrait;
use contracts::contract::interface::IPositionTraitDispatcher;
use starknet::{ContractAddress, deploy_syscall, get_caller_address, contract_address_const};
use starknet::class_hash::declare;
use core::result::ResultTrait;
use contracts::contract::position::{Key, Info};

#[test]
mod position_tests {
    use super::*;
    
    // Helper function to deploy the Position contract
    fn deploy_position() -> IPositionTraitDispatcher {
        // Declare the contract
        let contract = declare("Position").unwrap();
        
        // Deploy with empty calldata
        let (contract_address, _) = contract.deploy(@array![]).unwrap();
        
        // Return a dispatcher for the contract
        IPositionTraitDispatcher { contract_address }
    }
    
    // Helper to create a position key
    fn create_key(owner_value: felt252, lower_tick: i32, upper_tick: i32) -> Key {
        Key {
            owner: contract_address_const::<owner_value>(),
            lower_tick,
            upper_tick,
        }
    }
    
    // Helper to compare Info structs
    fn assert_info_equal(a: Info, b: Info, message: felt252) {
        assert(a.liq == b.liq, message);
    }

    #[test]
    fn test_setup() {
        // Simple test to ensure deployment works
        let dispatcher = deploy_position();
        // Get a position that doesn't exist yet
        let key = create_key(0x123, 100, 200);
        let info = dispatcher.get(key);
        
        // Should return zero liquidity
        assert(info.liq == 0, 'Initial liquidity should be 0');
    }
    """
    
    # Test cases for basic position operations
    
    code += """
    #[test]
    fn test_create_single_position() {
        // Test creating a single position
        let dispatcher = deploy_position();
        
        // Create a position key
        let key = create_key(0x123, 100, 200);
        
        // Initially should have zero liquidity
        let info_before = dispatcher.get(key);
        assert(info_before.liq == 0, 'Initial liquidity should be 0');
        
        // Add liquidity
        let liquidity: u128 = 1000;
        dispatcher.update(key, liquidity);
        
        // Check updated position
        let info_after = dispatcher.get(key);
        assert(info_after.liq == liquidity, 'Liquidity not updated correctly');
    }
    
    #[test]
    fn test_add_to_existing_position() {
        // Test adding liquidity to an existing position
        let dispatcher = deploy_position();
        let key = create_key(0x123, 100, 200);
        
        // Add initial liquidity
        let initial_liq: u128 = 1000;
        dispatcher.update(key, initial_liq);
        
        // Add more liquidity
        let additional_liq: u128 = 500;
        dispatcher.update(key, additional_liq);
        
        // Check updated position
        let info = dispatcher.get(key);
        assert(info.liq == initial_liq + additional_liq, 'Liquidity addition failed');
    }
    
    #[test]
    fn test_remove_liquidity() {
        // Test removing liquidity from a position
        let dispatcher = deploy_position();
        let key = create_key(0x123, 100, 200);
        
        // Add initial liquidity
        let initial_liq: u128 = 1000;
        dispatcher.update(key, initial_liq);
        
        // Remove some liquidity using a liq_delta of 0
        // Since the contract does a direct addition, we need to update liq_after manually
        let info_before = dispatcher.get(key);
        let amount_to_remove: u128 = 400;
        let new_liq = if info_before.liq > amount_to_remove {
            info_before.liq - amount_to_remove
        } else {
            0
        };
        
        // Update with the manually calculated delta
        let liq_delta = new_liq - info_before.liq + amount_to_remove;
        dispatcher.update(key, liq_delta);
        
        // Check updated position
        let info_after = dispatcher.get(key);
        assert(info_after.liq == new_liq, 'Liquidity removal failed');
    }
    """
    
    # Test cases for multiple positions
    
    code += """
    #[test]
    fn test_multiple_positions_different_owners() {
        // Test multiple positions with different owners
        let dispatcher = deploy_position();
        
        // Create positions for different owners
        let key1 = create_key(0x123, 100, 200);
        let key2 = create_key(0x456, 100, 200);
        
        // Add liquidity to both positions
        dispatcher.update(key1, 1000);
        dispatcher.update(key2, 2000);
        
        // Check each position independently
        let info1 = dispatcher.get(key1);
        let info2 = dispatcher.get(key2);
        
        assert(info1.liq == 1000, 'Position 1 incorrect');
        assert(info2.liq == 2000, 'Position 2 incorrect');
    }
    
    #[test]
    fn test_multiple_positions_different_ticks() {
        // Test multiple positions with different tick ranges
        let dispatcher = deploy_position();
        
        // Same owner, different tick ranges
        let key1 = create_key(0x123, 100, 200);
        let key2 = create_key(0x123, 150, 250);
        let key3 = create_key(0x123, 50, 150);
        
        // Add liquidity to all positions
        dispatcher.update(key1, 1000);
        dispatcher.update(key2, 2000);
        dispatcher.update(key3, 3000);
        
        // Check each position independently
        let info1 = dispatcher.get(key1);
        let info2 = dispatcher.get(key2);
        let info3 = dispatcher.get(key3);
        
        assert(info1.liq == 1000, 'Position 1 incorrect');
        assert(info2.liq == 2000, 'Position 2 incorrect');
        assert(info3.liq == 3000, 'Position 3 incorrect');
    }
    
    #[test]
    fn test_overlapping_positions() {
        // Test overlapping positions for the same owner
        let dispatcher = deploy_position();
        
        // Create overlapping positions
        // Full range: 100-300
        let key_full = create_key(0x123, 100, 300);
        // Lower half: 100-200
        let key_lower = create_key(0x123, 100, 200);
        // Upper half: 200-300
        let key_upper = create_key(0x123, 200, 300);
        
        // Add liquidity to all positions
        dispatcher.update(key_full, 1000);
        dispatcher.update(key_lower, 2000);
        dispatcher.update(key_upper, 3000);
        
        // Check each position independently
        let info_full = dispatcher.get(key_full);
        let info_lower = dispatcher.get(key_lower);
        let info_upper = dispatcher.get(key_upper);
        
        assert(info_full.liq == 1000, 'Full range position incorrect');
        assert(info_lower.liq == 2000, 'Lower range position incorrect');
        assert(info_upper.liq == 3000, 'Upper range position incorrect');
    }
    """
    
    # Test cases for edge cases and limits
    
    code += """
    #[test]
    fn test_update_to_zero() {
        // Test updating a position to exactly zero liquidity
        let dispatcher = deploy_position();
        let key = create_key(0x123, 100, 200);
        
        // Add initial liquidity
        dispatcher.update(key, 1000);
        
        // Get current liquidity to calculate the update to zero
        let info = dispatcher.get(key);
        let remove_all_delta = info.liq;
        
        // Instead of calculating remove delta, we directly set the new value
        // This is different from how Uniswap V3 handles it, but matches your implementation
        dispatcher.update(key, 0);
        
        // Check position has zero liquidity
        let info_after = dispatcher.get(key);
        assert(info_after.liq == 0, 'Should have zero liquidity');
    }
    
    #[test]
    fn test_large_liquidity_values() {
        // Test with large liquidity values near u128 limits
        let dispatcher = deploy_position();
        let key = create_key(0x123, 100, 200);
        
        // Use a large but safe value for u128
        let large_liq: u128 = 340282366920938463463374607431768211455_u128 / 2; // Max u128 / 2
        dispatcher.update(key, large_liq);
        
        // Check position has correct liquidity
        let info = dispatcher.get(key);
        assert(info.liq == large_liq, 'Large liquidity incorrect');
    }
    
    #[test]
    fn test_same_tick_different_owners() {
        // Test same tick range for different owners
        let dispatcher = deploy_position();
        
        // Create many positions with same ticks, different owners
        let keys = array![
            create_key(0x111, 100, 200),
            create_key(0x222, 100, 200),
            create_key(0x333, 100, 200),
            create_key(0x444, 100, 200),
            create_key(0x555, 100, 200)
        ];
        
        // Add different amounts of liquidity
        let mut i = 0;
        while i < keys.len() {
            let key = keys.at(i);
            let liq = (i + 1) * 1000_u128;
            dispatcher.update(*key, liq);
            i += 1;
        }
        
        // Verify each position
        let mut j = 0;
        while j < keys.len() {
            let key = keys.at(j);
            let expected_liq = (j + 1) * 1000_u128;
            let info = dispatcher.get(*key);
            assert(info.liq == expected_liq, 'Position liquidity incorrect');
            j += 1;
        }
    }
    """
    
    # Test cases for boundary tick values
    
    code += """
    #[test]
    fn test_min_max_ticks() {
        // Test with minimum and maximum tick values
        let dispatcher = deploy_position();
        
        // Create a position with extreme tick values
        let min_tick: i32 = -887272;
        let max_tick: i32 = 887272;
        
        let key = create_key(0x123, min_tick, max_tick);
        dispatcher.update(key, 1000);
        
        // Check position
        let info = dispatcher.get(key);
        assert(info.liq == 1000, 'Extreme tick position incorrect');
    }
    
    #[test]
    fn test_negative_ticks() {
        // Test with negative tick values
        let dispatcher = deploy_position();
        
        // Position entirely in negative tick range
        let key = create_key(0x123, -200, -100);
        dispatcher.update(key, 1000);
        
        // Position spanning across zero
        let key_cross_zero = create_key(0x123, -100, 100);
        dispatcher.update(key_cross_zero, 2000);
        
        // Check positions
        let info = dispatcher.get(key);
        let info_cross = dispatcher.get(key_cross_zero);
        
        assert(info.liq == 1000, 'Negative tick position incorrect');
        assert(info_cross.liq == 2000, 'Cross-zero position incorrect');
    }
    """
    
    # Test cases for complex update patterns
    
    code += """
    #[test]
    fn test_multiple_updates_same_position() {
        // Test multiple updates to the same position
        let dispatcher = deploy_position();
        let key = create_key(0x123, 100, 200);
        
        // Sequence of updates
        dispatcher.update(key, 1000); // 0 -> 1000
        dispatcher.update(key, 500);  // 1000 -> 1500
        dispatcher.update(key, 0);    // Reset to 0 using direct value
        dispatcher.update(key, 2000); // 0 -> 2000
        dispatcher.update(key, 1000); // 2000 -> 3000
        
        // Check final position
        let info = dispatcher.get(key);
        assert(info.liq == 3000, 'Final liquidity incorrect');
    }
    
    #[test]
    fn test_complex_scenario() {
        // More complex scenario with multiple operations
        let dispatcher = deploy_position();
        
        // Create several positions
        let key1 = create_key(0x111, 100, 200);
        let key2 = create_key(0x222, 150, 250);
        let key3 = create_key(0x111, 100, 200); // Same as key1
        
        // Series of operations
        dispatcher.update(key1, 1000);
        dispatcher.update(key2, 2000);
        
        // key3 is the same as key1, so this should update the same position
        dispatcher.update(key3, 500);
        
        // Check positions
        let info1 = dispatcher.get(key1);
        let info2 = dispatcher.get(key2);
        
        // key1 and key3 are the same position
        assert(info1.liq == 1500, 'Key1 liquidity incorrect');
        assert(info2.liq == 2000, 'Key2 liquidity incorrect');
    }
    """
    
    # Close the module
    code += """
}  // End of position_tests module
"""
    
    return code

if __name__ == "__main__":
    test_code = generate_position_tests()
    print(test_code)
