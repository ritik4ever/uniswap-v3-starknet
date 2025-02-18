import math

q96 = 2**96

def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))

def price_to_sqrtp(p):
    # Compute sqrt(p) as a Q64.96 fixed-point number with full precision wihout using floats
    price_scaled = int(p * 10**18)  # STRK 18 decimals 
    sqrt_scaled = int(math.isqrt(price_scaled * 10**18))  # sqrt(0.215 * 1e36) = 1e18 * sqrt(0.215)
    q96_ratio = (1 << 96) // (10**9)  # scale sqrt to Q64.96 (adjust for 18 decimals)
    cur_sqrtp = sqrt_scaled * q96_ratio // (10**9)  # Final Q64.96 value
    return cur_sqrtp

def liquidity0(amount, pa, pb):
    if pa > pb:
        pa,pb = pb,pa
    return (amount * (pa * pb) / q96 ) / (pb - pa)

def liquidity1(amount, pa, pb):
    if pa > pb:
        pa,pb = pb,pa
    return amount * q96 / (pb - pa)

def calc_amount0(liq,pa,pb):
    if pa>pb:
        pa, pb = pb, pa
    return int(liq*q96 * (pb - pa) / pa / pb)

def calc_amount1(liq,pa,pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * (pb - pa) / q96)

strk = 10**18 # 18 decimals
amnt_strk = 1 * strk
amt_usdc = 0.215 * strk

tick = price_to_tick(0.215)

sqrtp_low = price_to_sqrtp(0.195)
cur_sqrtp = price_to_sqrtp(0.215)
sqrtp_hi = price_to_sqrtp(0.255)

liq0 = liquidity0(amnt_strk, cur_sqrtp, sqrtp_hi)
liq1 = liquidity1(amt_usdc, cur_sqrtp, sqrtp_low)
liq = int(min(liq0,liq1))

amount0 = calc_amount0(liq, sqrtp_hi, cur_sqrtp)
amount1 = calc_amount1(liq, sqrtp_low, cur_sqrtp)

print("amt0 ", amount0)
print("amt1", amount1)
print("liquidity ", liq)
print("current price scaled ",cur_sqrtp)
print("tick ", tick)