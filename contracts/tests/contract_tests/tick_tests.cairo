use contracts::contract::interface::{ITickTraitDispatcher, ITickTraitDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};

// Helper function to deploy the Tick contract
fn deploy_tick() -> ITickTraitDispatcher {
    // Declare the contract
    let contract = declare("Tick").unwrap().contract_class();

    // Deploy with empty calldata
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Return a dispatcher for the contract
    ITickTraitDispatcher { contract_address }
}

#[test]
fn test_update_initialize_lower_tick() {
    // Test initializing a tick as a lower tick (not upper)
    let dispatcher = deploy_tick();

    // Tick not initialized initially
    let init_before = dispatcher.is_init(100);
    assert(!init_before, 'Tick should not be initialized');

    // Add 1000 units of liquidity to tick 100 (lower tick)
    let liq_delta: i128 = 1000;
    let upper = false; // It's a lower tick
    let flipped = dispatcher.update(100, liq_delta, upper);

    // Verify initialization state flipped
    assert(flipped, 'Init state should be flipped');

    // Verify tick is now initialized
    let init_after = dispatcher.is_init(100);
    assert(init_after, 'Tick should be initialized');

    // Verify crossing the tick returns the correct liquidity value
    let liq_net = dispatcher.cross(100);
    assert(liq_net == 1000, ' incorrect liquidity net');
}

#[test]
fn test_update_initialize_upper_tick() {
    // Test initializing a tick as an upper tick
    let dispatcher = deploy_tick();

    // Add 1000 units of liquidity to tick 200 (upper tick)
    let liq_delta: i128 = 1000;
    let upper = true; // It's an upper tick
    let flipped = dispatcher.update(200, liq_delta, upper);

    // Verify initialization state flipped
    assert(flipped, 'Init state should be flipped');

    // Verify crossing the tick returns negative liquidity value for upper tick
    let liq_net = dispatcher.cross(200);
    assert(liq_net == -1000, 'Should get negative liquidity');
}

#[test]
fn test_update_add_more_liquidity() {
    // Test adding more liquidity to an existing tick
    let dispatcher = deploy_tick();

    // First add 1000 units
    dispatcher.update(100, 1000, false);

    // Then add 500 more
    let flipped = dispatcher.update(100, 500, false);

    // Verify initialization state didn't flip
    assert(!flipped, 'Init state should not change');

    // Verify crossing returns the sum of both updates
    let liq_net = dispatcher.cross(100);
    assert(liq_net == 1500, 'Should get combined liquidity');
}

#[test]
fn test_update_remove_some_liquidity() {
    // Test removing some (but not all) liquidity
    let dispatcher = deploy_tick();

    // First add 1000 units
    dispatcher.update(100, 1000, false);

    // Then remove 600
    let flipped = dispatcher.update(100, -600, false);

    // Verify initialization state didn't flip
    assert(!flipped, 'Init state should not change');

    // Verify crossing returns the remaining liquidity
    let liq_net = dispatcher.cross(100);
    assert(liq_net == 400, 'Should get remaining liquidity');
}

#[test]
fn test_update_remove_all_liquidity() {
    // Test removing all liquidity, causing tick to be uninitialized
    let dispatcher = deploy_tick();

    // First add 1000 units
    dispatcher.update(100, 1000, false);

    // Then remove all 1000
    let flipped = dispatcher.update(100, -1000, false);

    // Verify initialization state flipped back
    assert(flipped, 'Init state should flip back');

    // Verify tick is no longer initialized
    let init_after = dispatcher.is_init(100);
    assert(!init_after, 'Tick should be uninitialized');
}

#[test]
fn test_update_with_opposite_values() {
    // Test adding liquidity with opposite values for upper/lower ticks
    let dispatcher = deploy_tick();

    // Initialize lower tick
    dispatcher.update(100, 1000, false);

    // Initialize upper tick with same liquidity
    dispatcher.update(200, 1000, true);

    // Verify net liquidity values are opposite
    let lower_liq = dispatcher.cross(100);
    let upper_liq = dispatcher.cross(200);

    assert(lower_liq == 1000, 'Lower tick should be +1000');
    assert(upper_liq == -1000, 'Upper tick should be -1000');
}

#[test]
fn test_cross_uninitialized_tick() {
    // Test crossing a tick that hasn't been initialized
    let dispatcher = deploy_tick();

    // Cross an uninitialized tick
    let liq_net = dispatcher.cross(300);

    // Should return 0 for uninitialized tick
    assert(liq_net == 0, 'Uninitialized should return 0');
}

#[test]
fn test_multiple_crosses() {
    // Test crossing a tick multiple times
    let dispatcher = deploy_tick();

    // Initialize tick
    dispatcher.update(100, 1000, false);

    // First cross
    let liq_net1 = dispatcher.cross(100);
    assert(liq_net1 == 1000, 'First cross should be +1000');

    // Second cross - should return the same value
    let liq_net2 = dispatcher.cross(100);
    assert(liq_net2 == 1000, 'Second cross should be +1000');
}

