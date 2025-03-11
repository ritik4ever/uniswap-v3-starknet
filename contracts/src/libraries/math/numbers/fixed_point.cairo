/// Q64.96 representation for sqrt prices.
#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct SqrtPriceQ64x96 {
    value: u256,
}

/// The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to
/// getSqrtRatioAtTick(MIN_TICK) [uniswap
/// v3-core](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
const MIN_SQRT_RATIO: u256 = 4295128739;
/// The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to
/// getSqrtRatioAtTick(MAX_TICK) [uniswap
/// v3-core](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
const MAX_SQRT_RATIO: u256 = 1461446703485210103287273052203988822378723970342;

#[generate_trait]
impl ISqrtPriceQ64x96Impl of ISqrtPriceQ64x96Trait {
    fn new(value: u256) -> SqrtPriceQ64x96 {
        assert(value <= MAX_SQRT_RATIO, 'sqrt ratio overflow');
        assert(value >= MIN_SQRT_RATIO, 'sqrt ratio underflow');
        SqrtPriceQ64x96 { value }
    }
}
