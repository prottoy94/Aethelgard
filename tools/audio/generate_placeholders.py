"""Generates the placeholder sounds (AUDIO_DESIGN.md §7.1) and their SoundEvent resources.

Every sound is built from simple recipes (whoosh, chime, impact, crackle, rustle, click...) with numpy, saved as WAV
with its final name under assets/audio/placeholders/, and gets a SoundEvent .tres in assets/audio/sound_events/ plus
an entry in assets/audio/sound_library.tres. Ambience loops and the placeholder combat layer get MusicTrack .tres
files in data/audio/music/; data/audio/music_library.tres lists every MusicTrack there (also the owner's music).
Audio files are git-ignored, so run this after a fresh clone:
    python tools/audio/generate_placeholders.py
Deterministic (fixed seed). Python 3 + numpy only.
"""
import os
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SR = 44100
AMB_SR = 22050
rng = np.random.default_rng(1234)

# F# major (the key of the owner's song) for musical placeholders
F_SHARP = 369.99
SCALE = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16]  # major scale steps


def note(step, base=F_SHARP):
    octave, idx = divmod(step, 7)
    return base * 2 ** ((SCALE[idx] + 12 * octave) / 12)


# --- Building blocks --------------------------------------------------------------------------

def t(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=0.005, release=0.1, sr=SR, curve=4.0):
    a = max(int(attack * sr), 1)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    tail = np.linspace(0, 1, n - a)
    e[a:] = np.exp(-curve * tail * (n - a) / (release * sr + 1e-9) / 4)
    return e


def decay(dur, rate, sr=SR):
    x = t(dur, sr)
    e = np.exp(-rate * x)
    a = min(int(0.003 * sr), len(e))
    e[:a] *= np.linspace(0, 1, a)
    return e


def band(signal, lo, hi, sr=SR):
    spec = np.fft.rfft(signal)
    f = np.fft.rfftfreq(len(signal), 1 / sr)
    mask = ((f >= lo) & (f <= hi)).astype(float)
    # soft edges
    mask = np.convolve(mask, np.hanning(31) / np.hanning(31).sum(), mode="same")
    return np.fft.irfft(spec * mask, len(signal))


def noise(dur, sr=SR):
    return rng.standard_normal(int(dur * sr))


def sweep(f0, f1, dur, sr=SR, shape="exp"):
    x = t(dur, sr)
    if shape == "exp":
        f = f0 * (f1 / f0) ** (x / dur)
    else:
        f = f0 + (f1 - f0) * x / dur
    return np.sin(2 * np.pi * np.cumsum(f) / sr)


def chime(freq, dur, rate=6.0, partials=(1, 2.76, 5.4), sr=SR):
    x = t(dur, sr)
    out = np.zeros_like(x)
    for i, p in enumerate(partials):
        out += np.sin(2 * np.pi * freq * p * x) * (0.6 ** i) * np.exp(-rate * (1 + i * 0.6) * x)
    a = int(0.002 * sr)
    out[:a] *= np.linspace(0, 1, a)
    return out


def tone(freq, dur, rate=4.0, sr=SR):
    x = t(dur, sr)
    return np.sin(2 * np.pi * freq * x) * decay(dur, rate, sr)


def whoosh(dur, lo=300, hi=3000, sr=SR):
    n = noise(dur, sr)
    low = band(n, lo * 0.5, lo * 2, sr)
    high = band(n, hi * 0.5, hi * 1.5, sr)
    x = t(dur, sr) / dur
    shape = np.sin(np.pi * x) ** 1.5
    return (low * (1 - x) + high * x) * shape


def impact(dur=0.25, freq=120, bright=2500, sr=SR):
    body = sweep(freq * 1.6, freq * 0.6, dur, sr) * decay(dur, 18, sr)
    crack = band(noise(dur, sr), 400, bright, sr) * decay(dur, 45, sr)
    return body + crack * 0.8


def crackle(dur, density=60, sr=SR):
    out = np.zeros(int(dur * sr))
    for _ in range(int(density * dur)):
        pos = rng.integers(0, len(out) - 200)
        length = rng.integers(20, 180)
        out[pos:pos + length] += rng.standard_normal(length) * np.exp(-np.arange(length) / (length / 4)) * rng.uniform(0.3, 1)
    return band(out, 600, 9000, sr)


