#!/usr/bin/env python3
"""
Vulcan I - pygame port of the PureBasic original by Kenny Cason

Controls:
  WASD      - move
  J         - shoot / hold for charge weapon
  K         - cycle weapon
  L         - speed down
  Tab       - skip to next level/boss (debug)
  Space     - pause
  Escape    - quit
"""
import pygame
import sys
import os
import random
import math
import json

# ── Constants ─────────────────────────────────────────────────────────────
SCREEN_W, SCREEN_H = 800, 600
GAME_H    = 500          # playfield; HUD occupies rows 500-600
MAX_ENEMIES = 25
MAX_BULLETS = 35
FPS = 60

BASE    = os.path.dirname(os.path.abspath(__file__))
SPRITES = os.path.join(BASE, "sprites")
SOUND   = os.path.join(BASE, "sound")
SAVE    = os.path.join(BASE, "vulcan.json")

# ── Sprite / sound registries ──────────────────────────────────────────────
spr: dict[int, pygame.Surface] = {}
sfx: dict[int, pygame.mixer.Sound] = {}


def _fallback(color, w=32, h=32):
    s = pygame.Surface((w, h))
    s.fill(color)
    return s


def load_spr(num, *parts, ck=(0, 0, 0), fb=(128, 128, 128), sz=(32, 32)):
    path = os.path.join(SPRITES, *parts)
    try:
        surf = pygame.image.load(path).convert()
        loaded = True
    except Exception:
        surf = _fallback(fb, *sz)
        loaded = False
    surf.set_colorkey(ck)   # apply to both real and fallback surfaces
    spr[num] = surf
    return loaded


def load_spr_bg(num, *parts, fb=(5, 5, 20), sz=(320, 240)):
    path = os.path.join(SPRITES, *parts)
    try:
        surf = pygame.image.load(path).convert()
    except Exception:
        surf = _fallback(fb, *sz)
    spr[num] = surf


def get_w(num): return spr[num].get_width()  if num in spr else 32
def get_h(num): return spr[num].get_height() if num in spr else 32


def blit_s(screen, num, x, y):
    if num in spr:
        screen.blit(spr[num], (int(x), int(y)))


def load_sfx(num, *parts):
    path = os.path.join(SOUND, "wav", *parts)
    try:
        sfx[num] = pygame.mixer.Sound(path)
    except Exception:
        pass


def load_ogg(num, *parts):
    path = os.path.join(SOUND, "ogg", *parts)
    try:
        sfx[num] = pygame.mixer.Sound(path)
    except Exception:
        pass


def play_sfx(num, loops=0):
    if num in sfx:
        sfx[num].play(loops=loops)


def stop_sfx(num):
    if num in sfx:
        sfx[num].stop()


# ── Bitmap font ────────────────────────────────────────────────────────────
def bitmap_text(screen, text, x, y):
    x = int(x)
    for ch in text.upper():
        if ch == ' ':
            x += 20
            continue
        code = ord(ch)
        if 65 <= code <= 90:
            idx = 736 + code      # A=801 … Z=826
        elif 48 <= code <= 57:
            idx = 779 + code      # 0=827 … 9=836
        else:
            x += 20
            continue
        if idx in spr:
            screen.blit(spr[idx], (x, int(y)))
            x += get_w(idx)


