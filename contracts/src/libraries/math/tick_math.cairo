pub mod TickMath {
    // HIGH P TODO: Unit tests

    use alexandria_math::const_pow::pow2_u256;
    use alexandria_math::i257::{I257Impl, i257};
    use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl};

    // The minimum tick that can be used
    const MIN_TICK: i32 = -887272;
    // The maximum tick that can be used
    const MAX_TICK: i32 = 887272;
    // Minimum sqrt ratio (corresponding to MIN_TICK)
    const MIN_SQRT_RATIO: u256 = 4295128739;
    // Maximum sqrt ratio (corresponding to MAX_TICK)
    const MAX_SQRT_RATIO: u256 = 1461446703485210103287273052203988822378723970342;

    /// Calculates sqrt(1.0001^tick) * 2^96
    /// @param tick The tick for which to compute the sqrt ratio
    /// @return The sqrt ratio as a Q64.96 fixed point number
    fn get_sqrt_ratio_at_tick(tick: i32) -> FixedQ64x96 {
        // Validate tick is within bounds
        assert(tick >= MIN_TICK, 'Tick below MIN_TICK');
        assert(tick <= MAX_TICK, 'Tick above MAX_TICK');

        let abs_tick = if tick < 0 {
            -tick
        } else {
            tick
        };
        let abs_tick_u256: u256 = u256 { low: abs_tick.try_into().unwrap(), high: 0 };

        // Start with base ratio
        let mut ratio = if (abs_tick_u256 & 0x1_u256) != 0_u256 {
            0xfffcb933bd6fad37aa2d162d1a594001_u256
        } else {
            0x100000000000000000000000000000000_u256
        };

        // Perform bit checks and adjustments
        if (abs_tick_u256 & 0x2_u256) != 0_u256 {
            ratio = (ratio * 0xfff97272373d413259a46990580e213a_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x4_u256) != 0_u256 {
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x8_u256) != 0_u256 {
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x10_u256) != 0_u256 {
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x20_u256) != 0_u256 {
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x40_u256) != 0_u256 {
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x80_u256) != 0_u256 {
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x100_u256) != 0_u256 {
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x200_u256) != 0_u256 {
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x400_u256) != 0_u256 {
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x800_u256) != 0_u256 {
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x1000_u256) != 0_u256 {
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x2000_u256) != 0_u256 {
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x4000_u256) != 0_u256 {
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x8000_u256) != 0_u256 {
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x10000_u256) != 0_u256 {
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x20000_u256) != 0_u256 {
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x40000_u256) != 0_u256 {
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98_u256) / pow2_u256(128);
        }
        if (abs_tick_u256 & 0x80000_u256) != 0_u256 {
            ratio = (ratio * 0x48a170391f7dc42444e8fa2_u256) / pow2_u256(128);
        }

        // If tick is positive, invert the ratio
        if tick > 0 {
            // Using an arbitrary large number for division
            // For a more accurate implementation, calculate 2^256 - 1 or similar max value
            let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff_u256;
            ratio = max_u256 / ratio;
        }

        // Convert to Q64.96 format (from Q128.128)
        // We divide by 2^32 and round up
        let mut sqrt_price_x96 = ratio / pow2_u256(32);
        if ratio % pow2_u256(32) > 0 {
            sqrt_price_x96 += 1; // Round up
        }

        // Ensure result is within bounds
        if sqrt_price_x96 < MIN_SQRT_RATIO {
            return IFixedQ64x96Impl::new(MIN_SQRT_RATIO);
        }
        if sqrt_price_x96 > MAX_SQRT_RATIO {
            return IFixedQ64x96Impl::new(MAX_SQRT_RATIO);
        }

        IFixedQ64x96Impl::new(sqrt_price_x96)
    }

    /// Calculates the greatest tick value such that `get_sqrt_ratio_at_tick(tick) <= sqrt_ratio`
    /// @param sqrt_ratio_x96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return The greatest tick for which the ratio is less than or equal to the input ratio
    fn get_tick_at_sqrt_ratio(sqrt_ratio_x96: FixedQ64x96) -> i32 {
        // Validate price is within bounds
        assert(sqrt_ratio_x96.value >= MIN_SQRT_RATIO, 'sqrt price too low');
        assert(sqrt_ratio_x96.value < MAX_SQRT_RATIO, 'sqrt price too high');

        // Shift left by 32 bits
        let ratio = sqrt_ratio_x96.value * pow2_u256(32);
        let mut r = ratio;
        let mut msb = 0;

        // Find most significant bit position using binary search
        if r >= 0x100000000000000000000000000000000_u256 {
            r = r / pow2_u256(128);
            msb += 128;
        }
        if r >= 0x10000000000000000_u256 {
            r = r / pow2_u256(64);
            msb += 64;
        }
        if r >= 0x100000000_u256 {
            r = r / pow2_u256(32);
            msb += 32;
        }
        if r >= 0x10000_u256 {
            r = r / pow2_u256(16);
            msb += 16;
        }
        if r >= 0x100_u256 {
            r = r / pow2_u256(8);
            msb += 8;
        }
        if r >= 0x10_u256 {
            r = r / pow2_u256(4);
            msb += 4;
        }
        if r >= 0x4_u256 {
            r = r / pow2_u256(2);
            msb += 2;
        }
        if r >= 0x2_u256 {
            msb += 1;
        }

        // Adjust r for the log calculation
        if msb >= 128 {
            r = ratio / pow2_u256(msb - 127);
        } else {
            r = ratio * pow2_u256(127 - msb);
        }

        // Create log_2 as i257 with appropriate sign
        let msb_minus_128 = msb - 128;
        let is_negative = msb_minus_128 < 0;
        let abs_value = if is_negative {
            128 - msb
        } else {
            msb_minus_128
        };
        let abs_u256 = u256 { low: abs_value.into(), high: 0 } * pow2_u256(64);
        let mut log_2 = I257Impl::new(abs_u256, is_negative);

        // Begin log approximation through repeated squaring
        r = (r * r) / pow2_u256(127);
        let f = r / pow2_u256(128);
        let bit_value = I257Impl::new(
            u256 { low: f.try_into().unwrap(), high: 0 } * pow2_u256(63), false,
        );
        log_2 = log_2 + bit_value;
        r = r / pow2_u256(f.try_into().unwrap());

        // Continue with more squaring steps for precision
        for i in 0..13_u32 {
            r = (r * r) / pow2_u256(127);
            let f = r / pow2_u256(128);
            let bit_value = I257Impl::new(
                u256 { low: f.try_into().unwrap(), high: 0 } * pow2_u256(62 - i), false,
            );
            log_2 = log_2 + bit_value;
            r = r / pow2_u256(f.try_into().unwrap());
        }

        // Convert to log base 1.0001 (multiply by 1/log₂(1.0001))
        let log_sqrt10001_multiplier = I257Impl::new(
            u256 { low: 255738958999603826347141, high: 0 }, false,
        );
        let log_sqrt10001 = log_2 * log_sqrt10001_multiplier;

        // Calculate tick bounds
        let tick_low_offset = I257Impl::new(
            u256 { low: 3402992956809132418596140100660247210, high: 0 }, false,
        );
        let tick_high_offset = I257Impl::new(
            u256 { low: 291339464771989622907027621153398088495, high: 0 }, false,
        );

        let tick_low_i257 = log_sqrt10001 - tick_low_offset;
        let tick_high_i257 = log_sqrt10001 + tick_high_offset;

        // Convert to i32 with proper sign handling
        let tick_low_abs = tick_low_i257.abs() / pow2_u256(128);
        let tick_high_abs = tick_high_i257.abs() / pow2_u256(128);

        let tick_low = if tick_low_i257.is_negative() {
            let tick_low_u32: u32 = tick_low_abs.try_into().unwrap();
            -1 * (tick_low_u32.try_into().unwrap())
        } else {
            let tick_low_u32: u32 = tick_low_abs.try_into().unwrap();
            tick_low_u32.try_into().unwrap()
        };

        let tick_high = if tick_high_i257.is_negative() {
            let tick_high_u32: u32 = tick_high_abs.try_into().unwrap();
            -1 * tick_high_u32.try_into().unwrap()
        } else {
            let tick_high_u32: u32 = tick_high_abs.try_into().unwrap();
            tick_high_u32.try_into().unwrap()
        };

        // Determine the correct tick
        let tick = if tick_low == tick_high {
            tick_low
        } else if get_sqrt_ratio_at_tick(tick_high).value <= sqrt_ratio_x96.value {
            tick_high
        } else {
            tick_low
        };

        tick
    }
}
