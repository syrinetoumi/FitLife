"""Render the sports-space showcase from real Flutter demo captures."""
import json
import math
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/showcase/python'))
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import imageio_ffmpeg

W, H, FPS = 1920, 1080, 24
MINT = '#6BF0A0'
WHITE = '#F7F8FF'
MUTED = '#B6BED8'
OUT = ROOT.parent / 'Fit Life Docs/media'
OUT.mkdir(parents=True, exist_ok=True)
WORK = ROOT / 'build/showcase'
FONT = Path('C:/Windows/Fonts')
BODY = FONT / 'segoeui.ttf'
BOLD = FONT / 'segoeuib.ttf'
TITLE = ROOT / 'assets/fonts/BarlowCondensed-BoldItalic.ttf'
font = lambda path, size: ImageFont.truetype(str(path), size)
scenes = json.loads((WORK / 'scenes.json').read_text(encoding='utf-8'))
intro = {'image': scenes[0]['image'], 'chapitre': 'FITLIFE / SHOWCASE', 'titre': 'Espaces\nsportifs.',
         'texte': 'Un parcours guidé des interfaces gestionnaire et athlète.', 'duree': 5}
outro = {'image': scenes[-1]['image'], 'chapitre': 'LE MODULE EN UN COUP D’ŒIL', 'titre': '5 entités.\nDeux parcours.',
         'texte': 'Espaces · Équipements · Horaires\nOffres · Abonnements', 'duree': 5}
scenes = [intro] + scenes + [outro]

# Build a reusable background and retain legible UI captures at their original aspect ratio.
bg = Image.new('RGB', (W, H))
d = ImageDraw.Draw(bg)
for y in range(H):
    t = y / H
    d.line((0, y, W, y), fill=(int(12+7*t), int(17+11*t), int(38+18*t)))
d.ellipse((1040, -230, 2220, 950), outline='#26305B', width=2)
d.ellipse((1140, -130, 2120, 850), outline='#26305B', width=2)
d.rectangle((0, 0, 14, H), fill='#3742B5')

def wrap(text, face, width):
    lines = []
    for para in text.split('\n'):
        line = ''
        for word in para.split():
            trial = (line + ' ' + word).strip()
            if face.getlength(trial) > width and line:
                lines.append(line); line = word
            else: line = trial
        lines.append(line)
    return lines


def compose(scene, index):
    im = bg.copy(); dr = ImageDraw.Draw(im)
    dr.text((112, 70), 'FITLIFE', font=font(TITLE, 82), fill=WHITE)
    dr.text((114, 159), 'ESPACES SPORTIFS', font=font(BOLD, 22), fill=MUTED)
    dr.rounded_rectangle((114, 272, 168, 279), radius=3, fill=MINT)
    dr.text((190, 252), scene['chapitre'], font=font(BOLD, 24), fill=MINT)
    face = font(TITLE, 100)
    title_lines = wrap(scene['titre'], face, 990)
    y = 327
    for line in title_lines:
        dr.text((107, y), line, font=face, fill=WHITE)
        y += 111
    y += 29
    for line in wrap(scene['texte'], font(BODY, 32), 950):
        dr.text((114, y), line, font=font(BODY, 32), fill=MUTED)
        y += 47
    if index == len(scenes)-1:
        dr.text((114, y+35), 'Interfaces réelles · Scénario de démonstration', font=font(BOLD, 24), fill=MINT)
    # Phone frame; the screenshot itself remains uncropped.
    screenshot = Image.open(WORK / 'captures' / scene['image']).convert('RGB')
    screenshot = screenshot.resize((430, 900), Image.Resampling.LANCZOS)
    x, sy = 1280, 90
    shadow = Image.new('RGBA', (W,H), (0,0,0,0)); sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x-21, sy-13, x+451, sy+932), radius=49, fill=(0,0,0,160))
    im = Image.alpha_composite(im.convert('RGBA'), shadow.filter(ImageFilter.GaussianBlur(18))).convert('RGB')
    dr = ImageDraw.Draw(im)
    dr.rounded_rectangle((x-16,sy-16,x+446,sy+916), radius=39, fill='#111827', outline='#5D6685', width=2)
    mask = Image.new('L',(430,900)); ImageDraw.Draw(mask).rounded_rectangle((0,0,429,899), radius=25, fill=255)
    im.paste(screenshot,(x,sy),mask)
    dr.rounded_rectangle((x+165,sy+886,x+265,sy+891), radius=3, fill='#9CA3AF')
    dr.text((115, 930), 'DÉMONSTRATION  /  DONNÉES FICTIVES', font=font(BOLD, 19), fill=MUTED)
    dr.text((114, 970), f'{index+1:02d} / {len(scenes):02d}', font=font(BODY, 19), fill=MUTED)
    dr.text((337, 970), 'GESTIONNAIRE + ATHLÈTE', font=font(BODY, 19), fill=MUTED)
    return im

cards = [compose(s,i) for i,s in enumerate(scenes)]
for index in [0, 4, 8, 14, len(scenes)-1]:
    cards[index].save(WORK / f'preview-{index:02d}.png')
output = OUT / 'FitLife-Espaces-Sportifs-Showcase.mp4'
writer = imageio_ffmpeg.write_frames(str(output), (W,H), fps=FPS, codec='libx264',
    pix_fmt_in='rgb24', pix_fmt_out='yuv420p', quality=None, macro_block_size=1,
    output_params=['-crf','20','-preset','fast','-movflags','+faststart'])
writer.send(None)
total_frames = sum(round(s['duree']*FPS) for s in scenes)
frame_number = 0
for i, scene in enumerate(scenes):
    frames = round(scene['duree']*FPS)
    for f in range(frames):
        frame = cards[i]
        if i > 0 and f < 9:
            t = f/8
            frame = Image.blend(cards[i-1], frame, t*t*(3-2*t))
        else: frame = frame.copy()
        draw = ImageDraw.Draw(frame)
        draw.rounded_rectangle((114,1018,1090,1023), radius=2, fill='#303956')
        progress = (frame_number+1)/total_frames
        draw.rounded_rectangle((114,1018,114+976*progress,1023), radius=2, fill=MINT)
        writer.send(frame.tobytes())
        frame_number += 1
    print(f'Rendered scene {i+1}/{len(scenes)}', flush=True)
writer.close()
# A shareable cover and subtitle file accompany the video.
cards[0].save(OUT / 'FitLife-Espaces-Sportifs-Showcase-cover.jpg', quality=93)
def stamp(seconds):
    ms=round(seconds*1000); h,ms=divmod(ms,3600000); m,ms=divmod(ms,60000); sec,ms=divmod(ms,1000)
    return f'{h:02d}:{m:02d}:{sec:02d},{ms:03d}'
elapsed=0; subtitles=[]
for i, scene in enumerate(scenes):
    subtitles.append(f"{i+1}\n{stamp(elapsed)} --> {stamp(elapsed+scene['duree'])}\n{scene['titre'].replace(chr(10),' ')}\n{scene['texte']}\n")
    elapsed += scene['duree']
(OUT/'FitLife-Espaces-Sportifs-Showcase.srt').write_text('\n'.join(subtitles),encoding='utf-8')
(OUT/'FitLife-Espaces-Sportifs-Showcase.json').write_text(json.dumps({'created':'2026-11-04','duration_seconds':elapsed,'resolution':[W,H],'fps':FPS,'audio':'none; French captions are baked in','source':'actual Flutter UI driven with explicit in-memory demo data','scenes':scenes}, ensure_ascii=False, indent=2),encoding='utf-8')
print(str(output), flush=True)
