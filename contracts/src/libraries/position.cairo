#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Info {
    liq: u128
}


#[derive(Copy, Drop, Serde, starknet::Store, Hash)]
pub struct Key {
    owner: starknet::ContractAddress,
    lower_tick: i32,
    upper_tick: i32,
}

#[starknet::contract]
mod Position {
    use core::hash::HashStateTrait;
use core::hash::HashStateExTrait;
use super::*;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use contracts::contract::interface::IPositionTrait;
    use core::poseidon::PoseidonTrait;

    #[storage]
    struct Storage {
        positions: Map<felt252, Info>
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
    }

    #[abi(embed_v0)]
    impl IPositionImpl of IPositionTrait<ContractState>{
        fn update(ref self: ContractState, key: Key, liq_delta: u128) {
            let hash = PoseidonTrait::new().update_with(key).finalize();
            let mut info = self.positions.read(hash);
            let liq_after = liq_delta + info.liq; // info.liq is liq_before
            info.liq = liq_after;
            self.positions.write(hash, info);
        }

        fn get(self: @ContractState, key: Key) -> Info {
            let hash = PoseidonTrait::new().update_with(key).finalize();
            self.positions.read(hash)
        }
    }
}

