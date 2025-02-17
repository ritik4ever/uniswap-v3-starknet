import math

# Compute sqrt(0.215) as a Q64.96 fixed-point number with full precision wihout using floats
price_scaled = int(0.215 * 10**18)  # STRK 18 decimals 
sqrt_scaled = int(math.isqrt(price_scaled * 10**18))  # sqrt(0.215 * 1e36) = 1e18 * sqrt(0.215)
q96_ratio = (1 << 96) // (10**9)  # scale sqrt to Q64.96 (adjust for 18 decimals)
cur_sqrtp = sqrt_scaled * q96_ratio // (10**9)  # Final Q64.96 value

print(cur_sqrtp)