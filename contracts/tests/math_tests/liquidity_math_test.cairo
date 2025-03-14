use contracts::libraries::math::liquidity_math::LiquidityMath;
use contracts::libraries::math::numbers::fixed_point::{FixedQ64x96, IFixedQ64x96Impl, ONE};

 // --- Exact Test Values --- //
// Test values for basic case:
// sqrtp_a = 79228162514264337593543950336
// sqrtp_b = 112045541949572287496682733568
// liquidity = 1000000
// expected_amount0 = 292893
// expected_amount1 = 414213

// Test values for ETH/USDC range:
// sqrtp_low = 3068493539683605223466464182272
// sqrtp_high = 3961408125713216879677197516800
// liquidity = 2000000000000000000
// expected_amount0 = 11639777949432226
// expected_amount1 = 22540333075851661312
// --- END --- //

 // --- Cairo Test Code for calc_amount0_delta --- // 
 #[test]
 fn test_calc_amount0_delta_basic_case() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(79228162514264337593543950336_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(112045541949572287496682733568_u256);
     let liquidity = 1000000_u128;
 
     let result = LiquidityMath::calc_amount0_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 292893_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount0_delta incorrect');
 }
 
 #[test]
 fn test_calc_amount0_delta_inverted_case() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(112045541949572287496682733568_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(79228162514264337593543950336_u256);
     let liquidity = 1000000_u128;
 
     let result = LiquidityMath::calc_amount0_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 292893_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount0_delta incorrect');
 }
 
 #[test]
 fn test_calc_amount0_delta_eth_usdc_range() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(3068493539683605223466464182272_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(3961408125713216879677197516800_u256);
     let liquidity = 2000000000000000000_u128;
 
     let result = LiquidityMath::calc_amount0_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 11639777949432226_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount0_delta incorrect');
 }
 
 
  // --- Cairo Test Code for calc_amount1_delta --- // 
 #[test]
 fn test_calc_amount1_delta_basic_case() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(79228162514264337593543950336_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(112045541949572287496682733568_u256);
     let liquidity = 1000000_u128;
 
     let result = LiquidityMath::calc_amount1_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 414213_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount1_delta incorrect');
 }
 
 #[test]
 fn test_calc_amount1_delta_inverted_case() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(112045541949572287496682733568_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(79228162514264337593543950336_u256);
     let liquidity = 1000000_u128;
 
     let result = LiquidityMath::calc_amount1_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 414213_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount1_delta incorrect');
 }
 
 #[test]
 fn test_calc_amount1_delta_eth_usdc_range() {
     // Create sqrt prices
     let sqrt_price_a = IFixedQ64x96Impl::new(3068493539683605223466464182272_u256);
     let sqrt_price_b = IFixedQ64x96Impl::new(3961408125713216879677197516800_u256);
     let liquidity = 2000000000000000000_u128;
 
     let result = LiquidityMath::calc_amount1_delta(sqrt_price_a, sqrt_price_b, liquidity);
 
     let expected = 22540333075851661312_u256;
     let tolerance = expected / 100_u256; // 1% tolerance
     assert(result >= expected - tolerance && result <= expected + tolerance, 'calc_amount1_delta incorrect');
 }
 
 
  // --- Cairo Test Code for swap calculation --- // 
 #[test]
 fn test_swap_calculation() {
     // Test swapping 42 USDC for ETH
     let current_sqrtp = FixedQ64x96 { value: 5602277097478614198912276234240_u256 };
     let liquidity = 1517882343751509868544_u128;
     let amount_in = 42000000000000000000_u128;  // 42 USDC
 
     // Calculate price impact
     let price_diff = (amount_in.into() * ONE) / liquidity.into();
     let price_next = FixedQ64x96 { value: current_sqrtp.value + price_diff };
 
     // Verify expected values
     let expected_price_next = 5604469350942327889444743441197_u256;
     assert(price_next.value >= expected_price_next - 100 && price_next.value <= expected_price_next + 100, 'Price calculation incorrect');
 
     // Calculate amounts
     let amount_in_calculated = LiquidityMath::calc_amount1_delta(current_sqrtp.clone(), price_next.clone(), liquidity);
     let amount_out_calculated = LiquidityMath::calc_amount0_delta(current_sqrtp, price_next, liquidity);
 
     // Verify calculated amounts
     let expected_amount_in = 42000000000000000000_u256;  // 42 USDC
     let expected_amount_out = 8396714242162445_u256;  // ~0.0084 ETH
 
     let tolerance_in = expected_amount_in / 100_u256;  // 1% tolerance
     let tolerance_out = expected_amount_out / 100_u256;  // 1% tolerance
     assert(amount_in_calculated >= expected_amount_in - tolerance_in && amount_in_calculated <= expected_amount_in + tolerance_in, 'Amount in incorrect');
     assert(amount_out_calculated >= expected_amount_out - tolerance_out && amount_out_calculated <= expected_amount_out + tolerance_out, 'Amount out incorrect');
 }