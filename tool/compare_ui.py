"""Compare Flutter QA captures with the approved reference sheet."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
output = root / "build/qa09"
reference = Image.open(root / "docs/reference/novadoku-ui.jpg")
panels = [
    ("home", 31, 127), ("gameplay", 344, 127),
    ("settings", 656, 127), ("hint", 969, 127), ("mistake", 1281, 127),
    ("retry", 31, 842), ("complete", 344, 842),
    ("leave", 656, 842), ("daily", 969, 842), ("tutorial", 1281, 842),
]
for batch in range(2):
    sheet = Image.new("RGB", (1700, 410), "#eeebf8")
    draw = ImageDraw.Draw(sheet)
    for column, (name, x, y) in enumerate(panels[batch * 5:(batch + 1) * 5]):
        for side in range(2):
            image = reference.crop((x, y, x + 293, y + 634)) if side == 0 else Image.open(output / f"phone-{name}.png")
            image.thumbnail((164, 356))
            left = column * 340 + side * 168
            draw.text((left, 6), name, fill="#242038")
            draw.text((left, 22), "Reference" if side == 0 else "Flutter", fill="#242038")
            sheet.paste(image, (left, 44))
    sheet.save(output / f"comparison-{batch + 1}.png")
