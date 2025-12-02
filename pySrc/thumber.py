from PIL import Image
import sys
import os

size = (128, 128)
infile = sys.argv[1]

outfile = os.path.splitext(infile)[0] + "_thumb.jpg"

with Image.open(infile) as im:
    im.thumbnail(size)
    im.save(outfile, "JPEG")

print(f"Saved {outfile}")
