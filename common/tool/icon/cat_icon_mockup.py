"""고양이 아이콘 시안 (제안용). 사용법: python cat_icon_mockup.py <고양이 원본 PNG/WEBP> <출력 폴더> [앱 ID ...]

원본 이미지는 유료 Icons8 에셋이라 이 저장소에 두지 않는다. 앱 ID 해시로 배경 hue를 정한다.
"""
import colorsys, hashlib, os, sys
from PIL import Image, ImageDraw, ImageFilter

SRC = sys.argv[1]
OUT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)
SIZE = 1024
# 고양이(주황/노랑)와 겹치는 hue 구간은 피한다.
BANNED = (0.03, 0.20)  # 약 10°~72°

def hue_for(app_id):
    h = int(hashlib.sha256(app_id.encode()).hexdigest(), 16) % 10000 / 10000
    span = 1 - (BANNED[1] - BANNED[0])
    v = h * span
    return v if v < BANNED[0] else v + (BANNED[1] - BANNED[0])

def rgb(h, s, v):
    return tuple(int(c * 255) for c in colorsys.hsv_to_rgb(h, s, v))

def icon(app_id, cat):
    h = hue_for(app_id)
    top, bot = rgb(h, 0.55, 0.95), rgb(h, 0.85, 0.55)
    bg = Image.new("RGBA", (SIZE, SIZE))
    px = bg.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(SIZE):
            px[x, y] = c + (255,)
    # 후광
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse((110, 130, 914, 934), fill=rgb(h, 0.25, 1.0) + (110,))
    bg = Image.alpha_composite(bg, halo.filter(ImageFilter.GaussianBlur(40)))
    # 고양이 (그림자 포함)
    c = cat.resize((int(SIZE * 0.80),) * 2, Image.LANCZOS)
    pos = ((SIZE - c.width) // 2, (SIZE - c.height) // 2 + 20)
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    a = c.split()[3].point(lambda v: v * 0.35)
    sh.paste(Image.new("RGBA", c.size, (0, 0, 0, 255)), (pos[0], pos[1] + 22), a)
    bg = Image.alpha_composite(bg, sh.filter(ImageFilter.GaussianBlur(18)))
    bg.alpha_composite(c, pos)
    # 둥근 사각형 마스크
    m = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=int(SIZE * 0.225), fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(bg, (0, 0), m)
    return out, h

cat = Image.open(SRC).convert("RGBA")
apps = sys.argv[3:] or ["daylight-terminal", "portside"]
W, H = 90 + 700 * len(apps), 760
sheet = Image.new("RGBA", (W, H), (245, 245, 247, 255))
d = ImageDraw.Draw(sheet)
for i, app in enumerate(apps):
    ic, h = icon(app, cat)
    ic.save(os.path.join(OUT, f"{app}.png"))
    big = ic.resize((520, 520), Image.LANCZOS)
    x0 = 90 + i * 700
    sheet.alpha_composite(big, (x0, 60))
    for j, s in enumerate((128, 64, 32, 16)):
        sm = ic.resize((s, s), Image.LANCZOS)
        sheet.alpha_composite(sm, (x0 + j * 150 if j < 2 else x0 + 300 + (j - 2) * 60, 620 if j < 2 else 640))
    d.text((x0, 20), f"{app}  (hue {int(h*360)}°)", fill=(40, 40, 40, 255))
sheet.convert("RGB").save(os.path.join(OUT, "sheet.png"))
print("ok")
