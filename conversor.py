import math

def q13_to_float(q13_value: int) -> float:
    """Converts a Q3.13 integer to float"""
    if q13_value & 0x8000:  # Check if sign bit is set
        q13_value = q13_value - 0x10000  # Convert to negative two's complement
    return q13_value / 8192.0

def float_to_q13(float_value: float) -> int:
    """Converts a float to Q3.13 integer representation"""
    if float_value >= 4.0 or float_value < -4.0:
        raise ValueError("Value out of range for Q3.13 format (-4.0 to <4.0)")
    q13 = int(round(float_value * 8192))
    return q13 & 0xFFFF  # Keep it 16-bit unsigned

# 🔢 Valor de entrada (em radianos)
input_radians = 0.2984
input_q13 = float_to_q13(input_radians)
# 📐 Cálculo do seno e cosseno
sin_val = math.sin(input_radians)
cos_val = math.cos(input_radians)

# 🔄 Conversão para Q3.13
sin_q13 = float_to_q13(sin_val)
cos_q13 = float_to_q13(cos_val)

# 🖨️ Impressão dos resultados
print(f"Input (radians): {input_radians}")
print(f"Input (Q3.13): {input_q13:#06x} ({input_q13})")
print(f"\nSine:")
print(f"  Float: {sin_val}")
print(f"  Q3.13: {sin_q13:#06x} ({sin_q13})")

print(f"\nCosine:")
print(f"  Float: {cos_val}")
print(f"  Q3.13: {cos_q13:#06x} ({cos_q13})")

# 🔁 Conversão reversa para checagem
print(f"\nBack to float from Q3.13:")
print(f"  sin: {q13_to_float(sin_q13)}")
print(f"  cos: {q13_to_float(cos_q13)}")

print(f"\n\nCos: {q13_to_float(0x1e97)}")
print(f"Sin: {q13_to_float(0x0968)}")