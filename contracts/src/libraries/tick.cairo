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

    pub impl ITickImpl of ITickTrait<ContractState> {
        fn update(ref self: ContractState, tick: i32, liq_delta: i128, upper: bool) -> bool {
            let mut info = self.ticks.read(tick.into());

            // Calculate liquidity before and after
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
