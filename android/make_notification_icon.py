from PIL import Image
import os

src = "app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.webp"
sizes = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96, "": 48}

img = Image.open(src).convert("RGBA")
r, g, b, a = img.split()

# Ritaglia esattamente al bounding box dei pixel visibili
bbox = a.getbbox()
img = img.crop(bbox)
r, g, b, a = img.split()

for density, px in sizes.items():
    white = Image.new("RGBA", img.size, (255, 255, 255, 0))
    white.putalpha(a)
    out = white.resize((px, px), Image.LANCZOS)
    dest = f"app/src/main/res/drawable-{density}" if density else "app/src/main/res/drawable"
    os.makedirs(dest, exist_ok=True)
    out.save(f"{dest}/ic_notification.png")
    print(f"✓ {dest}/ic_notification.png ({px}x{px})")

print("Done!")