# ── Asset loading ──────────────────────────────────────────────────────────
def load_all_assets():
    # Font  A-Z → 801-826, digits 0-9 → 827-836
    for i, c in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
        load_spr(801 + i, "Font", f"{c.lower()}.bmp", fb=(255, 255, 255), sz=(14, 18))
    for i in range(10):
        load_spr(827 + i, "Font", f"{i}.bmp", fb=(255, 255, 255), sz=(14, 18))
    # Scale font to a compact size so the HUD fits within 100px
    # Large (title) use stays readable; HUD rows become non-overlapping
    for idx in list(range(801, 827)) + list(range(827, 837)):
        if idx in spr:
            s = spr[idx]
            spr[idx] = pygame.transform.scale(s, (max(1, s.get_width() * 3 // 4),
                                                   max(1, s.get_height() * 3 // 4)))

    # Title / crosshair
    load_spr_bg(501, "Title.jpg",   fb=(20, 20, 60),  sz=(800, 600))
    load_spr_bg(502, "Title2.jpg",  fb=(20, 20, 60),  sz=(800, 600))
    load_spr(510, "crosshair.bmp",  fb=(255, 255, 0), sz=(24, 24))
    load_spr(511, "crosshair2.bmp", fb=(200, 200, 0), sz=(24, 24))

    # Ship  1-3 normal, 4-6 down, 7-9 up, 40-42 forward
    for k in range(1, 4):
        load_spr(k,      f"ship{k}.bmp",        fb=(0, 180, 255), sz=(50, 36))
        load_spr(k + 3,  f"ship{k}_down.bmp",   fb=(0, 180, 255), sz=(50, 36))
        load_spr(k + 6,  f"ship{k}_up.bmp",     fb=(0, 180, 255), sz=(50, 36))
        load_spr(k + 39, f"ship{k}_forward.bmp",fb=(0, 180, 255), sz=(50, 36))
    for k in range(1, 4):          # iship 495-497
        load_spr(494 + k, f"iship_{k}.bmp",     fb=(0, 150, 200), sz=(40, 30))
    for k in range(1, 3):          # icon 498-499
        load_spr(497 + k, f"icon_{k}.bmp",      fb=(200, 200, 80), sz=(30, 30))

    # Bullets 10-15, explosions 16-23
    for k in range(1, 7):
        load_spr(9 + k,   f"Bullet_{k}.bmp",      fb=(255, 255, 0), sz=(16, 8))
    for k in range(1, 9):
        load_spr(15 + k,  f"Explosion_{k}.bmp",   fb=(255, 100, 0), sz=(64, 64))
    for k in range(1, 7):
        load_spr(149 + k, f"Bullet_back_{k}.bmp", fb=(255, 200, 0), sz=(16, 8))
        load_spr(159 + k, f"Bullet_left_{k}.bmp", fb=(200, 255, 0), sz=(8, 16))
        load_spr(169 + k, f"Bullet_right_{k}.bmp",fb=(200, 200, 0), sz=(8, 16))

    # Beams 400-407, back 422-424, left 443, right 463, charging 480-482
    for k in range(1, 9):
        load_spr(399 + k, f"beam_{k}.bmp",       fb=(0, 255, 200), sz=(40, 20))
    for k in range(2, 5):
        load_spr(420 + k, f"beam_back_{k}.bmp",  fb=(0, 200, 255), sz=(40, 20))
    load_spr(443, "beam_left_3.bmp",              fb=(0, 200, 255), sz=(20, 40))
    load_spr(463, "beam_right_3.bmp",             fb=(0, 200, 255), sz=(20, 40))
    for k in range(1, 4):
        load_spr(479 + k, f"charging_{k}.bmp",   fb=(100, 100, 255), sz=(30, 30))

    # Enemy bullets 200-207, items 25-34
    for k in range(1, 9):
        load_spr(199 + k, f"enemy_bullet_{k}.bmp", fb=(255, 60, 60), sz=(12, 12))
    for k in range(1, 11):
        load_spr(24 + k, f"item_{k}.bmp",          fb=(0, 220, 100), sz=(22, 22))

    # Enemies
    for k in range(1, 7):   # enemy_1  250-255
        load_spr(249 + k, f"Enemy_1_{k}.bmp",   fb=(200, 50, 50),  sz=(48, 36))
    for k in range(1, 7):   # enemy_2  256-261
        load_spr(255 + k, f"enemy_2_{k}.bmp",   fb=(180, 80, 80),  sz=(48, 36))
    for k in range(1, 8):   # enemy_3  262-268
        load_spr(261 + k, f"enemy_3_{k}.bmp",   fb=(160, 100, 80), sz=(48, 36))
    for k in range(1, 4):   # asteroids 269-271
        load_spr(268 + k, f"asteriod_1_{k}.bmp",fb=(140, 120, 100),sz=(60, 60))
    for k in range(1, 8):   # enemy_4  272-278
        load_spr(271 + k, f"Enemy_4_{k}.bmp",   fb=(80, 80, 200),  sz=(48, 36))
    for k in range(1, 5):   # enemy_5  279-282
        load_spr(278 + k, f"enemy_5_{k}.bmp",   fb=(80, 200, 80),  sz=(48, 36))
    for k in range(1, 10):  # enemy_6  283-291
        load_spr(282 + k, f"enemy_6_{k}.bmp",   fb=(200, 80, 200), sz=(48, 36))
    for k in range(1, 3):   # boss_1  300-301
        load_spr(299 + k, f"boss_1_{k}.bmp",    fb=(255, 0, 0),    sz=(150, 120))
    for k in range(1, 12):  # boss_2  302-312
        load_spr(301 + k, f"boss_2_{k}.bmp",    fb=(220, 30, 30),  sz=(150, 120))
    for k in range(1, 3):   # boss_3  313-314
        load_spr(312 + k, f"boss_3_{k}.bmp",    fb=(200, 50, 50),  sz=(150, 120))
    for k in range(1, 5):   # boss_4  315-318
        load_spr(314 + k, f"boss_4_{k}.bmp",    fb=(180, 60, 60),  sz=(150, 120))
    for k in range(1, 11):  # enemy_7  319-328
        load_spr(318 + k, f"enemy_7_{k}.bmp",   fb=(100, 180, 180),sz=(48, 36))

    # Backgrounds (stored as sprites 1001,1002,1005 to avoid colliding with ship 1-3)
    for k in (1, 2, 5):
        load_spr_bg(1000 + k, f"back_{k}.bmp", fb=(5, 5, 20), sz=(320, 240))

    # Level images — use indices 601-608 (501-502 are reserved for title screens)
    # colorkey=(0,0,0): black areas transparent so star background shows through
    for n in range(1, 9):
        loaded = False
        for ext in ("png", "jpg", "bmp"):
            path = os.path.join(SPRITES, "level", f"level_{n}.{ext}")
            if os.path.exists(path):
                try:
                    surf = pygame.image.load(path).convert()
                    surf.set_colorkey((0, 0, 0))
                    spr[600 + n] = surf
                    print(f"[vulcan] level_{n}.{ext} OK  size={surf.get_size()}")
                    loaded = True
                    break
                except Exception as e:
                    print(f"[vulcan] level_{n}.{ext} FAILED: {e}")
        if not loaded:
            print(f"[vulcan] level_{n} not found (tried png/jpg/bmp)")
            s = pygame.Surface((4000, 500))
            s.fill((0, 0, 0))
            s.set_colorkey((0, 0, 0))
            spr[600 + n] = s

    # Sounds
    load_sfx(1, "weapon_1.wav")
    load_sfx(2, "plasma_1.wav")
    load_sfx(3, "plasma_2.wav")
    load_sfx(4, "plasma_3.wav")
    load_sfx(5, "Explosion_1.wav")
    load_sfx(6, "shield_1.wav")
    load_sfx(7, "shield_2.wav")
    load_sfx(8, "bullethit.wav")
    load_ogg(30, "level_1.ogg")

    # Balance: SFX at 25%, music at full
    for num, sound in sfx.items():
        sound.set_volume(1.0 if num == 30 else 0.25)


# ── Save / load hi-score ───────────────────────────────────────────────────
def load_hi():
    try:
        with open(SAVE) as f:
            d = json.load(f)
        return (d.get("hiscore", 0), d.get("unlock", 0),
                d.get("beatgame", 0), d.get("maxkills", 0),
                d.get("hiplayer", "-----"))
    except Exception:
        return 0, 0, 0, 0, "-----"


def save_hi_file(hiscore, unlock, beatgame, maxkills, hiplayer):
    try:
        with open(SAVE, "w") as f:
            json.dump({"hiscore": hiscore, "unlock": unlock,
                       "beatgame": beatgame, "maxkills": maxkills,
                       "hiplayer": hiplayer}, f)
    except Exception:
        pass


# ── Game ───────────────────────────────────────────────────────────────────
class Game:
    def __init__(self, screen: pygame.Surface):
        self.screen  = screen
        self.clock   = pygame.time.Clock()
        self.running = True

        self.hiscore, self.unlock, self.beatgame, \
            self.maxkills, self.hiplayer = load_hi()

        self.mode       = 1
        self.bonuslevel = 0
        self._reset_game()

    # ── Reset / NewGame ────────────────────────────────────────────────────
    def _reset_game(self):
        self.score      = 0
        self.lives      = 5
        self.lvl        = 0
        self.lastlevel  = 7
        self.lvlup      = 1
        self.miss       = 0
        self.hit        = 0
        self.enemykill  = 0
        self.paused     = False
        self.gameover   = False

        # Weapon
        self.weaponselect   = 10
        self.weaponstrength = 1.0
        self.weaponspeed    = 16
        self.beamselect     = 0
        self.beam           = 0
        self.beam0 = 1
        self.beam1 = self.beam2 = self.beam3 = self.beam4 = 0
        self.special    = 0
        self.charge     = 0
        self.chargetime = 0
        self.chargeimage = 480

        # Player
        self.shield       = 1
        self.playerimage  = 1
        self.playerx      = 100.0
        self.playery      = SCREEN_H / 2
        self.playerspeedx = 3
        self.playerspeedy = 3
        self.playerwidth  = get_w(1)
        self.playerheight = get_h(1)
        self.bulletspeedx = 18
        self.bulletspeedy = 10
        self.deaddelay    = 0    # no flicker on first spawn; post-death uses 100
        self.dead_flag    = 0
        self.flash        = 0
        self.adjusty      = 0

        # Level
        self.boss          = 1
        self.bossexplosion = 0
        self.levelx        = -5000.0
        self.levely        = 0.0
        self.levellength   = 0
        self.levelheight   = 500
        self.levelspeed    = -3
        self.levelimage_num = 501   # placeholder; updated in setup_level
        self.backgroundmap  = 1002
        self.backgroundspeedx = -4
        self.backgroundspeedy = 0
        self.scrollx = 0.0
        self.scrolly = 0.0
        self.lvlsound      = 30
        self.lvldifficulty = 220
        self.howmany       = 3
        self.itemfrequency = 70
        self.do            = 0

        # Enemy spawn config  (3 type slots)
        self.enemyset   = 1
        self.frequency1 = 50
        self.frequency2 = 80
        self.enemydelay = 100

        # Type-1 defaults
        self.EStartImage1=250; self.EEndImage1=255; self.EActualImage1=250
        self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
        self.EspeedX1=3;       self.EspeedY1=3
        self.Eweapon1=200;     self.Eshotchance1=9
        self.EArmor1=1;        self.Epointvalue1=40
        self.Eweaponstrength1=1; self.Eflight1=1
        self.Emisc1=0;         self.EImageDelay=4; self.ENextImageDelay=4
        self.Edeaddelay=20

        # Type-2 defaults
        self.EStartImage2=256; self.EEndImage2=261; self.EActualImage2=256
        self.Eattacktype2=0;   self.Ebspeedx2=-5;  self.Ebspeedy2=0
        self.EspeedX2=3;       self.EspeedY2=3
        self.Eweapon2=200;     self.Eshotchance2=9
        self.EArmor2=1;        self.Epointvalue2=40
        self.Eweaponstrength2=1; self.Eflight2=1

        # Type-3 defaults
        self.EStartImage3=272; self.EEndImage3=278; self.EActualImage3=272
        self.Eattacktype3=0;   self.Ebspeedx3=-4;  self.Ebspeedy3=0
        self.EspeedX3=2;       self.EspeedY3=2
        self.Eweapon3=200;     self.Eshotchance3=3
        self.EArmor3=1;        self.Epointvalue3=30
        self.Eweaponstrength3=1; self.Eflight3=2

        # Entity lists
        self.enemies    = []
        self.bullets    = []
        self.ebullets   = []
        self.items      = []
        self.explosions = []

        self.selectdelay = 0
        self.bulletdelay = 0
        self.skipdelay   = 0

    # ── Entity helpers ─────────────────────────────────────────────────────
    def _delete_enemies(self):      self.enemies.clear()
    def _delete_ebullets(self):     self.ebullets.clear()
    def _delete_bullets(self):      self.bullets.clear()
    def _delete_items(self):        self.items.clear()

    def _player_rect(self):
        return pygame.Rect(self.playerx, self.playery,
                           self.playerwidth, self.playerheight)

    def _enemy_rect(self, e):
        return pygame.Rect(e['x'], e['y'], e['width'], e['height'])

    def _bullet_rect(self, b):
        return pygame.Rect(b['x'], b['y'], get_w(b['image']), get_h(b['image']))

    # ── Terrain collision ──────────────────────────────────────────────────
    def _terrain_pixel(self, lvl_surf, sx, sy):
        """Check a single screen-space point against the level image."""
        ix = int(sx - self.levelx)
        iy = int(sy - self.levely)
        if ix < 0 or iy < 0:
            return False
        if ix >= lvl_surf.get_width() or iy >= lvl_surf.get_height():
            return False
        c = lvl_surf.get_at((ix, iy))
        return (c[0] + c[1] + c[2]) > 80

    def _terrain_hit(self, x, y):
        lvl_surf = spr.get(self.levelimage_num)
        if lvl_surf is None:
            return False
        pw = self.playerwidth or 32
        ph = self.playerheight or 32
        # Check 5 points: 4 corners (inset 4px) + centre; require 2+ hits
        # to avoid false positives from single bright star pixels.
        pts = [
            (x + 4,          y + 4),           # top-left inset
            (x + pw - 4,     y + 4),           # top-right inset
            (x + pw // 2,    y + ph // 2),     # centre
            (x + 4,          y + ph - 4),      # bottom-left inset
            (x + pw - 4,     y + ph - 4),      # bottom-right inset
        ]
        hits = sum(1 for px, py in pts if self._terrain_pixel(lvl_surf, px, py))
        return hits >= 2

    # ── Title screen ───────────────────────────────────────────────────────
    def _title_screen(self):
        px, py = 390.0, 290.0
        while True:
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    self.running = False
                    return
                if ev.type == pygame.KEYDOWN and ev.key == pygame.K_ESCAPE:
                    self.running = False
                    return

            keys = pygame.key.get_pressed()
            if keys[pygame.K_w] or keys[pygame.K_UP]:    py -= 2
            if keys[pygame.K_s] or keys[pygame.K_DOWN]:  py += 2
            if keys[pygame.K_a] or keys[pygame.K_LEFT]:  px -= 2
            if keys[pygame.K_d] or keys[pygame.K_RIGHT]: px += 2

            cw = get_w(510); ch = get_h(510)
            px = max(0, min(px, SCREEN_W - cw))
            py = max(0, min(py, SCREEN_H - ch))

            fire = keys[pygame.K_j] or keys[pygame.K_RETURN]
            if fire:
                if 346 <= px <= 430 and 245 < py < 275:
                    self.mode = 1; return
                elif 320 <= px <= 470 and 278 < py < 302:
                    self.mode = 2; return
                elif self.unlock > 0 and 346 <= px <= 435 and 306 < py < 332:
                    self.mode = 3; return
                elif self.unlock > 1 and 170 <= px <= 645 and 336 < py < 360:
                    self.mode = 4; return

            self.screen.fill((0, 0, 0))
            blit_s(self.screen, 501 if not self.beatgame else 502, 0, 0)
            bitmap_text(self.screen, "EASY",   360, 260)
            bitmap_text(self.screen, "NORMAL", 330, 290)
            if self.unlock > 0:
                bitmap_text(self.screen, "HARD", 360, 320)
            if self.unlock > 1:
                bitmap_text(self.screen, "SUPER ULTRA MEGA HARD", 180, 350)
            bitmap_text(self.screen, "HI SCORE", 330, 410)
            bitmap_text(self.screen, str(self.hiscore), 350, 440)
            bitmap_text(self.screen, self.hiplayer, 350, 470)
            blit_s(self.screen, 510 if not self.beatgame else 511, px, py)
            pygame.display.flip()
            self.clock.tick(FPS)

    # ── Between levels splash ──────────────────────────────────────────────
    def _between_levels(self):
        names = {1:"METROPOLA", 2:"THE OASIS", 3:"METEORA", 4:"RED BARON",
                 5:"THE CAVES",  6:"THE CELERON", 7:"ASSEMBLER"}
        label = "UNKNOWN LANDS" if self.bonuslevel else names.get(self.lvl, "")
        self.screen.fill((0, 0, 0))
        bitmap_text(self.screen, label, 300, 275)
        pygame.display.flip()
        pygame.time.delay(1500)

    # ── Credits roll ───────────────────────────────────────────────────────
    def _show_credits(self):
        lines = [
            "CONGRATULATIONS", "PEACE HAS BEEN RESTORED", "TO THE UNIVERSE", "",
            "CREDITS", "", "PROGRAMMER", "KENNY CASON", "",
            "CUSTOM GRAPHICS", "KENNY CASON", "DAVID JOHNSON", "JOSH DAUGHERTY", "",
            "MUSIC", "TONY LOFTON", "", "OTHER THANKS", "UAGDC", "PUREBASIC",
            "NINTENDO", "MICHAEL BIEBESHEIMER", "", "BETA TESTERS",
            "DAVID JOHNSON", "JOHN DEFOREST", "CONNIE JIANG", "GLADSON RIPLEY", "",
            "THE END", "", "ENEMIES KILLED", str(self.enemykill),
            "SCORE", str(self.score),
        ]
        stop_sfx(30)
        total_h = len(lines) * 30
        for y in range(700, -total_h - 200, -1):
            self.screen.fill((0, 0, 0))
            for i, t in enumerate(lines):
                bitmap_text(self.screen, t, 260, y + i * 30)
            pygame.display.flip()
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    return
                if ev.type == pygame.KEYDOWN and ev.key == pygame.K_ESCAPE:
                    return
            self.clock.tick(90)

    def _beat_game(self):
        if self.mode == 2 and self.unlock < 1: self.unlock = 1
        elif self.mode == 3 and self.unlock < 2: self.unlock = 2
        elif self.mode == 4 and self.unlock < 3: self.unlock = 3
        if self.mode > 2:
            self.beatgame = 1
        if self.hit + self.miss > 0:
            self.score += int((self.hit / (self.hit + self.miss) * 100) * 250)
        self._save_hi()
        self._show_credits()
        self._title_screen()
        if not self.running:
            return
        self._reset_game()
        self._setup_level()

    def _save_hi(self):
        if self.score > self.hiscore:
            self.hiscore  = self.score
            self.hiplayer = "PLYR "
        if self.enemykill > self.maxkills:
            self.maxkills = self.enemykill
        save_hi_file(self.hiscore, self.unlock, self.beatgame,
                     self.maxkills, self.hiplayer)

    # ── Add boss helper ────────────────────────────────────────────────────
    def _add_boss(self, si, ei, imgdelay, speedx, speedy, armor, pts,
                  shotchance, dirx, weapon, wstrength, bspx, bspy,
                  attacktype, misc1, deaddelay, ex, ey):
        e = {
            'x': float(ex), 'y': float(ey),
            'width':  get_w(si), 'height': get_h(si),
            'speedx': speedx, 'speedy': speedy,
            'start_image': si, 'end_image': ei,
            'image_delay': imgdelay, 'next_image_delay': imgdelay,
            'actual_image': si,
            'armor': float(armor), 'pointvalue': pts,
            'directionx': dirx, 'directiony': random.randint(0, 1),
            'weapon': weapon, 'weaponstrength': float(wstrength),
            'bspeedx': bspx, 'bspeedy': bspy,
            'shotchance': shotchance, 'attacktype': attacktype,
            'misc1': misc1, 'deaddelay': deaddelay, 'flight': 1,
        }
        self.enemies.append(e)

    # ── Level setup ────────────────────────────────────────────────────────
    def _setup_level(self):
        lvl  = self.lvl
        boss = self.boss

        if lvl == 1 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=70; self.lvldifficulty=220; self.howmany=3
            self.EStartImage1=250; self.EEndImage1=255; self.EActualImage1=250
            self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
            self.EspeedX1=3;       self.EspeedY1=3;    self.Eweapon1=200
            self.Eshotchance1=9;   self.EArmor1=1;     self.Epointvalue1=40
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=4;    self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 1 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=0; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            for _ in range(3):
                self._add_boss(302,312,6,2,2,15,5000,20,1,203,1,150,150,1,1,5,
                               SCREEN_H-150-random.randint(0,200),
                               300+random.randint(0,50))

        elif lvl == 2 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=70; self.lvldifficulty=220; self.howmany=4
            self.EStartImage1=256; self.EEndImage1=261; self.EActualImage1=256
            self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
            self.EspeedX1=3;       self.EspeedY1=3;    self.Eweapon1=200
            self.Eshotchance1=9;   self.EArmor1=1;     self.Epointvalue1=40
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=4;    self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 2 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=0; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            for _ in range(3):
                self._add_boss(302,312,6,2,2,15,5000,20,1,203,1,150,150,1,1,5,
                               SCREEN_H-150-random.randint(0,200),
                               300+random.randint(0,50))

        elif lvl == 3 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=70; self.lvldifficulty=150; self.howmany=5
            self.EStartImage1=269; self.EEndImage1=269; self.EActualImage1=269
            self.Eattacktype1=1000; self.EspeedX1=3; self.EspeedY1=0
            self.Eweapon1=200; self.Eshotchance1=10; self.EArmor1=2000
            self.Epointvalue1=3000; self.Eweaponstrength1=0; self.Eflight1=1
            self.EStartImage2=270; self.EEndImage2=270; self.EActualImage2=270
            self.Eattacktype2=100; self.EspeedX2=3; self.EspeedY2=0
            self.Eweapon2=200; self.Eshotchance2=10; self.EArmor2=2000
            self.Epointvalue2=3000; self.Eweaponstrength2=0; self.Eflight2=1
            self.EStartImage3=272; self.EEndImage3=278; self.EActualImage3=272
            self.Eattacktype3=0;   self.Ebspeedx3=-4; self.Ebspeedy3=0
            self.EspeedX3=2;       self.EspeedY3=2;   self.Eweapon3=200
            self.Eshotchance3=3;   self.EArmor3=1;    self.Epointvalue3=30
            self.Eweaponstrength3=1; self.Eflight3=2
            self.frequency1=10; self.frequency2=50; self.enemyset=3; self.Emisc1=0
            self.EImageDelay=4; self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 3 and boss == 1:
            self._delete_enemies(); self.levelspeed=0; self.itemfrequency=0
            self._add_boss(300,301,2,2,3,40,5000,40,0,202,1,-5,0,0,1,5,
                           SCREEN_W-300, 100)

        elif lvl == 4 and boss == 0:
            self.levely=0; self.backgroundmap=1005
            self.backgroundspeedx=-1; self.backgroundspeedy=0
            self.levelspeed=-3; self.howmany=0
            self.itemfrequency=70; self.lvldifficulty=200
            self.EStartImage1=256; self.EEndImage1=261; self.EActualImage1=256
            self.Eattacktype1=1;   self.Ebspeedx1=100; self.Ebspeedy1=100
            self.EspeedX1=2;       self.EspeedY1=2;    self.Eweapon1=200
            self.Eshotchance1=6;   self.EArmor1=1;     self.Epointvalue1=40
            self.Eweaponstrength1=1; self.Emisc1=0;    self.Eflight1=2
            self.enemyset=1; self.EImageDelay=4; self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 4 and boss == 1:
            self._delete_enemies(); self.levelspeed=0; self.itemfrequency=0
            self._add_boss(300,301,2,0,2,40,5000,70,0,202,1,-5,0,0,1,5,
                           SCREEN_W-400, 300)

        elif lvl == 5 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=70; self.lvldifficulty=280; self.howmany=0
            self.EStartImage1=302; self.EEndImage1=312; self.EActualImage1=302
            self.Eattacktype1=1;   self.Ebspeedx1=130; self.Ebspeedy1=130
            self.EspeedX1=3;       self.EspeedY1=3;    self.Eweapon1=203
            self.Eshotchance1=8;   self.EArmor1=2;     self.Epointvalue1=40
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=4;    self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 5 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=0; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            for _ in range(3):
                self._add_boss(302,312,6,2,2,15,5000,20,1,203,1,150,150,1,1,5,
                               SCREEN_H-150-random.randint(0,200),
                               300+random.randint(0,50))

        elif lvl == 6 and boss == 0:
            self.playerspeedx=6; self.playerspeedy=6
            self.backgroundmap=1002; self.backgroundspeedx=-20; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-10
            self.itemfrequency=40; self.lvldifficulty=99999; self.howmany=2
            self.EStartImage1=250; self.EEndImage1=255; self.EActualImage1=250
            self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
            self.EspeedX1=3;       self.EspeedY1=3;    self.Eweapon1=201
            self.Eshotchance1=0;   self.EArmor1=1;     self.Epointvalue1=1000
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=4;    self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 6 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=-20; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            self._add_boss(315,318,20,1,0,55,10000,13,1,205,1,90,90,1,1,5,
                           420, 230)

        elif lvl == 7 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=40; self.lvldifficulty=200; self.howmany=2
            self.EStartImage1=319; self.EEndImage1=328; self.EActualImage1=319
            self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
            self.EspeedX1=3;       self.EspeedY1=3;    self.Eweapon1=204
            self.Eshotchance1=9;   self.EArmor1=1;     self.Epointvalue1=40
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=4;    self.ENextImageDelay=4; self.Edeaddelay=20

        elif lvl == 7 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            self._add_boss(313,314,3,0,0,50,25000,12,1,205,1,-3,0,2,1,5,
                           550, 330)
            for k in range(0, 121, 40):
                self._add_boss(279,281,3,0,0,15,2502,0,1,205,1,-3,0,2,1,5,
                               400-k, 335)

        elif lvl == 8 and boss == 0:
            self.backgroundmap=1002; self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levely=0; self.levelspeed=-3
            self.itemfrequency=40; self.lvldifficulty=180; self.howmany=2
            self.EStartImage1=283; self.EEndImage1=291; self.EActualImage1=283
            self.Eattacktype1=0;   self.Ebspeedx1=-5;  self.Ebspeedy1=0
            self.EspeedX1=5;       self.EspeedY1=3;    self.Eweapon1=200
            self.Eshotchance1=-1000; self.EArmor1=1;   self.Epointvalue1=50
            self.Eweaponstrength1=1; self.Eflight1=1;  self.enemyset=1; self.Emisc1=0
            self.EImageDelay=5;    self.ENextImageDelay=5; self.Edeaddelay=20

        elif lvl == 8 and boss == 1:
            self._delete_enemies()
            self.backgroundspeedx=-4; self.backgroundspeedy=0
            self.levelspeed=0; self.itemfrequency=0
            self._add_boss(313,314,3,0,0,15,15000,10,1,205,1,-5,-5,2,1,5,
                           255, 270)
        else:
            self._beat_game()
            return

        # Common post-setup
        if boss == 0:
            self.enemydelay      = 100
            self.levelimage_num  = 600 + lvl   # 601-608, clear of title sprites 501-502
            self.levelheight     = get_h(self.levelimage_num) or 500
            self.levellength     = get_w(self.levelimage_num) or 4000
            self.levelx          = float(SCREEN_W)
        else:
            self.enemydelay = 0
            self.levelx     = float(-self.levellength + SCREEN_W)

        print(f"[level] lvl={lvl} boss={boss}  levelimage={self.levelimage_num} "
              f"size={get_w(self.levelimage_num)}x{get_h(self.levelimage_num)} "
              f"levelx={self.levelx:.0f}  difficulty={self.lvldifficulty}")

        self.lvldifficulty = max(1, self.lvldifficulty // max(1, self.mode))
        if self.playery > self.levelheight - self.playerheight:
            self.playery = self.levelheight // 2
        self.scrollx = 0.0
        self.scrolly = 0.0
        stop_sfx(30)
        play_sfx(30, loops=-1)

    # ── Advance level ──────────────────────────────────────────────────────
    def _advance_level(self):
        if self.boss == 0:
            self.boss = 1
        else:
            self.boss  = 0
            self.lvl  += 1
            if self.lvl == self.lastlevel + 2 and self.bonuslevel:
                self.bonuslevel = 0; self.lvl = 8
            elif self.lvl == self.lastlevel + 2:
                self.lvl = 1
            elif self.lvl == self.lastlevel + 1:
                self._beat_game()
                return
            else:
                self._between_levels()
                self._delete_ebullets()
        self._setup_level()

    # ── Shoot ──────────────────────────────────────────────────────────────
    def _shoot(self):
        bs = self.beamselect
        px, py = self.playerx, self.playery
        sp = self.special

        if bs == 0:  # Phazor
            self.bulletdelay = self.weaponspeed
            num = 150 if self.weaponselect == 10 else 149
            self.bullets.append({'x':px+50,'y':py-5,'image':self.weaponselect,
                'speedx':float(self.bulletspeedx),'speedy':0.0,
                'strength':self.weaponstrength,'life':0})
            if sp >= 1:
                self.bullets.append({'x':px-20,'y':py-5,
                    'image':self.weaponselect+num-10,
                    'speedx':float(-self.bulletspeedx),'speedy':0.0,
                    'strength':self.weaponstrength,'life':0})
            if sp >= 2:
                self.bullets.append({'x':px,'y':py-10,
                    'image':self.weaponselect+num,
                    'speedx':0.0,'speedy':float(-self.bulletspeedy),
                    'strength':self.weaponstrength,'life':0})
                self.bullets.append({'x':px,'y':py+30,
                    'image':self.weaponselect+num+10,
                    'speedx':0.0,'speedy':float(self.bulletspeedy),
                    'strength':self.weaponstrength,'life':0})
            play_sfx(1)

        elif bs == 1:  # Homing
            self.bulletdelay = 25
            k = 0
            for e in self.enemies:
                if e['weaponstrength'] > 0 and k <= sp * 2 + 2:
                    dx = e['x'] - px; dy = e['y'] - py
                    dist = math.sqrt(dx*dx + dy*dy) or 1
                    vx = dx/dist + dx/(14 - sp)
                    vy = dy/dist + dy/(14 - sp)
                    self.bullets.append({'x':px+40,'y':py+5,
                        'image':399+self.beam,'speedx':vx,'speedy':vy,
                        'strength':1,'life':0})
                    k += 1
            if k == 0:
                self.bullets.append({'x':px+50,'y':py-5,
                    'image':399+self.beam,'speedx':18.0,'speedy':0.0,
                    'strength':1,'life':0})
            play_sfx(1)

        elif bs == 2:  # Plasma
            self.bulletdelay = 25
            if sp < 1:
                self.bullets.append({'x':px+50,'y':py-5,'image':399+self.beam,
                    'speedx':14.0,'speedy':0.0,'strength':3,'life':0})
            else:
                self.bullets.append({'x':px+50,'y':py-8,'image':399+self.beam,
                    'speedx':14.0,'speedy':0.0,'strength':3,'life':0})
                self.bullets.append({'x':px+50,'y':py+20,'image':399+self.beam,
                    'speedx':14.0,'speedy':0.0,'strength':3,'life':0})
                if sp >= 2:
                    self.bullets.append({'x':px-80,'y':py-8,'image':399+self.beam,
                        'speedx':-14.0,'speedy':0.0,'strength':3,'life':0})
                    self.bullets.append({'x':px-80,'y':py+20,'image':399+self.beam,
                        'speedx':-14.0,'speedy':0.0,'strength':3,'life':0})
            play_sfx(min(sp + 1, 4))

        elif bs == 3:  # Vulcan spread
            self.bulletdelay = 30
            angles = [(-10, 11), (-6, 13), (-2, 15), (2, 15), (6, 13), (10, 11)]
            img_base = 399 + self.beam + (5 if sp >= 2 else 0)
            for sy, sx in angles:
                self.bullets.append({'x':px+50,'y':py-5,'image':img_base,
                    'speedx':float(sx),'speedy':float(sy),'strength':1,'life':0})
            if sp > 0:
                back = [(-8, 12), (-4, 14), (0, 15), (4, 14), (8, 12)]
                for sy, sx in back:
                    self.bullets.append({'x':px-5,'y':py-5,'image':img_base,
                        'speedx':float(sx),'speedy':float(sy),'strength':1,'life':0})
            play_sfx(1)

        elif bs == 4:  # Charge (begin charging)
            if self.charge == 0:
                self.bulletdelay = 18
                self.chargetime  = pygame.time.get_ticks()
                self.charge      = 1
                self.chargeimage = 480
            play_sfx(2, loops=-1)

    def _release_charge(self):
        if self.charge == 0:
            return
        elapsed = min(pygame.time.get_ticks() - self.chargetime, 1500)
        damage   = elapsed // 500 + 1
        beam_img = 399 + self.beam + elapsed // 500
        self.bullets.append({'x':self.playerx+25,
            'y':self.playery - elapsed//60,
            'image':beam_img,'speedx':18.0,'speedy':0.0,
            'strength':damage,'life':100})
        if self.special >= 1:
            self.bullets.append({'x':self.playerx-30,
                'y':self.playery - elapsed//60,
                'image':beam_img,'speedx':-18.0,'speedy':0.0,
                'strength':damage,'life':100})
        stop_sfx(2)
        self.charge = 0

    def _weapon_cycle(self):
        if self.selectdelay > 0:
            return
        bs    = self.beamselect
        avail = {1:self.beam1, 2:self.beam2, 3:self.beam3, 4:self.beam4}
        for i in range(bs + 1, 5):
            if avail.get(i, 0):
                self.beamselect = i
                self.beam = i
                self.selectdelay = 15
                return
        self.beamselect = 0
        self.beam = 0
        self.selectdelay = 15

    # ── Make items ─────────────────────────────────────────────────────────
    def _make_items(self, ex, ey):
        if self.itemfrequency <= 0:
            return
        if random.randint(0, self.itemfrequency) >= 10:
            return
        roll = random.randint(0, 30)
        if   roll >= 19: img = 25
        elif roll >= 14: img = 31
        elif roll >= 11: img = 26
        elif roll >= 6:
            b = random.randint(0, 20)
            if   b < 7:  img = 27
            elif b < 14: img = 32
            elif b < 19: img = 33
            else:        img = 34
        elif roll == 5:  img = 25
        elif roll == 4:  img = 28
        elif roll == 3:  img = 29
        else:            img = 30
        self.items.append({'x': float(ex), 'y': float(ey), 'image': img})

    # ── Add regular enemies ────────────────────────────────────────────────
    def _add_enemies(self):
        if len(self.enemies) >= MAX_ENEMIES:
            return
        if self.enemydelay > 0:
            self.enemydelay -= 1
            return

        k = random.randint(0, 100)
        if self.enemyset == 1:
            etype = 1
        elif self.enemyset == 2:
            etype = 1 if k > self.frequency1 else 2
        else:
            etype = 1 if k < self.frequency1 else (2 if k <= self.frequency2 else 3)

        howm = random.randint(1, max(1, self.howmany)) if self.howmany > 0 else 1
        ey   = float(random.randint(0, self.levelheight) - 100)
        temp = 0

        for _ in range(howm):
            if etype == 1:
                si,ei,ai = self.EStartImage1, self.EEndImage1, self.EActualImage1
                at=self.Eattacktype1; bsx=self.Ebspeedx1; bsy=self.Ebspeedy1
                spx=self.EspeedX1;   spy=self.EspeedY1
                wp=self.Eweapon1;    sc=self.Eshotchance1
                arm=self.EArmor1;    pv=self.Epointvalue1
                ws=self.Eweaponstrength1; fl=self.Eflight1
            elif etype == 2:
                si,ei,ai = self.EStartImage2, self.EEndImage2, self.EActualImage2
                at=self.Eattacktype2; bsx=self.Ebspeedx2; bsy=self.Ebspeedy2
                spx=self.EspeedX2;   spy=self.EspeedY2
                wp=self.Eweapon2;    sc=self.Eshotchance2
                arm=self.EArmor2;    pv=self.Epointvalue2
                ws=self.Eweaponstrength2; fl=self.Eflight2
            else:
                si,ei,ai = self.EStartImage3, self.EEndImage3, self.EActualImage3
                at=self.Eattacktype3; bsx=self.Ebspeedx3; bsy=self.Ebspeedy3
                spx=self.EspeedX3;   spy=self.EspeedY3
                wp=self.Eweapon3;    sc=self.Eshotchance3
                arm=self.EArmor3;    pv=self.Epointvalue3
                ws=self.Eweaponstrength3; fl=self.Eflight3

            w = get_w(si); h = get_h(si)
            e = {
                'x': float(SCREEN_W + w + temp), 'y': ey,
                'width': w, 'height': h,
                'speedx': spx, 'speedy': spy,
                'start_image': si, 'end_image': ei,
                'image_delay': self.EImageDelay,
                'next_image_delay': self.ENextImageDelay,
                'actual_image': ai,
                'armor': float(arm), 'pointvalue': pv,
                'directionx': 0, 'directiony': random.randint(0, 1),
                'weapon': wp, 'weaponstrength': float(ws),
                'bspeedx': bsx, 'bspeedy': bsy,
                'shotchance': sc + 3 * (self.mode - 1),
                'attacktype': at, 'misc1': self.Emisc1,
                'deaddelay': self.Edeaddelay, 'flight': fl,
            }
            self.enemies.append(e)
            self.enemydelay = random.randint(0, self.lvldifficulty)
            print(f"[enemy] spawned type={etype} img={si}-{ei} "
                  f"x={e['x']:.0f} y={e['y']:.0f} armor={arm} nextdelay={self.enemydelay}")
            temp += w + 10

    # ── Player death ───────────────────────────────────────────────────────
    def _player_dead(self):
        self.explosions.append({'x':self.playerx,'y':self.playery,'frame':0,'delay':3})
        self.dead_flag = 1
        self.deaddelay = 100
        self.lives    -= 1
        if self.lives < 0:
            self.gameover = True
            self._save_hi()
        self.shield = 1
        if self.charge:
            stop_sfx(2)
            self.charge = 0
        self.beam0 = 1
        if self.special > 0:
            self.special -= 1
        else:
            if self.beamselect == 0:
                self.weaponselect   = max(10, self.weaponselect - 2)
                self.weaponstrength = (self.weaponselect - 10) / 2 + 1
                self.weaponspeed    = (self.weaponselect - 10) // 3 + 16
            elif self.beamselect == 1: self.beamselect=0; self.beam1=0
            elif self.beamselect == 2: self.beamselect=0; self.beam2=0
            elif self.beamselect == 3: self.beamselect=0; self.beam3=0
            elif self.beamselect == 4: self.beamselect=0; self.beam4=0; self.charge=0
        self.beam         = self.beamselect
        self.playerimage  = self.shield
        self.playerspeedx = 3; self.playerspeedy = 3
        if self.lvl == 6:
            self.playerspeedx = 6; self.playerspeedy = 6
        self.playery = GAME_H // 2

    # ── Collect item ───────────────────────────────────────────────────────
    def _collect_item(self, img):
        if img == 25:   self.score += 500
        elif img == 26:
            self.score += 50; self.weaponselect = min(15, self.weaponselect + 1)
            if self.weaponselect < 15:
                self.weaponstrength = (self.weaponselect-10)/2+1
                self.weaponspeed    = (self.weaponselect-10)//3+16
        elif img == 27: self.score+=150; self.beam1=1
        elif img == 32: self.score+=150; self.beam2=1
        elif img == 33: self.score+=150; self.beam4=1
        elif img == 34: self.score+=150; self.beam3=1
        elif img == 28: self.score+=150; self.lives+=1
        elif img == 29:
            self.score+=200; self.special = min(2, self.special+1); play_sfx(7)
        elif img == 30:
            self.score+=150; self.shield = min(3, self.shield+1); play_sfx(6)
            self.playerimage = self.shield
        elif img == 31:
            self.score+=50
            self.playerspeedx = min(7, self.playerspeedx+1)
            self.playerspeedy = min(7, self.playerspeedy+1)

    # ── Draw background ────────────────────────────────────────────────────
    def _draw_background(self):
        bg = spr.get(self.backgroundmap)
        if bg is None:
            self.screen.fill((5, 5, 20))
            return
        bw, bh = bg.get_width(), bg.get_height()
        if bw == 0 or bh == 0:
            self.screen.fill((5, 5, 20)); return
        sx = int(self.scrollx) % bw
        sy = int(self.scrolly) % bh
        x = -(bw - sx)
        while x < SCREEN_W + bw:
            y = -(bh - sy)
            while y < GAME_H + bh:
                self.screen.blit(bg, (x, y))
                y += bh
            x += bw
        self.scrolly += self.backgroundspeedy
        if self.scrolly < -bh: self.scrolly = 0.0
        self.scrollx += self.backgroundspeedx
        if self.scrollx < -bw: self.scrollx = 0.0

    # ── HUD ────────────────────────────────────────────────────────────────
    def _draw_hud(self):
        sc = self.screen
        pygame.draw.rect(sc, (18, 18, 38), (0, GAME_H, SCREEN_W, 100))
        pygame.draw.line(sc, (60, 60, 140), (0, GAME_H), (SCREEN_W, GAME_H), 2)

        R = 20  # row height — gives a couple pixels of breathing room between lines

        # Left column: score / level / lives / power
        bitmap_text(sc, f"HI {self.hiscore}",            10, 502)
        bitmap_text(sc, f"SCORE {self.score}",           10, 502 + R)
        bitmap_text(sc, f"LEVEL {self.lvl}",             10, 502 + R*2)
        bitmap_text(sc, f"LIVES {max(0, self.lives)}",   10, 502 + R*3)
        bitmap_text(sc, f"PWR {self.weaponselect - 10}", 10, 502 + R*4)

        # Centre column: all available weapons at fixed x; cursor moves to active row
        wnames = [("PHAZOR",0),("HOMING",1),("PLASMA",2),("VULCAN",3),("CHARGE",4)]
        beam_avail = [self.beam0, self.beam1, self.beam2, self.beam3, self.beam4]
        for name, idx in wnames:
            if beam_avail[idx]:
                wy = 502 + idx * R
                bitmap_text(sc, name, 252, wy)
                if idx == self.beamselect:
                    pygame.draw.polygon(sc, (0, 255, 160),
                                        [(236, wy+4), (236, wy+11), (242, wy+7)])

        # Right column: mode / hit% / speed
        mode_n = {1:"EASY", 2:"NORMAL", 3:"HARD", 4:"SUMH"}
        bitmap_text(sc, f"MODE {mode_n.get(self.mode, '?')}", 450, 502)
        total = self.hit + self.miss
        pct   = int(self.hit / total * 100) if total else 0
        bitmap_text(sc, f"HIT {pct}",              450, 502 + R)
        bitmap_text(sc, f"SPD {self.playerspeedx}", 450, 502 + R*2)

        # Shield pips (coloured rects)
        for i in range(1, 4):
            col = (0, 200, 255) if i <= self.shield else (40, 40, 70)
            pygame.draw.rect(sc, col, (600 + i * 28, 548, 22, 30))

        if self.levelx < -self.levellength + 1600 and \
           self.levelx > -self.levellength + 800:
            bitmap_text(sc, "BOSS INCOMING", 270, 15)


    # ── Update: enemies ────────────────────────────────────────────────────
    def _update_enemies(self):
        adj    = self.adjusty
        prect  = self._player_rect()
        to_del = []

        for e in self.enemies:
            img = e['actual_image']
            blit_s(self.screen, img, e['x'], e['y'])

            fl = e['flight']
            if fl == 1:
                if e['directiony'] == 1: e['y'] += e['speedy'] + adj
                else:                    e['y'] -= e['speedy'] - adj
                if e['directionx'] == 1: e['x'] += e['speedx']
                else:                    e['x'] -= e['speedx']
                # Bounce Y — terrain or boundary
                lvl_s = spr.get(self.levelimage_num)
                if e['directiony'] == 1:
                    if (e['y'] >= self.levelheight + self.levely - e['height'] or
                            (lvl_s and self._terrain_pixel(lvl_s, e['x'], e['y'] + 8))):
                        e['directiony'] = 0
                else:
                    if (e['y'] < self.levely or
                            (lvl_s and self._terrain_pixel(lvl_s, e['x'], e['y'] - 5))):
                        e['directiony'] = 1
                # Bounce X — terrain (non-boss only) or boss screen bounds
                if self.boss == 1:
                    if e['x'] > SCREEN_W - e['width']: e['directionx'] = 0
                    if e['x'] < 50:                     e['directionx'] = 1
                elif lvl_s:
                    if e['directionx'] == 1 and self._terrain_pixel(lvl_s, e['x'] + 8, e['y']):
                        e['directionx'] = 0
                    elif e['directionx'] == 0 and self._terrain_pixel(lvl_s, e['x'] - 5, e['y']):
                        e['directionx'] = 1

            elif fl == 2:  # swoop
                dx = self.playerx - e['x']; dy = self.playery - e['y']
                dist = math.sqrt(dx*dx + dy*dy) or 1
                vx = dx/dist + dx/14; vy = dy/dist + dy/14
                vx = max(-e['speedx']*3, min(e['speedx']*3, vx))
                vy = max(-e['speedy']*3, min(e['speedy']*3, vy))
                if abs(dx) > 30 or abs(dy) > 30:
                    e['x'] += vx; e['y'] += vy + adj
                else:
                    e['flight'] = 1

            # Animate sprite
            if e['next_image_delay'] <= 0:
                e['actual_image'] += 1
                if e['actual_image'] > e['end_image']:
                    e['actual_image'] = e['start_image']
                e['next_image_delay'] = e['image_delay']
            else:
                e['next_image_delay'] -= 1

            # Enemy shoots
            if random.randint(0, 1000) < e['shotchance'] and len(self.ebullets) < MAX_BULLETS:
                at = e['attacktype']
                if at == 0:
                    self.ebullets.append({'x':e['x'],'y':e['y']+32,
                        'image':e['weapon'],
                        'speedx':float(e['bspeedx']),'speedy':float(e['bspeedy']),
                        'strength':e['weaponstrength'],'life':e['misc1']})
                elif at == 1:
                    dx=self.playerx-e['x']; dy=self.playery-e['y']
                    dist=math.sqrt(dx*dx+dy*dy) or 1
                    bsx=max(1,abs(e['bspeedx'])); bsy=max(1,abs(e['bspeedy']))
                    vx=dx/dist+dx/bsx; vy=dy/dist+dy/bsy
                    self.ebullets.append({'x':e['x'],'y':e['y'],
                        'image':e['weapon'],'speedx':vx,'speedy':vy,
                        'strength':e['weaponstrength'],'life':e['misc1']})
                elif at == 2:
                    for _ in range(random.randint(0, self.mode*2)+1):
                        self.ebullets.append({'x':e['x'],'y':e['y'],
                            'image':e['weapon'],
                            'speedx':float(e['bspeedx'])-random.randint(0,5),
                            'speedy':float(e['bspeedy'])+random.randint(0,abs(e['bspeedy'])+2),
                            'strength':e['weaponstrength'],'life':e['misc1']})
                        self.ebullets.append({'x':e['x'],'y':e['y'],
                            'image':e['weapon'],
                            'speedx':float(e['bspeedx'])-random.randint(0,5),
                            'speedy':-float(e['bspeedy'])-random.randint(0,abs(e['bspeedy'])+2),
                            'strength':e['weaponstrength'],'life':e['misc1']})

            # Bullet → enemy collision
            if self.deaddelay == 0 and e['deaddelay'] < 1:
                erect = self._enemy_rect(e)
                for b in list(self.bullets):
                    if erect.colliderect(self._bullet_rect(b)) and e['x'] < SCREEN_W - 10:
                        self.hit += 1
                        play_sfx(8)
                        e['armor'] -= b['strength']
                        if self.boss == 0:
                            e['deaddelay'] = 20
                        if b['image'] < 403 or self.boss == 1:
                            if b in self.bullets:
                                self.bullets.remove(b)
                        break

                # Enemy → player collision
                if self._enemy_rect(e).colliderect(prect):
                    self.shield -= 1
                    if self.shield < 1:
                        self._player_dead()
                    else:
                        play_sfx(5)
            elif e['deaddelay'] > 0:
                e['deaddelay'] -= 1

            # Enemy destroyed
            if e['armor'] <= 0:
                self.score     += e['pointvalue']
                self.enemykill += 1
                self._make_items(e['x'], e['y'])
                if e['misc1'] == 1:
                    for _ in range(30):
                        self.explosions.append({
                            'x': e['x']-50+random.randint(0,100),
                            'y': e['y']-50+random.randint(0,100),
                            'frame':0, 'delay':3})
                    to_del.append(e)
                    remaining = [en for en in self.enemies if en not in to_del]
                    if not remaining:
                        self.enemykill  += 1
                        self.levelx      = -500000.0
                        self.levellength = 0
                        self.lvlup       = 1
                        self.bossexplosion = 1
                else:
                    self.explosions.append({
                        'x': e['x']-50+random.randint(0,100),
                        'y': e['y']-50+random.randint(0,100),
                        'frame':0,'delay':3})
                    to_del.append(e)
            elif e['x'] < -e['width'] or e['x'] > 1050:
                if self.boss == 0:
                    to_del.append(e)

        for e in to_del:
            if e in self.enemies:
                self.enemies.remove(e)

    # ── Update: player bullets ─────────────────────────────────────────────
    def _update_bullets(self):
        to_del = []
        for b in self.bullets:
            b['x'] += b['speedx']
            b['y'] += b['speedy'] + self.adjusty
            blit_s(self.screen, b['image'], b['x'], b['y'])
            if (b['x'] < -100 or b['x'] > SCREEN_W + 60 or
                b['y'] < self.levely - 60 or
                b['y'] > self.levelheight + self.levely - self.playerheight):
                self.miss += 1
                to_del.append(b)
        for b in to_del:
            if b in self.bullets: self.bullets.remove(b)

    # ── Update: enemy bullets ──────────────────────────────────────────────
    def _update_ebullets(self):
        prect  = self._player_rect()
        to_del = []
        for b in self.ebullets:
            b['x'] += b['speedx']
            b['y'] += b['speedy'] + self.adjusty
            blit_s(self.screen, b['image'], b['x'], b['y'])
            if (b['x'] < -20 or b['x'] > SCREEN_W or
                b['y'] < self.levely or
                b['y'] > self.levelheight + self.levely - self.playerheight):
                to_del.append(b)
            elif self.deaddelay == 0 and self._bullet_rect(b).colliderect(prect):
                self.shield -= b['strength']
                if self.shield < 1:
                    self._player_dead()
                to_del.append(b)
        for b in to_del:
            if b in self.ebullets: self.ebullets.remove(b)

    # ── Update: items ──────────────────────────────────────────────────────
    def _update_items(self):
        prect  = self._player_rect()
        to_del = []
        for it in self.items:
            it['x'] += self.levelspeed
            it['y'] += self.adjusty
            blit_s(self.screen, it['image'], it['x'], it['y'])
            irect = pygame.Rect(it['x'], it['y'],
                                get_w(it['image']), get_h(it['image']))
            if irect.colliderect(prect):
                self._collect_item(it['image'])
                to_del.append(it)
            elif it['x'] < -50:
                to_del.append(it)
        for it in to_del:
            if it in self.items: self.items.remove(it)

    # ── Update: explosions ─────────────────────────────────────────────────
    def _update_explosions(self):
        to_del = []
        for ex in self.explosions:
            img = 16 + ex['frame']
            blit_s(self.screen, img, ex['x'], ex['y'])
            if ex['delay'] <= 0:
                if ex['frame'] == 0: play_sfx(5)
                ex['frame'] += 1
                ex['delay']  = 3
                if ex['frame'] >= 8:
                    to_del.append(ex)
                    self.bossexplosion = 0
            else:
                ex['delay'] -= 1
        for ex in to_del:
            if ex in self.explosions: self.explosions.remove(ex)

    # ── Update: player movement & draw ────────────────────────────────────
    def _update_player(self, keys):
        self.adjusty = 0
        pimg = self.shield  # default = normal ship variant matching shield

        if keys[pygame.K_a]:
            self.playerx -= abs(self.levelspeed) + self.playerspeedx
            self.playerx = max(0, self.playerx)

        if keys[pygame.K_d]:
            pimg = self.shield + 39
            self.playerx += self.playerspeedx
            if self.playerx > SCREEN_W - self.playerwidth:
                self.playerx = float(SCREEN_W - self.playerwidth)

        if keys[pygame.K_w]:
            pimg = self.shield + 6
            if self.playery < 250 and self.levely < 0:
                self.levely  += self.playerspeedy
                self.adjusty  = self.playerspeedy
                if self.levely > 0: self.levely = 0.0
            else:
                self.playery -= self.playerspeedy
        if self.playery < 0: self.playery = 0.0

        if keys[pygame.K_s]:
            pimg = self.shield + 3
            if self.playery > 250 and -self.levely < self.levelheight - GAME_H:
                self.levely  -= self.playerspeedy
                self.adjusty  = -self.playerspeedy
                if -self.levely > self.levelheight - GAME_H:
                    self.levely = -(self.levelheight - GAME_H)
            else:
                self.playery += self.playerspeedy
        if self.playery > GAME_H - self.playerheight:
            self.playery = float(GAME_H - self.playerheight)

        self.playerimage  = pimg
        self.playerwidth  = get_w(pimg)
        self.playerheight = get_h(pimg)

        # Terrain hit
        if self.deaddelay == 0 and self._terrain_hit(self.playerx, self.playery):
            self._player_dead()

        # Draw player (flash when recently dead)
        if self.dead_flag:
            self.dead_flag = 0
            return
        self.flash = 1 - self.flash
        if self.deaddelay > 0:
            self.deaddelay -= 1
            if self.flash == 1 and self.deaddelay < 300:
                blit_s(self.screen, self.playerimage, self.playerx, self.playery)
        else:
            blit_s(self.screen, self.playerimage, self.playerx, self.playery)

        # Charge visual
        if self.charge == 1:
            blit_s(self.screen, self.chargeimage, self.playerx+8, self.playery-5)

    # ── Main loop ──────────────────────────────────────────────────────────
    def run(self):
        self._title_screen()
        if not self.running:
            return

        self._reset_game()
        self._advance_level()   # lvl=0,boss=1 → increments to lvl=1,boss=0 → setup level 1

        charge_held = False

        while self.running:
            self.clock.tick(FPS)

            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    self._save_hi(); self.running = False; return

                if ev.type == pygame.KEYDOWN:
                    if ev.key == pygame.K_ESCAPE:
                        self._save_hi(); self.running = False; return

                    if ev.key == pygame.K_SPACE:
                        self.paused = not self.paused

                    if ev.key == pygame.K_F12 or ev.key == pygame.K_p:
                        import datetime
                        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                        fname = f"screenshot_{ts}.png"
                        pygame.image.save(self.screen, fname)
                        print(f"[vulcan] screenshot saved: {fname}")

                    if not self.paused:
                        if ev.key == pygame.K_k and self.charge == 0:
                            self._weapon_cycle()

                        if ev.key == pygame.K_l:
                            if self.selectdelay <= 0:
                                self.playerspeedx = max(3, self.playerspeedx - 1)
                                self.playerspeedy = max(3, self.playerspeedy - 1)
                                self.selectdelay  = 15

                        # Debug: advance one level/boss stage
                        if ev.key == pygame.K_TAB and self.skipdelay <= 0:
                            self.lvlup  = 1
                            self.levelx = -100000000.0
                            self.skipdelay = 90
                            self._delete_enemies()

                if ev.type == pygame.KEYUP:
                    if ev.key == pygame.K_j and self.charge == 1:
                        self._release_charge()
                        charge_held = False

            # ── Paused ──────────────────────────────────────────────────
            if self.paused:
                self.screen.fill((0, 0, 0))
                bitmap_text(self.screen, "PAUSED",          310, 265)
                bitmap_text(self.screen, "SPACE TO RESUME", 220, 300)
                pygame.display.flip()
                continue

            keys = pygame.key.get_pressed()

            # Shoot / charge
            if self.deaddelay == 0 and self.bulletdelay == 0:
                if keys[pygame.K_j]:
                    if self.beamselect == 4:
                        if not charge_held:
                            self._shoot()
                            charge_held = True
                    else:
                        self._shoot()
                else:
                    charge_held = False

            # Charge animation tick
            if self.charge == 1:
                self.chargeimage += 1
                if self.chargeimage > 482:
                    self.chargeimage = 480

            if self.selectdelay > 0: self.selectdelay -= 1
            if self.bulletdelay > 0: self.bulletdelay -= 1
            if self.skipdelay   > 0: self.skipdelay   -= 1

            # ── Draw ────────────────────────────────────────────────────
            self._draw_background()
            self._update_enemies()
            self._update_bullets()
            self._update_ebullets()
            self._update_items()
            self._update_player(keys)
            self._update_explosions()

            # Level image overlay
            lvl_s = spr.get(self.levelimage_num)
            if lvl_s:
                self.screen.blit(lvl_s, (int(self.levelx), int(self.levely)))

            self.levelx += self.levelspeed

            # Level progression
            if not self.bossexplosion:
                if (self.levelx < -self.levellength + SCREEN_W and self.boss == 0):
                    self._advance_level()
                elif (self.levelx < -self.levellength - SCREEN_W and self.lvlup == 1):
                    self.lvlup = 0
                    self._advance_level()

            if self.boss == 0:
                self._add_enemies()

            self._draw_hud()

            # Game over handling
            if self.gameover:
                bitmap_text(self.screen, "GAME OVER",          290, 230)
                bitmap_text(self.screen, "PRESS SPACE TO RETRY", 200, 270)
                pygame.display.flip()
                # Wait for space or escape
                waiting = True
                while waiting:
                    for ev in pygame.event.get():
                        if ev.type == pygame.QUIT:
                            self._save_hi(); self.running = False; return
                        if ev.type == pygame.KEYDOWN:
                            if ev.key == pygame.K_ESCAPE:
                                self._save_hi(); self.running = False; return
                            if ev.key == pygame.K_SPACE:
                                waiting = False
                self.gameover = False
                self._reset_game()
                self._title_screen()
                if not self.running: return
                self._reset_game()
                self._advance_level()
                charge_held = False
                continue

            pygame.display.flip()

        self._save_hi()


# ── Entry point ────────────────────────────────────────────────────────────
def main():
    pygame.init()
    try:
        pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)
        print("[vulcan] Audio: mixer initialised OK")
    except Exception as e:
        print(f"[vulcan] Audio: mixer unavailable ({e})")
        print("[vulcan]        pygame.mixer is broken on Python 3.14 with pygame 2.6.1")
        print("[vulcan]        For sound, use Python 3.12:  pyenv install 3.12 && pyenv local 3.12")

    screen = pygame.display.set_mode((SCREEN_W, SCREEN_H))
    pygame.display.set_caption("Vulcan I")

    # Show loading screen
    screen.fill((0, 0, 0))
    pygame.draw.rect(screen, (200, 200, 200), (340, 288, 120, 24))
    pygame.display.flip()

    load_all_assets()

    game = Game(screen)
    game.run()
    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    main()
