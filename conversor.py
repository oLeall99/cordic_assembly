import math

def float_to_q3_13(value: float) -> int:
    """
    Converte float para ponto fixo Q3.13 (16 bits com sinal).
    """
    if value >= 4.0:
        value = 3.9998779296875
    elif value < -4.0:
        value = -4.0

    fixed_val = int(round(value * (1 << 13)))

    if fixed_val < -32768 or fixed_val > 32767:
        raise OverflowError("Valor fora do intervalo de 16 bits com sinal")

    return fixed_val


def q3_13_to_float(hex_value: int) -> float:
    """
    Converte Q3.13 (16 bits com sinal) para float.
    """
    value = hex_value & 0xFFFF
    if value & 0x8000:
        value -= 0x10000
    return value / (1 << 13)


# Valor de entrada
f = 0

# Calcula seno e cosseno
sin_f = math.sin(f)
cos_f = math.cos(f)

# Converte f, sen(f) e cos(f) para Q3.13
f_q = float_to_q3_13(f)
sin_q = float_to_q3_13(sin_f)
cos_q = float_to_q3_13(cos_f)

# Converte de volta para float
f_from_q = q3_13_to_float(f_q)
sin_from_q = q3_13_to_float(sin_q)
cos_from_q = q3_13_to_float(cos_q)

# Mostra resultados
print(f"f = {f} -> Q3.13: 0x{f_q & 0xFFFF:04X} -> float: {f_from_q}")
print(f"sin(f) = {sin_f} -> Q3.13: 0x{sin_q & 0xFFFF:04X} -> float: {sin_from_q}")
print(f"cos(f) = {cos_f} -> Q3.13: 0x{cos_q & 0xFFFF:04X} -> float: {cos_from_q}")
