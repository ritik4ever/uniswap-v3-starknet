pub mod TickMath {
    use alexandria_math::const_pow::pow2_u256;
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
}
