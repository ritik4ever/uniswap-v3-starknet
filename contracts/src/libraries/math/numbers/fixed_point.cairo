/// Q64.96 representation for sqrt prices.
#[derive(Debug, Drop, Serde, Clone, starknet::Store)]
pub struct FixedQ64x96 {
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

/// Fixed point constants
const ONE: u256 = 79228162514264337593543950336; // 2^96
const HALF: u256 = 39614081257132168796771975168; // 2^95

#[generate_trait]
impl IFixedQ64x96Impl of IFixedQ64x96Trait {
    fn new(value: u256) -> FixedQ64x96 {
        assert(value <= MAX_SQRT_RATIO, 'sqrt ratio overflow');
        assert(value >= MIN_SQRT_RATIO, 'sqrt ratio underflow');
        FixedQ64x96 { value }
    }

    /// from unscaled value
    fn new_unscaled(value: u256) -> FixedQ64x96 {
        FixedQ64x96 { value: value * ONE }
    }

    fn add(self: FixedQ64x96, other: FixedQ64x96) -> FixedQ64x96 {
        FixedQ64x96 { value: self.value + other.value }
    }

    /// Ceiling operation - round up to the nearest integer
    fn ceil(self: FixedQ64x96) -> FixedQ64x96 {
        let integer_part = self.value / ONE;
        let fractional_part = self.value % ONE;

        if fractional_part == 0 {
            return self;
        }

        FixedQ64x96 { value: (integer_part + 1) * ONE }
    }

    /// Divistion for 64x06 Fixed Point
    fn div(self: FixedQ64x96, other: FixedQ64x96) -> FixedQ64x96 {
        let result = (self.value * ONE) / other.value;
        FixedQ64x96 { value: result }
    }

    fn eq(self: FixedQ64x96, other: FixedQ64x96) -> bool {
        self.value == other.value
    }

    /// Floor operation - round down to the nearest integer
    fn floor(self: FixedQ64x96) -> FixedQ64x96 {
        let integer_part = self.value / ONE;
        FixedQ64x96 { value: integer_part * ONE }
    }
    /// >=
    fn ge(self: FixedQ64x96, other: FixedQ64x96) -> bool {
        self.value >= other.value
    }

    /// >
    fn gt(self: FixedQ64x96, other: FixedQ64x96) -> bool {
        self.value > other.value
    }

    fn sub(self: FixedQ64x96, other: FixedQ64x96) -> FixedQ64x96 {
        assert(self.value >= other.value, 'sqrt price underlow');
        FixedQ64x96 { value: self.value - other.value }
    }

    /// multiplication with precision retention
    fn mul(self: FixedQ64x96, other: FixedQ64x96) -> FixedQ64x96 {
        let product = (self.value * other.value) / ONE;
        FixedQ64x96 { value: product }
    }

    /// sqrt operation based on Newton-Raphson method for sqrt
    fn sqrt(self: FixedQ64x96) -> FixedQ64x96 {
        if self.value == 0 {
            return FixedQ64x96 { value: 0 };
        }

        let mut z = (self.value + ONE) / 2;
        let mut y = self.value;

        while z < y {
            y = z;
            z = (self.value / z + z) / 2;
        }

        FixedQ64x96 { value: y }
    }
}
