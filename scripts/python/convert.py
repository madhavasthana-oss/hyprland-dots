from PIL import Image
import subprocess
import tempfile
import os

input_png = "doomguy-logo.png"
output_svg = "doomguy-logo.svg"

# Load image and convert to pure black/white
img = Image.open(input_png).convert("L")

# Threshold
img = img.point(lambda p: 255 if p > 128 else 0)

with tempfile.NamedTemporaryFile(suffix=".pbm", delete=False) as tmp:
    pbm_path = tmp.name
    img.save(pbm_path)

subprocess.run([
    "potrace",
    pbm_path,
    "-s",
    "-o",
    output_svg
])

os.unlink(pbm_path)

print(f"Saved to {output_svg}")