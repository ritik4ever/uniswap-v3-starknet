import math

## This is pretty much all of the math needed for uniswap v3.
## Looks simple in python...

q96 = 2**96

def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))

def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)

def calc_amount0(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * q96 * (pb - pa) / pa / pb)

def calc_amount1(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * (pb - pa) / q96)
