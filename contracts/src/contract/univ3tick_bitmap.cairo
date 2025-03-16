#[starknet::contract]
pub mod TickBitmap {
    use alexandria_math::const_pow::pow2_u256;
    use contracts::contract::interface::IUniswapV3TickBitmap;
    use contracts::libraries::utils::math::{least_significant_bit, most_significant_bit, u256_max};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    #[storage]
    struct Storage {
        /// in Uniswap V3 this is `mapping(int16 => uint256)`
        /// [source](https://uniswapv3book.com/milestone_2/tick-bitmap-index.html#tickbitmap-contract)
        bitmap: Map<i16, u256>,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[abi(embed_v0)]
    impl IUniswapV3TickBitmapImpl of IUniswapV3TickBitmap<ContractState> {
        fn flip_tick(ref self: ContractState, tick: i32, tick_spacing: i32) {
            assert(tick % tick_spacing == 0, 'undivisible by tick_spacing');

            let compressed_tick = tick / tick_spacing;

            let (word_pos, bit_pos) = InternalImpl::position(compressed_tick);

            // mask with a 1 at the bit position (ignore plugin warning)
            let mask = 1_u256 * (pow2_u256(bit_pos.into()));

            // XOR the current word with the mask to flip the bit
            let current_word = self.bitmap.read(word_pos);
            let new_word = current_word ^ mask;

            self.bitmap.write(word_pos, new_word);
        }

        fn next_initialized_tick_within_one_word(
            self: @ContractState, tick: i32, tick_spacing: i32, lte: bool,
        ) -> (i32, bool) {
            let compressed_tick = tick / tick_spacing;

            let (word_pos, bit_pos) = InternalImpl::position(compressed_tick);

            let word = self.bitmap.read(word_pos);

            let word_pos_i32: i32 = word_pos.into();

            if lte {
                let mask = if bit_pos == 255_u8 {
                    u256_max()
                } else {
                    // ignore diagnostic
                    (1_u256 * (pow2_u256(bit_pos.into() + 1))) - 1
                };

                let masked_word = word & mask;

                if masked_word != 0 {
                    let msb = most_significant_bit(masked_word);
                    return ((word_pos_i32 * 256 + msb) * tick_spacing, true);
                }
            } else {
                // Create mask for positions > bit_pos
                let mask = if bit_pos == 255_u8 {
                    0_u256
                } else {
                    u256_max() - ((1_u256 * pow2_u256(bit_pos.into() + 1)) - 1)
                };

                let masked_word = word & mask;

                if masked_word != 0 {
                    let lsb = least_significant_bit(masked_word);
                    return ((word_pos_i32 * 256 + lsb) * tick_spacing, true);
                }
            }

            let next_tick = if lte {
                ((word_pos_i32 - 1) * 256 + 255) * tick_spacing
            } else {
                (word_pos_i32 + 1) * 256 * tick_spacing
            };

            (next_tick, false)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn position(tick: i32) -> (i16, u8) {
            // shift right by 8 (divide by 2**8) to calculate the positions
            let word_pos: i16 = (tick / 256).try_into().unwrap();
            let bit_pos: u8 = (tick % 256).try_into().unwrap();

            // If tick is negative and not a multiple of 256, we need to adjust the position
            // This ensures correct handling of negative ticks
            let (adjusted_word_pos, adjusted_bit_pos) = if tick < 0 && tick % 256 != 0 {
                (word_pos - 1, 255_u8 - (((-tick) % 256) - 1).try_into().unwrap())
            } else {
                (word_pos, bit_pos.try_into().unwrap())
            };

            (adjusted_word_pos, adjusted_bit_pos)
        }
    }
}
