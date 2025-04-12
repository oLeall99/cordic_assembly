import math

# Constantes
ITERATIONS = 14
K_GAIN = 0.607252935  # Valor do ganho CORDIC para 14 iterações
FIXED_POINT_BITS = 15
SCALE = 1 << FIXED_POINT_BITS

# Converte ângulo em radianos para formato fixo Q3.13
def to_fixed_point(val, bits=FIXED_POINT_BITS):
    return int(val * (1 << bits))

# Converte de ponto fixo para float
def from_fixed_point(val, bits=FIXED_POINT_BITS):
    return val / float(1 << bits)

# Tabela de arctan(2^-i) em ponto fixo Q15
atan_table = [to_fixed_point(math.atan(2 ** -i)) for i in range(ITERATIONS)]
print(atan_table)
def cordic(angle_rad):
    # Inicialização
    x = to_fixed_point(K_GAIN)
    y = 0
    z = to_fixed_point(angle_rad)

    for i in range(ITERATIONS):
        dx = x >> i
        dy = y >> i

        if z >= 0:
            x_new = x - dy
            y_new = y + dx
            z -= atan_table[i]
        else:
            x_new = x + dy
            y_new = y - dx
            z += atan_table[i]

        x, y = x_new, y_new

    # Converte de volta para float
    cos_val = from_fixed_point(x)
    sin_val = from_fixed_point(y)

    return cos_val, sin_val

# ===========================
# EXEMPLO DE USO
# ===========================
angle_deg = 20
angle_rad = math.radians(angle_deg)

cosine, sine = cordic(angle_rad)

print(f"Ângulo: {angle_deg}° ({angle_rad:.6f} rad)")
print(f"Seno  ≈ {sine:.6f} (real: {math.sin(angle_rad):.6f})")
print(f"Cosseno ≈ {cosine:.6f} (real: {math.cos(angle_rad):.6f})")
