import math
import pytest

q96 = 2**96


def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))

def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)

def liquidity0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / q96) / (pb - pa)

def liquidity1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * q96 / (pb - pa)

def calc_amount0(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * q96 * (pb - pa) / pa / pb)

def calc_amount1(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * (pb - pa) / q96)



def test_swap_calculation():
    eth = 10**18
    current_sqrtp = 5602277097478614198912276234240
    liquidity = 1517882343751509868544
    amount_in = 42 * eth  # 42 USDC

    price_diff = (amount_in * q96) // liquidity
    price_next = current_sqrtp + price_diff

    new_price = (price_next / q96) ** 2
    new_tick = price_to_tick(new_price)

    print(f"[DEBUG] Swap Calculation:")
    print(f"    current_sqrtp  = {current_sqrtp}")
    print(f"    liquidity      = {liquidity}")
    print(f"    amount_in      = {amount_in}")
    print(f"    price_diff     = {price_diff}")
    print(f"    price_next     = {price_next}")
    print(f"    new_price      = {new_price}")
    print(f"    new_tick       = {new_tick}")

    expected_price_next = 5604469350942327889444743441197
    expected_new_price = 5003.913912782393
    expected_new_tick = 85184

    assert price_next == expected_price_next, f"Expected price_next {expected_price_next}, got {price_next}"
    assert math.isclose(new_price, expected_new_price, rel_tol=1e-9), f"Expected new_price {expected_new_price}, got {new_price}"
    assert new_tick == expected_new_tick, f"Expected new_tick {expected_new_tick}, got {new_tick}"

    amount_in_calculated = calc_amount1(liquidity, price_next, current_sqrtp)
    amount_out_calculated = calc_amount0(liquidity, price_next, current_sqrtp)

    print(f"    USDC in  = {amount_in_calculated / eth}")
    print(f"    ETH out  = {amount_out_calculated / eth}")

    assert math.isclose(amount_in_calculated / eth, 42.0, rel_tol=1e-9), f"Expected USDC in 42.0, got {amount_in_calculated / eth}"
    assert math.isclose(amount_out_calculated / eth, 0.008396714242162444, rel_tol=1e-9), f"Expected ETH out 0.008396714242162444, got {amount_out_calculated / eth}"

def test_swap_calculation_strk():
    strk = 10**18
    current_sqrtp = price_to_sqrtp(0.215)  
    liquidity = 5670207847624059387904 

    # Swap: selling 42 USDC for STRK
    amount_in = 42 * strk

    # for a USDC swap, the price (sqrtP) increases.
    price_diff = (amount_in * q96) // liquidity
    price_next = current_sqrtp + price_diff

    new_price = (price_next / q96) ** 2
    new_tick = price_to_tick(new_price)

    print(f"[DEBUG] STRK Swap Calculation:")
    print(f"    current_sqrtp  = {current_sqrtp}")
    print(f"    liquidity      = {liquidity}")
    print(f"    amount_in      = {amount_in}")
    print(f"    price_diff     = {price_diff}")
    print(f"    price_next     = {price_next}")
    print(f"    new_price      = {new_price}")
    print(f"    new_tick       = {new_tick}")

    amount_in_calculated = calc_amount1(liquidity, price_next, current_sqrtp)
    amount_out_calculated = calc_amount0(liquidity, price_next, current_sqrtp)


    print(f"    USDC in   = {amount_in_calculated / strk}")
    print(f"    STRK out  = {amount_out_calculated / strk}")

    assert math.isclose(amount_in_calculated / strk, 42.0, rel_tol=1e-9), \
        f"Expected USDC in 42.0, got {amount_in_calculated / strk}"
    
    assert new_tick > price_to_tick(0.215), \
        f"Expected new tick higher than {price_to_tick(0.215)}, got {new_tick}"


def test_price_to_tick():
    p = 0.215
    expected_tick = math.floor(math.log(p, 1.0001))
    computed_tick = price_to_tick(p)
    print(f"[DEBUG] price_to_tick: p = {p}, expected_tick = {expected_tick}, computed_tick = {computed_tick}")
    assert computed_tick == expected_tick, f"Expected tick {expected_tick}, got {computed_tick}"

def test_price_to_sqrtp():
    p = 5000
    expected = int(math.sqrt(p) * q96)
    computed = price_to_sqrtp(p)
    print(f"[DEBUG] price_to_sqrtp: p = {p}, expected_sqrtp = {expected}, computed_sqrtp = {computed}")
    assert computed == expected, f"Expected sqrtP {expected}, got {computed}"

def test_liquidity_calculation():
    strk = 10**18
    amnt_strk = 1000 * strk # scaled up by to make sure liquidity not too low 
    amt_usdc = 215 * strk

    sqrtp_low = price_to_sqrtp(0.195)
    cur_sqrtp = price_to_sqrtp(0.215)
    sqrtp_hi = price_to_sqrtp(0.255)

    liq0 = liquidity0(amnt_strk, cur_sqrtp, sqrtp_hi)
    liq1 = liquidity1(amt_usdc, cur_sqrtp, sqrtp_low)
    liq = int(min(liq0, liq1))
    
    print(f"[DEBUG] Liquidity Calculation:")
    print(f"    amnt_strk = {amnt_strk}")
    print(f"    amt_usdc  = {amt_usdc}")
    print(f"    sqrtp_low = {sqrtp_low}")
    print(f"    cur_sqrtp = {cur_sqrtp}")
    print(f"    sqrtp_hi  = {sqrtp_hi}")
    print(f"    liq0      = {liq0}")
    print(f"    liq1      = {liq1}")
    print(f"    Chosen liq = {liq}")
    


def test_calc_amounts():
    strk = 10**18
    amnt_strk = 1 * strk
    amt_usdc = 0.215 * strk

    cur_sqrtp = price_to_sqrtp(0.215)
    sqrtp_low = price_to_sqrtp(0.195)
    sqrtp_hi = price_to_sqrtp(0.255)

    liq0 = liquidity0(amnt_strk, cur_sqrtp, sqrtp_hi)
    liq1 = liquidity1(amt_usdc, cur_sqrtp, sqrtp_low)
    liq = int(min(liq0, liq1))

    amount0 = calc_amount0(liq, sqrtp_hi, cur_sqrtp)
    amount1 = calc_amount1(liq, sqrtp_low, cur_sqrtp)

    print(f"[DEBUG] Token Amounts Calculation:")
    print(f"    cur_sqrtp = {cur_sqrtp}")
    print(f"    sqrtp_low = {sqrtp_low}")
    print(f"    sqrtp_hi  = {sqrtp_hi}")
    print(f"    liq       = {liq}")
    print(f"    Calculated amount0 = {amount0}")
    print(f"    Calculated amount1 = {amount1}")
    
    expected_amount0 = 1000000000000000000
    expected_amount1 = 125271229822007120

    assert amount0 == expected_amount0, f"Expected amount0 {expected_amount0}, got {amount0}"
    assert amount1 == expected_amount1, f"Expected amount1 {expected_amount1}, got {amount1}"


if __name__ == '__main__':
    test_price_to_tick()
    test_price_to_sqrtp()
    test_liquidity_calculation()
    test_calc_amounts()
    test_swap_calculation()
    test_swap_calculation_strk()
