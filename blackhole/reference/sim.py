import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Constants
black_hole_mass = 10  # Arbitrary mass of the black hole
gravitational_constant = 1  # Simplified for visualization
light_speed = 1  # Simplified for visualization
black_hole_position = (0, 0, 0)  # Center of the 3D grid


# Function to calculate the deflection due to gravitational lensing
def gravitational_lensing_3d(x, y, z, bh_x, bh_y, bh_z, mass):
    dx = x - bh_x
    dy = y - bh_y
    dz = z - bh_z
    r = np.sqrt(dx**2 + dy**2 + dz**2) + 1e-6  # Avoid division by zero
    deflection = gravitational_constant * mass / (r * light_speed**2)
    return (
        x - deflection * dx / r,
        y - deflection * dy / r,
        z - deflection * dz / r,
    )


# Generate a 3D grid of light rays
grid_size = 30
x = np.linspace(-5, 5, grid_size)
y = np.linspace(-5, 5, grid_size)
z = np.linspace(-5, 5, grid_size)
xx, yy, zz = np.meshgrid(x, y, z)

# Apply lensing effect
deflected_x, deflected_y, deflected_z = gravitational_lensing_3d(
    xx, yy, zz, *black_hole_position, black_hole_mass
)

# Plot the results
fig = plt.figure(figsize=(12, 8))
ax = fig.add_subplot(111, projection="3d")

# Choose a fixed Z plane for wireframe visualization
z_slices = np.linspace(-5, 5, 5)  # Slices at 5 different Z-values

for z_slice in z_slices:
    idx = np.abs(z - z_slice).argmin()  # Closest Z-slice index
    ax.plot_wireframe(
        deflected_x[:, :, idx],
        deflected_y[:, :, idx],
        z_slice * np.ones_like(deflected_x[:, :, idx]),
        color="blue",
        alpha=0.7,
        linewidth=0.5,
    )

# Plot the black hole
ax.scatter(*black_hole_position, color="black", s=100, label="Black Hole")

# Set plot limits and labels
ax.set_xlim([-5, 5])
ax.set_ylim([-5, 5])
ax.set_zlim([-5, 5])
ax.set_title("Gravitational Lensing by a Black Hole (3D Slices)")
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")
ax.legend()

plt.show()
