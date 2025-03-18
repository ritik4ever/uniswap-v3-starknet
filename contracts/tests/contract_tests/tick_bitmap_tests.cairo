use contracts::contract::interface::{
    IUniswapV3TickBitmapDispatcher, IUniswapV3TickBitmapDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};

fn deploy_tick_bitmap() -> IUniswapV3TickBitmapDispatcher {
    // Declare the contract
    let contract = declare("TickBitmap").unwrap().contract_class();

    // Deploy with empty calldata
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    // Return a dispatcher for the contract
    IUniswapV3TickBitmapDispatcher { contract_address }
}

#[test]
fn test_flip_tick_simple_positive() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=10, tick_spacing=1
    // Word position: 0, bit position: 10

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(10, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 10, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(10, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_simple_negative() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=-10, tick_spacing=1
    // Word position: -2, bit position: 246

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-10, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(-10, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-10, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == -10, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(-10, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-10, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_tick_spacing_2() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=20, tick_spacing=2
    // Word position: 0, bit position: 10

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 2, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(20, 2);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 2, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 20, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(20, 2);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 2, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_tick_spacing_10() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=100, tick_spacing=10
    // Word position: 0, bit position: 10

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 10, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(100, 10);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 10, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 100, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(100, 10);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 10, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_edge_zero() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=0, tick_spacing=1
    // Word position: 0, bit position: 0

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(0, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(0, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(0, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 0, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(0, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(0, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_edge_word_boundary() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=255, tick_spacing=1
    // Word position: 0, bit position: 255

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(255, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(255, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(255, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 255, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(255, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(255, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_flip_twice() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=10, tick_spacing=1
    // Word position: 0, bit position: 10

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(10, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 10, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(10, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_flip_tick_multiple_flips() {
    let dispatcher = deploy_tick_bitmap();

    // Test for tick=20, tick_spacing=1
    // Word position: 0, bit position: 20

    // Verify initial state (empty bitmap)
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 1, true);
    assert(!initialized, 'Tick should not be initialized');

    // Flip the tick
    dispatcher.flip_tick(20, 1);

    // Verify tick is now initialized
    let (found_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 1, true);
    assert(initialized, 'Tick should be initialized');
    assert(found_tick == 20, 'Wrong tick found');

    // Flip it again to clear
    dispatcher.flip_tick(20, 1);

    // Verify it's uninitialized again
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(20, 1, true);
    assert(!initialized, 'Tick should be uninitialized');
}

#[test]
fn test_next_tick_single_tick_lte_match() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 100, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 1, true);

    // Expected: tick=100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_single_tick_lte_above() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 150, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(150, 1, true);

    // Expected: tick=100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_single_tick_lte_below() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 50, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(50, 1, true);

    // Expected: tick=-1, initialized=False
    assert(initialized == false, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == -1, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_single_tick_gt_match() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 100, direction=gt
    let (_next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(100, 1, false);

    // When searching GT from an initialized tick, we should NOT find the current tick
    assert(initialized == false, 'Wrong initialized state');

    // Alternative test: search from 99 to find 100
    let (next_tick_from_99, initialized_from_99) = dispatcher
        .next_initialized_tick_within_one_word(99, 1, false);
    assert(initialized_from_99 == true, 'Should find from lower tick');
    assert(next_tick_from_99 == 100, 'Should find tick 100');
}


#[test]
fn test_next_tick_single_tick_gt_below() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 50, direction=gt
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(50, 1, false);

    // Expected: tick=100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_single_tick_gt_above() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(100, 1);

    // Test finding next tick: start at 150, direction=gt
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(150, 1, false);

    // Expected: tick=256, initialized=False
    assert(initialized == false, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 256, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_multiple_ticks_lte() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(50, 1);
    dispatcher.flip_tick(100, 1);
    dispatcher.flip_tick(150, 1);

    // Test finding next tick: start at 120, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(120, 1, true);

    // Expected: tick=100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_multiple_ticks_gt() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(50, 1);
    dispatcher.flip_tick(100, 1);
    dispatcher.flip_tick(150, 1);

    // Test finding next tick: start at 80, direction=gt
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(80, 1, false);

    // Expected: tick=100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_word_boundary_low_lte() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(0, 1);

    // Test finding next tick: start at 10, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(10, 1, true);

    // Expected: tick=0, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 0, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_word_boundary_high_gt() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(255, 1);

    // Test finding next tick: start at 250, direction=gt
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(250, 1, false);

    // Expected: tick=255, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == 255, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_negative_tick_lte() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(-100, 1);
    dispatcher.flip_tick(-50, 1);

    // Test finding next tick: start at -75, direction=lte
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-75, 1, true);

    // Expected: tick=-100, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == -100, 'Wrong tick found');
    }
}

#[test]
fn test_next_tick_negative_tick_gt() {
    let dispatcher = deploy_tick_bitmap();

    // Initialize the bitmap with specific ticks
    dispatcher.flip_tick(-100, 1);
    dispatcher.flip_tick(-50, 1);

    // Test finding next tick: start at -75, direction=gt
    let (next_tick, initialized) = dispatcher.next_initialized_tick_within_one_word(-75, 1, false);

    // Expected: tick=-50, initialized=True
    assert(initialized == true, 'Wrong initialized state');
    if (initialized) {
        assert(next_tick == -50, 'Wrong tick found');
    }
}

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

