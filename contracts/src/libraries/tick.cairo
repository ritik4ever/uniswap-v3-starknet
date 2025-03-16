#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Info {
    inited: bool,
    liq_gross: u128,
    liq_net: i128,
}

#[starknet::contract]
pub mod Tick {
    use contracts::contract::interface::ITickTrait;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use super::*;

    #[storage]
    struct Storage {
        ticks: Map<felt252, Info>,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[abi(embed_v0)]
    pub impl ITickImpl of ITickTrait<ContractState> {
        fn cross(ref self: ContractState, tick: i32) -> i128 {
            // Read the current tick info
            let mut info = self.ticks.read(tick.into());

            // When crossing a tick, we flip the fee growth outside values
            // This is a simplified version without the full fee tracking
            // In a complete implementation, you would receive and use these values as parameters

            // DO NOT toggle initialization state - that's incorrect
            // A tick's initialization state only changes during liquidity addition/removal

            // Store the updated info back to storage
            self.ticks.write(tick.into(), info);

            // Return the liquidity net value which indicates how much liquidity
            // to add or remove when crossing this tick
            info.liq_net
        }
        fn update(ref self: ContractState, tick: i32, liq_delta: i128, upper: bool) -> bool {
            let mut info = self.ticks.read(tick.into());

            let liq_before = info.liq_gross;
            let liq_after = if liq_delta > 0 {
                liq_before + liq_delta.try_into().unwrap()
            } else {
                liq_before - (-liq_delta).try_into().unwrap()
            };

            let flipped = (liq_after == 0) != (liq_before == 0);

            if liq_before == 0 {
                info.inited = true;
            }

            info.liq_gross = liq_after;

            // Update liquidityNet based on whether it's an upper or lower tick
            // For upper ticks: subtract liquidityDelta
            // For lower ticks: add liquidityDelta
            if upper {
                info.liq_net = info.liq_net - liq_delta;
            } else {
                info.liq_net = info.liq_net + liq_delta;
            }

            if liq_after == 0 {
                info.inited = false;
            }

            self.ticks.write(tick.into(), info);

            flipped
        }
        fn is_init(self: @ContractState, tick: i32) -> bool {
            self.ticks.read(tick.into()).inited
        }
    }
}
