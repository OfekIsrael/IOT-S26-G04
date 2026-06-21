import numpy as np
import matplotlib.pyplot as plt
import math

# ==========================================
# CONFIGURATION
# ==========================================
CANVAS_SIZE = 58
NUM_LEDS_PER_STRIP = 58
NUM_ANGLES = 360
ANGLE_STEP = 1

# Change this value (0-4) to run different diagnostic tests
# 0 = Original 'X' and Hub
# 1 = Asymmetric Test (Detects Mirroring)
# 2 = Bounding Box Test (Detects Center/Scaling Skew)
# 3 = Isolated Dot Test (Detects Timing Smear)
# 4 = Radial Gradient Test (Detects Hardware Wiring Reversal)
TEST_MODE = 6

# ==========================================
# 1. INITIALIZE CANVAS & LOAD TEST PATTERN
# ==========================================
canvas = np.zeros((CANVAS_SIZE, CANVAS_SIZE, 3), dtype=np.uint8)

if TEST_MODE == 0:
    # Original 'X' and Center Hub
    for i in range(CANVAS_SIZE):
        canvas[i, i] = [255, 255, 255]
        canvas[i, CANVAS_SIZE - 1 - i] = [255, 255, 255]
    canvas[28:31, 28:31] = [0, 0, 255]

elif TEST_MODE == 1:
    # Asymmetric Test
    for i in range(CANVAS_SIZE):
        canvas[i, i] = [255, 0, 0]  # Full Red Diagonal
    for i in range(29):
        canvas[28 - i, 29 + i] = [0, 0, 255]  # Top-Right Blue Half-Diagonal

elif TEST_MODE == 2:
    # Bounding Box Test
    canvas[0, :] = [0, 255, 0]
    canvas[CANVAS_SIZE - 1, :] = [0, 255, 0]
    canvas[:, 0] = [0, 255, 0]
    canvas[:, CANVAS_SIZE - 1] = [0, 255, 0]

elif TEST_MODE == 3:
    # Isolated Dot Test
    canvas[28:30, 50:52] = [255, 255, 255]  # 2x2 white dot on the right

elif TEST_MODE == 4:
    # Radial Gradient Test
    for i in range(29, CANVAS_SIZE):
        intensity = int(((i - 29) / 28.0) * 255)
        canvas[28:30, i] = [intensity, 0, 0]

elif TEST_MODE == 5:
    # Checkerboard Test (Detects Aliasing and Resolution Limits)
    block_size = 4  # 4x4 pixel blocks
    for i in range(CANVAS_SIZE):
        for j in range(CANVAS_SIZE):
            # Alternate colors based on grid position
            if ((i // block_size) + (j // block_size)) % 2 == 0:
                canvas[i, j] = [255, 255, 255]  # White square
            else:
                canvas[i, j] = [0, 0, 0]        # Black square

elif TEST_MODE == 6:
    # Small Offset Square Test (Detects Cartesian-to-Polar Shape Warping)
    # Draws a 10x10 cyan square in the top-left quadrant
    canvas[0:38, 18:38] = [0, 255, 255]

# ==========================================
# 2. C++ _build_lut() LOGIC
# ==========================================
lut_i = np.zeros((NUM_ANGLES, NUM_LEDS_PER_STRIP), dtype=int)
lut_j = np.zeros((NUM_ANGLES, NUM_LEDS_PER_STRIP), dtype=int)

center = (CANVAS_SIZE - 1) / 2.0

for a in range(NUM_ANGLES):
    angle_deg = a * ANGLE_STEP
    angle_rad = math.radians(angle_deg)
    dx = math.cos(angle_rad)
    dy = math.sin(angle_rad)

    for r in range(NUM_LEDS_PER_STRIP):
        radius = r - center
        ci = int(round(center + dx * radius))
        cj = int(round(center + dy * radius))

        # Clamp logic exactly as it is in renderer.h
        ci = max(0, min(CANVAS_SIZE - 1, ci))
        cj = max(0, min(CANVAS_SIZE - 1, cj))

        lut_i[a, r] = ci
        lut_j[a, r] = cj

# ==========================================
# 3. C++ renderer::render() SIMULATION
# ==========================================
plot_x = []
plot_y = []
plot_colors = []

for a in range(NUM_ANGLES):
    angle_rad = math.radians(a * ANGLE_STEP)

    for r in range(NUM_LEDS_PER_STRIP):
        radius = r - center

        # Physical location of this LED at this angle slice
        # ci is driven by cos (→ row = Y), cj by sin (→ col = X).
        # Negate phys_y because image rows increase downward.
        phys_x = radius * math.sin(angle_rad)
        phys_y = -radius * math.cos(angle_rad)

        # Look up the color using the LUT mapping
        ci = lut_i[a, r]
        cj = lut_j[a, r]

        # Normalize 0-255 RGB to 0.0-1.0 for matplotlib
        color = canvas[ci, cj] / 255.0

        if sum(color) > 0:  # Only plot lit pixels to speed up visualization
            plot_x.append(phys_x)
            plot_y.append(phys_y)
            plot_colors.append(color)

# ==========================================
# 4. VISUALIZATION
# ==========================================
fig, axes = plt.subplots(1, 2, figsize=(14, 7))
fig.suptitle(f'POV Display Simulator - Test Mode: {TEST_MODE}', fontsize=16)

# Left Subplot: Memory Canvas
axes[0].imshow(canvas)
axes[0].set_title(f"Cartesian Memory ({CANVAS_SIZE}x{CANVAS_SIZE})")
axes[0].set_xlabel("X (Columns)")
axes[0].set_ylabel("Y (Rows)")

# Right Subplot: Polar Output
axes[1].scatter(plot_x, plot_y, c=plot_colors, s=15, marker='s')
axes[1].set_aspect('equal')
axes[1].set_xlim(-center - 2, center + 2)
axes[1].set_ylim(-center - 2, center + 2)
axes[1].set_title(f"Polar Hardware Simulation")
axes[1].set_facecolor('black')
axes[1].grid(color='gray', linestyle='-', linewidth=0.2, alpha=0.5)

plt.tight_layout()
plt.show()