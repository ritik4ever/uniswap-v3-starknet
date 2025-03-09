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
