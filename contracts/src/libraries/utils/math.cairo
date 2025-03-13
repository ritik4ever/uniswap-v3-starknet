use alexandria_math::fast_power::fast_power;

pub fn scale_amount(amount: i128, decimals: u8) -> u256 {
    let is_negative = amount < 0;
    let abs_amount: u128 = if is_negative {
        (-amount).try_into().unwrap()
    } else {
        amount.try_into().unwrap()
    };

    let scaled_amount = u256 { low: abs_amount, high: 0 } * fast_power(10_u256, decimals.into());

    scaled_amount
}


pub fn most_significant_bit(x: u256) -> i32 {
    match check_gt_zero(x) {
        Result::Ok(()) => {},
        Result::Err(err) => { panic!("{err}"); },
    }

    let mut x = x;
    let mut r: i32 = 0;

    if x >= 0x100000000000000000000000000000000_u256 {
        x = x / 0x100000000000000000000000000000000_u256;
        r += 128;
    }
    if x >= 0x10000000000000000_u256 {
        x = x / 0x10000000000000000_u256;
        r += 64;
    }
    if x >= 0x100000000_u256 {
        x = x / 0x100000000_u256;
        r += 32;
    }
    if x >= 0x10000_u256 {
        x = x / 0x10000_u256;
        r += 16;
    }
    if x >= 0x100_u256 {
        x = x / 0x100_u256;
        r += 8;
    }
    if x >= 0x10_u256 {
        x = x / 0x10_u256;
        r += 4;
    }
    if x >= 0x4_u256 {
        x = x / 0x4_u256;
        r += 2;
    }
    if x >= 0x2_u256 {
        r += 1;
    }

    r
}

pub fn least_significant_bit(x: u256) -> i32 {
    match check_gt_zero(x) {
        Result::Ok(()) => {},
        Result::Err(err) => { panic!("{err}"); },
    }

    let mut x = x;
    let mut r: i32 = 255;

    if (x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF_u256) > 0 {
        r -= 128;
    } else {
        x = x / 0x100000000000000000000000000000000_u256;
    }
    if (x & 0xFFFFFFFFFFFFFFFF_u256) > 0 {
        r -= 64;
    } else {
        x = x / 0x10000000000000000_u256;
    }
    if (x & 0xFFFFFFFF_u256) > 0 {
        r -= 32;
    } else {
        x = x / 0x100000000_u256;
    }
    if (x & 0xFFFF_u256) > 0 {
        r -= 16;
    } else {
        x = x / 0x10000_u256;
    }
    if (x & 0xFF_u256) > 0 {
        r -= 8;
    } else {
        x = x / 0x100_u256;
    }
    if (x & 0xF_u256) > 0 {
        r -= 4;
    } else {
        x = x / 0x10_u256;
    }
    if (x & 0x3_u256) > 0 {
        r -= 2;
    } else {
        x = x / 0x4_u256;
    }
    if (x & 0x1_u256) > 0 {
        r -= 1;
    }

    r
}

fn check_gt_zero(x: u256) -> Result<(), felt252> {
    if x > 0 {
        Result::Ok(())
    } else {
        Result::Err('x must be greater than 0')
    }
}

pub fn u256_max() -> u256 {
    u256 {
        low: 0xffffffffffffffffffffffffffffffff_u128, high: 0xffffffffffffffffffffffffffffffff_u128,
    }
}