#[test]
fn test_cross_with_multiple_updates() {
    // Test crossing a tick that has had multiple updates
    let dispatcher = deploy_tick();

    // Series of updates: add 1000, remove 500, add 200
    dispatcher.update(100, 1000, false); // +1000
    dispatcher.update(100, -500, false); // -500
    dispatcher.update(100, 200, false); // +200

    // Final net liquidity should be 700
    let liq_net = dispatcher.cross(100);
    assert(liq_net == 700, 'Should get net of all updates');
}

#[test]
fn test_is_init_lifecycle() {
    // Test the is_init function through a tick's lifecycle
    let dispatcher = deploy_tick();

    // Check initial state
    let init0 = dispatcher.is_init(100);
    assert(!init0, 'Should start uninitialized');

    // Initialize
    dispatcher.update(100, 1000, false);
    let init1 = dispatcher.is_init(100);
    assert(init1, 'Should initialize after update');

    // Remove some liquidity
    dispatcher.update(100, -500, false);
    let init2 = dispatcher.is_init(100);
    assert(init2, 'Should remain initialized');

    // Remove remaining liquidity
    dispatcher.update(100, -500, false);
    let init3 = dispatcher.is_init(100);
    assert(!init3, 'Should uninitialize');
}

#[test]
fn test_multiple_ticks_scenario() {
    // Comprehensive test with multiple ticks in a realistic scenario
    let dispatcher = deploy_tick();

    // Initialize several ticks representing a price range
    // Lower tick
    dispatcher.update(100, 2000, false);
    // Upper tick
    dispatcher.update(200, 2000, true);

    // Verify initialization
    assert(dispatcher.is_init(100), 'Lower tick should be init');
    assert(dispatcher.is_init(200), 'Upper tick should be init');

    // Cross lower tick (entering the range)
    let liq_change_enter = dispatcher.cross(100);
    assert(liq_change_enter == 2000, 'Entering range should add liq');

    // Cross upper tick (exiting the range)
    let liq_change_exit = dispatcher.cross(200);
    assert(liq_change_exit == -2000, 'should remove liquidity');

    // Simulate adding more liquidity to the same range
    dispatcher.update(100, 1000, false);
    dispatcher.update(200, 1000, true);

    // Cross back into the range (upper to lower)
    let liq_change_reenter = dispatcher.cross(200);
    assert(liq_change_reenter == -3000, 'Re-crossing with more liq');
}

#[test]
fn test_overlapping_positions() {
    // Test with overlapping positions that create different liquidity levels
    let dispatcher = deploy_tick();

    // Position 1: tick range 100-300
    dispatcher.update(100, 1000, false); // Lower tick adds liquidity
    dispatcher.update(300, 1000, true); // Upper tick removes liquidity

    // Position 2: tick range 200-400
    dispatcher.update(200, 2000, false); // Lower tick adds liquidity
    dispatcher.update(400, 2000, true); // Upper tick removes liquidity

    // Verify liquidity changes when crossing ticks
    let liq_at_100 = dispatcher.cross(100);
    assert(liq_at_100 == 1000, 'Should add 1000 at tick 100');

    let liq_at_200 = dispatcher.cross(200);
    assert(liq_at_200 == 2000, 'Should add 2000 at tick 200');

    let liq_at_300 = dispatcher.cross(300);
    assert(liq_at_300 == -1000, 'Should remove 1000 at tick 300');

    let liq_at_400 = dispatcher.cross(400);
    assert(liq_at_400 == -2000, 'Should remove 2000 at tick 400');
}

#[test]
fn test_negative_and_positive_liquidity_delta() {
    // Test with both negative and positive liquidity deltas
    let dispatcher = deploy_tick();

    // Add liquidity with a large positive delta
    let large_delta: i128 = 10000000;
    dispatcher.update(100, large_delta, false);

    // Remove liquidity with a negative delta
    let negative_delta: i128 = -5000000;
    dispatcher.update(100, negative_delta, false);

    // Expected net liquidity
    let expected_net = large_delta + negative_delta;

    // Verify net liquidity
    let actual_net = dispatcher.cross(100);
    assert(actual_net == expected_net, 'Net liquidity should be correct');
}

#[test]
fn test_zero_liquidity_delta() {
    // Test with a zero liquidity delta
    let dispatcher = deploy_tick();

    // Update with zero delta (should have no effect)
    let flipped = dispatcher.update(100, 0, false);

    // Should not flip initialization state
    assert(!flipped, 'Zero delta shouldnt flip state');

    // Tick should remain uninitialized
    assert(!dispatcher.is_init(100), 'Should remain uninitialized');
}

#[test]
fn test_extreme_tick_values() {
    // Test with extreme tick values
    let dispatcher = deploy_tick();

    // Min tick value
    let min_tick: i32 = -887272;
    dispatcher.update(min_tick, 1000, false);
    assert(dispatcher.is_init(min_tick), 'Min tick should initialize');

    // Max tick value
    let max_tick: i32 = 887272;
    dispatcher.update(max_tick, 1000, true);
    assert(dispatcher.is_init(max_tick), 'Max tick should initialize');

    // Cross both ticks
    let min_liq = dispatcher.cross(min_tick);
    let max_liq = dispatcher.cross(max_tick);

    assert(min_liq == 1000, 'Min tick liquidity incorrect');
    assert(max_liq == -1000, 'Max tick liquidity incorrect');
}