def rustle(dur, sr=SR):
    n = band(noise(dur, sr), 1500, 7000, sr)
    grain = np.abs(band(noise(dur, sr), 5, 40, sr))
    return n * (grain / (grain.max() + 1e-9))


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def seq(parts, gap, sr=SR):
    """Plays parts one after another, each starting `gap` seconds after the previous one."""
    step = int(gap * sr)
    n = step * (len(parts) - 1) + max(len(p) for p in parts)
    out = np.zeros(n)
    for i, p in enumerate(parts):
        out[i * step:i * step + len(p)] += p
    return out


def normalize(signal, peak_db=-3.0):
    peak = np.max(np.abs(signal)) + 1e-9
    return signal / peak * (10 ** (peak_db / 20))


def fade_edges(signal, sr=SR, fade=0.005):
    n = min(int(fade * sr), len(signal) // 2)
    signal[:n] *= np.linspace(0, 1, n)
    signal[-n:] *= np.linspace(1, 0, n)
    return signal


def loopable(signal, crossfade, sr):
    """Crossfades the extra tail into the head, so the loop seams quietly."""
    f = int(crossfade * sr)
    body = signal[:-f].copy()
    body[:f] = body[:f] * np.linspace(0, 1, f) + signal[-f:] * np.linspace(1, 0, f)
    return body


def write_wav(path, signal, sr=SR, stereo=False, peak_db=-3.0, edges=True):
    signal = normalize(signal.astype(float), peak_db)
    if edges:
        signal = fade_edges(signal, sr)
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    data = np.clip(signal, -1, 1)
    if stereo:
        width = np.roll(data, int(0.0007 * sr)) * 0.92  # a touch of width
        data = np.column_stack([data, width]).ravel()
    pcm = (data * 32767).astype("<i2")
    with wave.open(full, "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


# --- Recipes ------------------------------------------------------------------------------------

def footstep_grass():
    return mix(rustle(0.14) * decay(0.14, 28), band(noise(0.1), 80, 400) * decay(0.1, 40) * 0.6)


def footstep_stone():
    return mix(impact(0.12, freq=rng.uniform(170, 220), bright=4000) * 0.7, band(noise(0.06), 2000, 6000) * decay(0.06, 70) * 0.4)


def staff_swing():
    return whoosh(rng.uniform(0.18, 0.24), 400, 2200)


def staff_hit():
    return impact(0.22, freq=rng.uniform(140, 170), bright=3000)


def hit_light():
    return mix(impact(0.2, 160, 3000) * 0.6, chime(note(7, F_SHARP * 2), 0.5, 9) * 0.7)


def hit_wind():
    return mix(whoosh(0.25, 500, 3500), impact(0.15, 130) * 0.5)


def hit_ember():
    return mix(crackle(0.35, 80), impact(0.25, 90, 1800) * 0.8, sweep(220, 70, 0.3) * decay(0.3, 9) * 0.3)


def hit_none():
    return impact(0.2, 130, 2200)


def chirp(f0=1400, f1=2300, dur=0.16, wobble=18.0):
    """A small, bright dragon chirp: a quick rising whistle with a flutter."""
    n = int(dur * SR)
    freq = np.linspace(f0, f1, n) * (1 + 0.04 * np.sin(2 * np.pi * wobble * t(dur)))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return (np.sin(phase) + 0.25 * np.sin(2 * phase)) * env(n, 0.01, dur * 0.6)


def breath(dur, lo, hi, texture=None):
    """A puff of breath: filtered noise swelling and fading, with an optional texture on top."""
    n = int(dur * SR)
    body = band(noise(dur), lo, hi) * env(n, 0.06, dur * 0.7)
    return mix(body, texture[:n] * 0.6) if texture is not None else body


def telegraph(dur, f0, f1, texture):
    rise = sweep(f0, f1, dur) * np.linspace(0.2, 1, int(dur * SR)) ** 1.5
    return mix(rise * 0.6, texture[:int(dur * SR)] * np.linspace(0.3, 1, len(texture[:int(dur * SR)])))


SOUNDS = {
    # id: (category for folders, recipe(s) → list of variants, options)
    "player_footstep_grass": ("player", [footstep_grass for _ in range(4)], dict(volume=-10, poly=2, pitch=(0.9, 1.1))),
    "player_footstep_stone": ("player", [footstep_stone for _ in range(4)], dict(volume=-9, poly=2, pitch=(0.9, 1.1))),
    "player_dash": ("player", [lambda: mix(whoosh(0.35, 300, 4000), chime(note(9, F_SHARP * 2), 0.4, 10) * 0.25)], {}),
    "player_staff_swing": ("player", [staff_swing for _ in range(3)], dict(volume=-4)),
    "player_staff_hit": ("player", [staff_hit for _ in range(3)], {}),
    "player_hurt": ("player", [lambda: mix(impact(0.3, 100, 1500), rustle(0.25) * 0.4)], dict(volume=-2)),
    "player_defeated": ("player", [lambda: mix(sweep(300, 90, 1.2) * decay(1.2, 2.5) * 0.6, chime(note(4), 1.5, 2.5) * 0.4)], dict(poly=1)),
    "player_cast_fail": ("player", [lambda: mix(band(noise(0.3), 300, 1500) * decay(0.3, 12), sweep(180, 90, 0.3) * decay(0.3, 8) * 0.4)], dict(poly=1, interval=0.15)),
    "player_stamina_ready": ("player", [lambda: seq([chime(note(4), 0.5, 7), chime(note(7), 0.6, 6)], 0.09)], dict(volume=-8, poly=1, positional=False)),
    "player_heal": ("player", [lambda: seq([chime(note(i), 0.7, 5) for i in (0, 2, 4, 7)], 0.08)], dict(volume=-4, poly=1)),
    "spell_light_mote_cast": ("spells", [lambda: mix(chime(note(7, F_SHARP * 2), 0.5, 7), band(noise(0.3), 5000, 12000) * decay(0.3, 12) * 0.25)], dict(volume=-4)),
    "spell_light_mote_impact": ("spells", [lambda: mix(chime(note(9, F_SHARP * 2), 0.4, 12), band(noise(0.2), 3000, 11000) * decay(0.2, 25) * 0.5)], {}),
    "spell_lantern_glow_cast": ("spells", [lambda: mix(*[np.sin(2 * np.pi * note(s) * t(1.4)) * env(int(1.4 * SR), 0.35, 1.0) * 0.4 for s in (0, 2, 4)], band(noise(1.4), 4000, 10000) * env(int(1.4 * SR), 0.3, 1.0) * 0.1)], dict(poly=1)),
    "spell_gust_cast": ("spells", [lambda: whoosh(0.6, 250, 3500)], dict(volume=-1)),
    "spell_mending_bloom_cast": ("spells", [lambda: seq([chime(note(i, F_SHARP / 2), 1.0, 3, (1, 2, 3)) for i in (0, 2, 4, 7, 9)], 0.11)], dict(poly=1)),
    "combat_hit_none": ("combat", [hit_none for _ in range(3)], {}),
    "combat_hit_light": ("combat", [hit_light for _ in range(3)], {}),
    "combat_hit_wind": ("combat", [hit_wind for _ in range(3)], {}),
    "combat_hit_ember": ("combat", [hit_ember for _ in range(3)], {}),
    "combat_hit_earth": ("combat", [lambda: impact(0.3, 80, 1200) for _ in range(2)], {}),
    "combat_hit_frost": ("combat", [lambda: mix(impact(0.18, 260, 9000) * 0.6, chime(2800, 0.35, 12, (1, 2.4)) * 0.4) for _ in range(2)], {}),
    "combat_weak_hit": ("combat", [lambda: chime(1760, 0.35, 12, (1, 2.0))], dict(volume=-6, poly=2)),
    "combat_resisted": ("combat", [lambda: band(impact(0.2, 90, 600), 40, 800)], dict(volume=-4, poly=2)),
    "combat_status_burn": ("combat", [lambda: crackle(0.6, 90) * env(int(0.6 * SR), 0.02, 0.4)], dict(volume=-6, poly=2, interval=0.2)),
    "combat_status_chill": ("combat", [lambda: mix(band(noise(0.5), 5000, 12000) * env(int(0.5 * SR), 0.05, 0.3), chime(2600, 0.4, 10) * 0.3)], dict(volume=-6, poly=2, interval=0.2)),
    "combat_status_freeze": ("combat", [lambda: mix(crackle(0.2, 200), chime(3100, 0.6, 6, (1, 2.4)) * 0.5)], dict(poly=2, interval=0.2)),
    "combat_status_daze": ("combat", [lambda: np.sin(2 * np.pi * (880 + 60 * np.sin(2 * np.pi * 7 * t(0.6))) * t(0.6)) * decay(0.6, 5) * 0.6], dict(volume=-8, poly=2, interval=0.2)),
    "combat_status_ember_mark": ("combat", [lambda: mix(sweep(160, 60, 0.5) * decay(0.5, 5), crackle(0.5, 40) * 0.5)], dict(volume=-4, poly=2, interval=0.2)),
    "combat_loot_drop": ("combat", [lambda: seq([chime(note(i, F_SHARP * 2), 0.25, 14) for i in (4, 7)], 0.05)], dict(volume=-8, poly=3)),
    "combat_loot_pickup": ("combat", [lambda: seq([chime(note(i, F_SHARP * 2), 0.3, 12) for i in (7, 9)], 0.06)], dict(volume=-6, poly=3)),
    "enemy_thornling_alert": ("enemies", [lambda: mix(rustle(0.4), sweep(110, 90, 0.4) * decay(0.4, 4) * 0.5)], dict(poly=2, interval=0.5)),
    "enemy_thornling_telegraph": ("enemies", [lambda: telegraph(0.8, 140, 520, rustle(0.8))], dict(volume=1, poly=2)),
    "enemy_thornling_attack": ("enemies", [lambda: whoosh(0.35, 300, 2800)], dict(poly=2)),
    "enemy_thornling_hurt": ("enemies", [lambda: mix(rustle(0.2) * 1.2, impact(0.15, 150) * 0.5)], dict(poly=3)),
    "enemy_thornling_death": ("enemies", [lambda: mix(rustle(0.6) * decay(0.6, 4), sweep(220, 60, 0.6) * decay(0.6, 4) * 0.5)], dict(poly=2)),
    "enemy_ember_wisp_alert": ("enemies", [lambda: mix(crackle(0.4, 120), sweep(300, 500, 0.4) * decay(0.4, 6) * 0.3)], dict(poly=2, interval=0.5)),
    "enemy_ember_wisp_telegraph": ("enemies", [lambda: telegraph(1.0, 120, 640, crackle(1.0, 90))], dict(volume=1, poly=2)),
    "enemy_ember_wisp_attack": ("enemies", [lambda: mix(band(noise(0.4), 100, 1500) * decay(0.4, 9), crackle(0.4, 80) * 0.6)], dict(poly=3)),
    "enemy_ember_wisp_hurt": ("enemies", [lambda: mix(crackle(0.25, 150), band(noise(0.25), 3000, 9000) * decay(0.25, 15) * 0.4)], dict(poly=3)),
    "enemy_ember_wisp_death": ("enemies", [lambda: mix(band(noise(0.8), 2000, 9000) * decay(0.8, 4) * 0.6, impact(0.2, 200) * 0.6)], dict(poly=2)),
    "world_chest_open": ("world", [lambda: mix(sweep(90, 140, 0.45) * env(int(0.45 * SR), 0.05, 0.3) * 0.5, seq([chime(note(i, F_SHARP * 2), 0.6, 6) for i in (0, 4, 7)], 0.1)[:int(0.9 * SR)])], dict(poly=1)),
    "world_gather_herb": ("world", [lambda: rustle(0.35) * decay(0.35, 6) for _ in range(2)], dict(poly=2)),
    "world_gather_ore": ("world", [lambda: seq([impact(0.12, 300, 6000) for _ in range(2)], 0.16) for _ in range(2)], dict(poly=2)),
    "world_gather_wood": ("world", [lambda: seq([impact(0.15, 180, 2500), impact(0.15, 160, 2500)], 0.18)], dict(poly=2)),
    "world_gather_crystal": ("world", [lambda: chime(2400, 0.6, 7, (1, 2.4, 3.9))], dict(poly=2)),
    "world_rest_point_activate": ("world", [lambda: mix(whoosh(0.8, 200, 1500) * 0.4, *[chime(note(s), 1.6, 2.2) * 0.5 for s in (0, 2, 4)])], dict(poly=1, positional=False)),
    "world_region_transition": ("world", [lambda: whoosh(0.7, 150, 1200)], dict(volume=-6, poly=1, positional=False)),
    "puzzle_brazier_ignite": ("puzzles", [lambda: mix(band(noise(0.5), 80, 1200) * env(int(0.5 * SR), 0.03, 0.3), crackle(0.8, 50) * 0.5)], dict(poly=2)),
    "puzzle_block_push": ("puzzles", [lambda: band(noise(0.45), 60, 600) * env(int(0.45 * SR), 0.05, 0.2)], dict(poly=1)),
    "puzzle_plate_press": ("puzzles", [lambda: mix(impact(0.25, 90, 1500), tone(1200, 0.2, 20) * 0.2)], dict(poly=1)),
    "puzzle_hidden_reveal": ("puzzles", [lambda: mix(band(noise(1.2), 3000, 10000) * env(int(1.2 * SR), 0.5, 0.6) * 0.4, *[chime(note(s, F_SHARP * 2), 1.2, 3) * 0.3 for s in (2, 6)])], dict(poly=1)),
    "puzzle_solved": ("puzzles", [lambda: seq([chime(note(i), 0.9, 4) for i in (0, 2, 4, 7)], 0.12)], dict(poly=1, positional=False)),
    "ui_hover": ("ui", [lambda: tone(2400, 0.03, 120)], dict(volume=-18, poly=1, interval=0.04)),
    "ui_confirm": ("ui", [lambda: seq([tone(1200, 0.06, 50), tone(1800, 0.08, 40)], 0.04)], dict(volume=-10, poly=2)),
    "ui_cancel": ("ui", [lambda: seq([tone(1200, 0.06, 50), tone(800, 0.08, 40)], 0.04)], dict(volume=-10, poly=2)),
    "ui_error": ("ui", [lambda: np.sign(np.sin(2 * np.pi * 140 * t(0.18))) * decay(0.18, 10) * 0.3], dict(volume=-12, poly=1, interval=0.1)),
    "ui_menu_open": ("ui", [lambda: whoosh(0.25, 800, 4000) * 0.6], dict(volume=-10, poly=1)),
    "ui_menu_close": ("ui", [lambda: whoosh(0.22, 4000, 800) * 0.6], dict(volume=-12, poly=1)),
    "ui_tab": ("ui", [lambda: band(noise(0.12), 1500, 6000) * decay(0.12, 30)], dict(volume=-12, poly=1)),
    "ui_page_turn": ("ui", [lambda: rustle(0.3) * env(int(0.3 * SR), 0.05, 0.2)], dict(volume=-10, poly=1)),
    "ui_dialogue_blip": ("ui", [lambda: tone(660, 0.035, 60) * 0.8], dict(volume=-18, poly=2, interval=0.03, pitch=(0.92, 1.08))),
    "ui_quest_update": ("ui", [lambda: seq([chime(note(4, F_SHARP * 2), 0.4, 8), chime(note(7, F_SHARP * 2), 0.5, 7)], 0.1)], dict(volume=-8, poly=1)),
    "ui_equip": ("ui", [lambda: mix(impact(0.12, 400, 7000) * 0.5, chime(1800, 0.3, 14) * 0.4)], dict(volume=-8, poly=1)),
    "ui_craft_success": ("ui", [lambda: seq([chime(note(i, F_SHARP * 2), 0.5, 7) for i in (0, 4, 7)], 0.07)], dict(volume=-6, poly=1)),
    "dragon_egg_pulse": ("dragon", [lambda: mix(np.sin(2 * np.pi * 110 * t(0.6)) * env(int(0.6 * SR), 0.08, 0.45) * 0.7, chime(note(4), 0.6, 5) * 0.3)], dict(poly=1)),
    "dragon_egg_crack": ("dragon", [lambda: seq([impact(0.08, 900, 9000) * 0.7 for _ in range(4)], 0.09)], dict(poly=1)),
    "dragon_hatch": ("dragon", [lambda: mix(seq([impact(0.1, 700, 8000) for _ in range(3)], 0.05), np.concatenate([np.zeros(int(0.25 * SR)), chirp(1300, 2400, 0.25)]) * 0.8)], dict(poly=1)),
    "dragon_chirp_hatchling": ("dragon", [lambda: chirp(1400, 2300), lambda: seq([chirp(1500, 2100, 0.1), chirp(1700, 2500, 0.12)], 0.11), lambda: chirp(1800, 1300, 0.18)], dict(volume=-4, poly=2, interval=0.12, pitch=(0.92, 1.1))),
    "dragon_bite": ("dragon", [lambda: mix(impact(0.1, 260, 4000) * 0.7, band(noise(0.08), 2000, 7000) * decay(0.08, 40) * 0.5) for _ in range(2)], dict(volume=-3, poly=3)),
    "dragon_hurt": ("dragon", [lambda: chirp(2200, 1200, 0.2, 30)], dict(volume=-3, poly=2, interval=0.2)),
    "dragon_ko": ("dragon", [lambda: seq([chirp(1600, 900, 0.3, 8), chirp(1100, 700, 0.4, 5)], 0.25)], dict(poly=1)),
    "dragon_return": ("dragon", [lambda: mix(whoosh(0.35, 400, 3000) * 0.5, chirp(1500, 2200, 0.15) * 0.6)], dict(volume=-4, poly=1)),
    "dragon_command_ack": ("dragon", [lambda: chirp(1600, 2400, 0.12), lambda: chirp(1700, 2600, 0.1)], dict(volume=-5, poly=1, interval=0.1)),
    "dragon_happy": ("dragon", [lambda: seq([chirp(1500, 2200, 0.1), chirp(1800, 2600, 0.1), chirp(2000, 2900, 0.14)], 0.09)], dict(volume=-4, poly=1, interval=0.2)),
    "dragon_eat": ("dragon", [lambda: mix(seq([impact(0.07, 300, 3000) * 0.6 for _ in range(3)], 0.12), np.concatenate([np.zeros(int(0.4 * SR)), chirp(1600, 2500, 0.15)]) * 0.7)], dict(poly=1)),
    "dragon_breath_frost": ("dragon", [lambda: breath(0.7, 4000, 12000, mix(band(noise(0.7), 6000, 12000) * 0.2, chime(2600, 0.7, 6) * 0.25))], dict(poly=1)),
    "dragon_breath_wind": ("dragon", [lambda: whoosh(0.6, 300, 3000)], dict(poly=1)),
    "dragon_breath_earth": ("dragon", [lambda: breath(0.6, 120, 1500, seq([impact(0.06, 400, 5000) * 0.5 for _ in range(5)], 0.07))], dict(poly=1)),
    "dragon_breath_light": ("dragon", [lambda: breath(0.7, 3000, 10000, seq([chime(note(i, F_SHARP * 2), 0.4, 8) * 0.4 for i in (0, 4, 7)], 0.08))], dict(poly=1)),
    "ui_save": ("ui", [lambda: seq([chime(note(i, F_SHARP * 2), 0.6, 6) for i in (4, 0)], 0.15)], dict(volume=-8, poly=1)),
}

# Stingers: short musical moments in F# major (AUDIO_DESIGN.md §5.3), stereo, on the Music bus.
STINGERS = {
    "stg_spell_learned": lambda: seq([chime(note(i), 1.4, 2.5, (1, 2, 3)) for i in (0, 2, 4, 7, 9)], 0.13),
    "stg_rank_up": lambda: mix(seq([chime(note(i), 1.6, 2.2, (1, 2, 3)) for i in (0, 4, 7, 9, 11)], 0.11),
                                np.concatenate([np.zeros(int(0.55 * SR)), *[np.sin(2 * np.pi * note(s, F_SHARP / 2) * t(2.0)) * env(int(2.0 * SR), 0.05, 1.6) * 0.25 for s in (0,)]])),
    "stg_quest_complete": lambda: seq([chime(note(i), 1.5, 2.2, (1, 2, 3)) for i in (4, 3, 2, 0)], 0.16),
    "stg_secret_found": lambda: seq([chime(note(i, F_SHARP * 2), 1.2, 3, (1, 2.4)) for i in (0, 3, 6, 9)], 0.14),
    "stg_item_crafted": lambda: mix(*[chime(note(i), 1.4, 3) * 0.5 for i in (0, 2, 4)]),
    "stg_dragon_hatched": lambda: mix(seq([chime(note(i, F_SHARP * 2), 1.4, 2.4, (1, 2, 3)) for i in (0, 2, 4, 7, 9, 7)], 0.12),
                                       np.concatenate([np.zeros(int(0.9 * SR)), chirp(1400, 2400, 0.25) * 0.4])),
    "stg_defeat": lambda: seq([chime(note(i, F_SHARP / 2), 1.6, 2, (1, 2)) for i in (4, 3, 1, 0)], 0.3),
}


def drum_loop(bpm=76, bars=8, sr=AMB_SR):
    """Placeholder combat layer: kick, toms and a shaker at the tempo of the owner's Elderroot music."""
    beat = 60 / bpm
    total = int(bars * 4 * beat * sr)
    out = np.zeros(total + sr)

    def hit(at, sound):
        i = int(at * sr)
        out[i:i + len(sound)] += sound

    kick = sweep(110, 45, 0.35, sr) * decay(0.35, 9, sr)
    tom = sweep(180, 120, 0.3, sr) * decay(0.3, 10, sr) * 0.6
    shaker = band(noise(0.05, sr), 4000, 10000, sr) * decay(0.05, 60, sr) * 0.25
    for b in range(bars * 4):
        at = b * beat
        if b % 2 == 0:
            hit(at, kick)
        if b % 4 == 3:
            hit(at + beat * 0.5, tom)
            hit(at + beat * 0.75, tom * 0.8)
        for k in range(2):
            hit(at + k * beat / 2, shaker * (1.0 if k == 0 else 0.6))
    return out[:total]


def ambience_day(dur=30, sr=AMB_SR):
    breeze = band(noise(dur + 3, sr), 150, 1200, sr)
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * t(dur + 3, sr) / 7.0)
    out = breeze * swell * 0.5
    for _ in range(14):  # birds
        at = rng.uniform(0, dur)
        chirps = []
        base = rng.uniform(2600, 4200)
        for k in range(rng.integers(2, 5)):
            chirps.append(sweep(base, base * rng.uniform(1.15, 1.5), 0.08, sr) * decay(0.08, 25, sr))
        call = seq(chirps, 0.11, sr) * rng.uniform(0.15, 0.35)
        i = int(at * sr)
        out[i:i + len(call)] += call[:len(out) - i]
    return loopable(out, 3, sr)


def ambience_night(dur=30, sr=AMB_SR):
    wind = band(noise(dur + 3, sr), 100, 600, sr) * 0.25
    x = t(dur + 3, sr)
    crickets = np.zeros_like(x)
    for k in range(3):
        rate = rng.uniform(14, 20)
        pulse = (np.sin(2 * np.pi * rate * x + k) > 0.6).astype(float)
        gate = (np.sin(2 * np.pi * x / rng.uniform(2.5, 4.0) + k) > -0.2).astype(float)
        crickets += np.sin(2 * np.pi * rng.uniform(4200, 5200) * x) * pulse * gate * 0.08
    return loopable(wind + band(crickets, 3000, 8000, sr), 3, sr)


def rain(dur=20, sr=AMB_SR):
    out = band(noise(dur + 3, sr), 400, 8000, sr) * 0.4
    for _ in range(int(dur * 25)):  # drops
        i = rng.integers(0, len(out) - 400)
        out[i:i + 300] += band(noise(300 / sr, sr), 2000, 9000, sr) * decay(300 / sr, 60, sr) * rng.uniform(0.1, 0.4)
    return loopable(out, 3, sr)


LOOPS = {
    # id: (file, recipe, bus, volume_db, bpm, notes)
    "mus_elderroot_combat": ("music/mus_elderroot_combat.wav", drum_loop, "Music", -4.0, 76,
                             "Placeholder combat layer: drums at 76 BPM (the tempo of the owner's Elderroot music)."),
    "amb_elderroot_day": ("ambience/amb_elderroot_day.wav", ambience_day, "Ambience", -6.0, 0,
                          "Placeholder: breeze and birds."),
    "amb_elderroot_night": ("ambience/amb_elderroot_night.wav", ambience_night, "Ambience", -6.0, 0,
                            "Placeholder: soft wind and crickets."),
    "amb_weather_rain": ("ambience/amb_weather_rain.wav", rain, "Ambience", -3.0, 0, "Placeholder: rain."),
}

BUSES = {"player": "Player", "spells": "Player", "combat": "SFX", "enemies": "Enemies", "dragon": "Dragon",
         "world": "World", "puzzles": "World", "ui": "UI"}


def sound_event_tres(sound_id, files, category, opts):
    bus = opts.get("bus", BUSES[category])
    positional = opts.get("positional", category not in ("ui",))
    pitch = opts.get("pitch", (0.95, 1.05))
    paths = ", ".join('"res://%s"' % f for f in files)
    return f'''[gd_resource type="Resource" script_class="SoundEvent" format=3]

[ext_resource type="Script" path="res://src/audio/sound_event.gd" id="1"]

; Generated by tools/audio/generate_placeholders.py (placeholder sound). Swap `files` for final sounds.
[resource]
script = ExtResource("1")
id = &"{sound_id}"
files = PackedStringArray({paths})
bus = &"{bus}"
volume_db = {float(opts.get("volume", 0.0))}
pitch_range = Vector2({pitch[0]}, {pitch[1]})
max_polyphony = {opts.get("poly", 4)}
min_interval = {float(opts.get("interval", 0.03))}
positional = {"true" if positional else "false"}
'''


def write_text(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    events = []
    for sound_id, (category, recipes, opts) in SOUNDS.items():
        files = []
        for i, recipe in enumerate(recipes, start=1):
            rel = "assets/audio/placeholders/sfx/%s/sfx_%s_%02d.wav" % (category, sound_id, i)
            write_wav(rel, recipe(), stereo=(category == "ui"))
            files.append(rel)
        write_text("assets/audio/sound_events/%s.tres" % sound_id, sound_event_tres(sound_id, files, category, opts))
        events.append(sound_id)
    for sound_id, recipe in STINGERS.items():
        rel = "assets/audio/placeholders/music/stingers/%s.wav" % sound_id
        write_wav(rel, recipe(), stereo=True, peak_db=-2.0)
        write_text("assets/audio/sound_events/%s.tres" % sound_id,
                   sound_event_tres(sound_id, [rel], "ui", dict(bus="Music", poly=1, positional=False, pitch=(1.0, 1.0))))
        events.append(sound_id)
    for track_id, (file, recipe, bus, volume, bpm, notes) in LOOPS.items():
        rel = "assets/audio/placeholders/" + file
        write_wav(rel, recipe(), sr=AMB_SR, stereo=False, peak_db=-6.0, edges=False)
        write_text("data/audio/music/%s.tres" % track_id, f'''[gd_resource type="Resource" script_class="MusicTrack" format=3]

[ext_resource type="Script" path="res://src/audio/music_track.gd" id="1"]

; Generated by tools/audio/generate_placeholders.py.
[resource]
script = ExtResource("1")
id = &"{track_id}"
file = "res://{rel}"
bus = &"{bus}"
volume_db = {volume}
bpm = {float(bpm)}
notes = "{notes}"
''')
    # The libraries
    ext = '[ext_resource type="Script" path="res://src/audio/sound_library.gd" id="1"]\n'
    ext += '[ext_resource type="Script" path="res://src/audio/sound_event.gd" id="2"]\n'
    refs = []
    for n, sound_id in enumerate(sorted(events), start=3):
        ext += '[ext_resource type="Resource" path="res://assets/audio/sound_events/%s.tres" id="%d"]\n' % (sound_id, n)
        refs.append('ExtResource("%d")' % n)
    write_text("assets/audio/sound_library.tres", '[gd_resource type="Resource" script_class="SoundLibrary" format=3]\n\n'
               + ext + "\n; Generated by tools/audio/generate_placeholders.py: every SoundEvent.\n[resource]\n"
               + 'script = ExtResource("1")\nevents = Array[ExtResource("2")]([%s])\n' % ", ".join(refs))
    tracks = sorted(f for f in os.listdir(os.path.join(ROOT, "data/audio/music")) if f.endswith(".tres"))
    ext = '[ext_resource type="Script" path="res://src/audio/music_library.gd" id="1"]\n'
    ext += '[ext_resource type="Script" path="res://src/audio/music_track.gd" id="2"]\n'
    refs = []
    for n, name in enumerate(tracks, start=3):
        ext += '[ext_resource type="Resource" path="res://data/audio/music/%s" id="%d"]\n' % (name, n)
        refs.append('ExtResource("%d")' % n)
    write_text("data/audio/music_library.tres", '[gd_resource type="Resource" script_class="MusicLibrary" format=3]\n\n'
               + ext + "\n; Generated by tools/audio/generate_placeholders.py: every MusicTrack in data/audio/music/.\n"
               + '[resource]\nscript = ExtResource("1")\ntracks = Array[ExtResource("2")]([%s])\n' % ", ".join(refs))
    print("sound events:", len(events), "| music tracks:", len(tracks))


if __name__ == "__main__":
    main()
