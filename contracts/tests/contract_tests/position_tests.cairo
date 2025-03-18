use contracts::contract::interface::{IPositionTraitDispatcher, IPositionTraitDispatcherTrait};
use contracts::libraries::position::{Info, Key};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
// Helper function to deploy the Position contract
fn deploy_position() -> IPositionTraitDispatcher {
    // Declare the contract
    let contract = declare("Position").unwrap().contract_class();

    // Deploy with empty calldata
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Return a dispatcher for the contract
    IPositionTraitDispatcher { contract_address }
}

// Helper to create a position key
fn create_key(owner_value: felt252, lower_tick: i32, upper_tick: i32) -> Key {
    Key { owner: owner_value.try_into().expect('owner_val'), lower_tick, upper_tick }
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
    dispatcher.update(key, liquidity.try_into().expect('single_pos'));

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
    dispatcher.update(key, initial_liq.try_into().expect('existing_pos0'));

    // Add more liquidity
    let additional_liq: u128 = 500;
    dispatcher.update(key, additional_liq.try_into().expect('existing_pos'));

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
    let initial_liq: i128 = 1000;
    dispatcher.update(key, initial_liq);

    // Amount to remove
    let amount_to_remove: i128 = -400; // Negative to indicate removal

    // Remove some liquidity directly using negative delta
    dispatcher.update(key, amount_to_remove);

    // Check updated position - should have original minus removed
    let info_after = dispatcher.get(key);
    assert(info_after.liq == 600, 'Liquidity removal failed');
}


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

#[test]
fn test_update_to_zero() {
    // Test updating a position to exactly zero liquidity
    let dispatcher = deploy_position();
    let key = create_key(0x123, 100, 200);

    // Add initial liquidity
    dispatcher.update(key, 1000);

    // Get current liquidity and create a negative delta to remove all
    let info = dispatcher.get(key);
    let remove_all: i128 = -(info.liq.try_into().unwrap());

    // Remove all liquidity using negative delta
    dispatcher.update(key, remove_all);

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
    dispatcher.update(key, large_liq.try_into().expect('large_liq'));

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
        create_key(0x555, 100, 200),
    ];

    // Add different amounts of liquidity
    let mut i = 0;
    while i < keys.len() {
        let key = keys.at(i);
        let i_u128: u128 = (i + 1).into(); // Convert u32 to u128
        let liq = i_u128 * 1000_u128;
        dispatcher.update(*key, liq.try_into().expect('diff_owners'));
        i += 1;
    }

    // Verify each position
    let mut j = 0;
    while j < keys.len() {
        let key = keys.at(j);
        let j_u128: u128 = (j + 1).into(); // Convert u32 to u128
        let expected_liq = j_u128 * 1000_u128;
        let info = dispatcher.get(*key);
        assert(info.liq == expected_liq, 'Position liquidity incorrect');
        j += 1;
    }
}

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

    assert(info.liq == 1000, 'tick position incorrect');
    assert(info_cross.liq == 2000, 'Cross-zero position incorrect');
}

#[test]
fn test_multiple_updates_same_position() {
    // Test multiple updates to the same position
    let dispatcher = deploy_position();
    let key = create_key(0x123, 100, 200);

    // Sequence of updates
    dispatcher.update(key, 1000); // 0 -> 1000
    dispatcher.update(key, 500); // 1000 -> 1500

    // Get current liquidity and remove all of it
    let info_mid = dispatcher.get(key);
    let remove_all: i128 = -(info_mid.liq.try_into().unwrap());
    dispatcher.update(key, remove_all); // Reset to 0 using negative delta

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
