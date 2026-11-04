"""Analyse a music track for the game (AUDIO_DESIGN.md §10): length, loudness, tempo, key, vocals and lyrics,
sections (from loudness and timbre changes) and the best loop points for an in-game loop.

Run with the analysis venv (librosa, soundfile, faster-whisper), e.g.:
    D:\\Tools\\audio-venv\\Scripts\\python.exe tools/audio/analyze_track.py Audio_music/Track.mp3 [--no-lyrics]
Prints a JSON summary. Set HF_HOME to a folder on D: so the speech model is stored there.
"""
import json
import sys

import librosa
import numpy as np

SR = 22050
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
# Krumhansl–Schmuckler key profiles
MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


def mmss(seconds):
    return "%d:%04.1f" % (int(seconds) // 60, seconds % 60)


def estimate_key(chroma):
    profile = chroma.mean(axis=1)
    best = None
    for shift in range(12):
        for name, template in (("major", MAJOR), ("minor", MINOR)):
            score = np.corrcoef(profile, np.roll(template, shift))[0, 1]
            if best is None or score > best[0]:
                best = (score, "%s %s" % (KEY_NAMES[shift], name))
    return best[1], round(float(best[0]), 2)


def loudness(path):
    y, sr = librosa.load(path, sr=None, mono=False)
    y = np.atleast_2d(y)
    peak = 20 * np.log10(np.max(np.abs(y)) + 1e-9)
    rms = 20 * np.log10(np.sqrt(np.mean(y ** 2)) + 1e-9)
    return sr, y.shape[0], round(float(peak), 1), round(float(rms), 1)


def sections(y, beat_times):
    """Section boundaries from timbre/harmony changes, labelled with their relative loudness."""
    mfcc = librosa.feature.mfcc(y=y, sr=SR, n_mfcc=13)
    chroma = librosa.feature.chroma_cqt(y=y, sr=SR)
    feats = np.vstack([librosa.util.normalize(mfcc, axis=1), chroma])
    duration = len(y) / SR
    k = int(np.clip(duration // 22, 4, 10))
    bounds = librosa.segment.agglomerative(feats, k)
    times = sorted(set([0.0] + list(librosa.frames_to_time(bounds, sr=SR)) + [duration]))
    rms = librosa.feature.rms(y=y)[0]
    rms_t = librosa.frames_to_time(np.arange(len(rms)), sr=SR)
    overall = np.mean(rms)
    out = []
    for a, b in zip(times[:-1], times[1:]):
        if b - a < 3:
            continue
        seg = rms[(rms_t >= a) & (rms_t < b)]
        level = 20 * np.log10((np.mean(seg) + 1e-9) / (overall + 1e-9))
        out.append({"from": mmss(a), "to": mmss(b), "level_db": round(float(level), 1)})
    return out


def fade_points(y):
    """Where the intro has built up and where the ending starts fading (first/last time near full level)."""
    rms = librosa.feature.rms(y=y, frame_length=4096, hop_length=1024)[0]
    t = librosa.frames_to_time(np.arange(len(rms)), sr=SR, hop_length=1024)
    smooth = np.convolve(rms, np.ones(20) / 20, mode="same")
    ref = np.percentile(smooth, 75)
    loud = np.where(smooth > ref * 0.6)[0]
    return float(t[loud[0]]), float(t[loud[-1]])


def best_loop(y, beat_frames, tempo, fade_in_end, fade_out_start):
    """Loop end near the start of the outro and loop start after the intro, both on beats, with the most
    similar music around them (beat-synchronous chroma + MFCC), the loop length a whole number of bars."""
    chroma = librosa.feature.chroma_cqt(y=y, sr=SR)
    mfcc = librosa.feature.mfcc(y=y, sr=SR, n_mfcc=13)
    feats = np.vstack([chroma, librosa.util.normalize(mfcc, axis=1)])
    sync = librosa.util.sync(feats, beat_frames, aggregate=np.median)
    sync = librosa.util.normalize(sync, axis=0)
    beat_times = librosa.frames_to_time(beat_frames, sr=SR)
    window = 8  # beats compared on each side
    best = None
    for end in range(len(beat_times)):
        te = beat_times[end]
        if te > fade_out_start + 2 or te < fade_out_start - 30:
            continue
        for start in range(end):
            ts = beat_times[start]
            if ts < fade_in_end - 2 or ts > fade_in_end + 25:
                continue
            if (end - start) % 4 != 0 or end - start < 32:
                continue
            if start + window >= sync.shape[1] or end + window >= sync.shape[1] or start < window:
                continue
            a = sync[:, start - window:start + window]
            b = sync[:, end - window:end + window]
            score = float(np.mean(np.sum(a * b, axis=0)))
            if best is None or score > best[0]:
                best = (score, ts, te, end - start)
    if best is None:
        return None
    return {"loop_start": round(best[1], 2), "loop_end": round(best[2], 2), "start": mmss(best[1]),
            "end": mmss(best[2]), "bars": best[3] // 4, "similarity": round(best[0], 3)}


def lyrics(path):
    from faster_whisper import WhisperModel
    model = WhisperModel("base", device="cpu", compute_type="int8")
    audio, _ = librosa.load(path, sr=16000, mono=True)  # decode here: avoids faster-whisper's own decoder (PyAV)
    segments, info = model.transcribe(audio.astype(np.float32), vad_filter=True, beam_size=5)
    lines = []
    for s in segments:
        if s.no_speech_prob < 0.6 and s.avg_logprob > -1.0 and len(s.text.strip()) > 1:
            lines.append({"at": mmss(s.start), "text": s.text.strip()})
    return info.language, round(float(info.language_probability), 2), lines


def main():
    path = sys.argv[1]
    sr0, channels, peak, rms_db = loudness(path)
    y, _ = librosa.load(path, sr=SR, mono=True)
    duration = len(y) / SR
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=SR)
    tempo = float(np.atleast_1d(tempo)[0])
    beat_times = librosa.frames_to_time(beat_frames, sr=SR)
    key, key_conf = estimate_key(librosa.feature.chroma_cqt(y=y, sr=SR))
    fade_in_end, fade_out_start = fade_points(y)
    centroid = float(np.mean(librosa.feature.spectral_centroid(y=y, sr=SR)))
    result = {
        "file": path, "duration": mmss(duration), "seconds": round(duration, 2), "sample_rate": sr0,
        "channels": channels, "peak_dbfs": peak, "rms_dbfs": rms_db, "tempo_bpm": round(tempo, 1),
        "key": key, "key_confidence": key_conf, "brightness_hz": round(centroid),
        "full_level_from": mmss(fade_in_end), "fade_out_from": mmss(fade_out_start),
        "sections": sections(y, beat_times),
        "loop": best_loop(y, beat_frames, tempo, fade_in_end, fade_out_start),
    }
    if "--no-lyrics" not in sys.argv:
        language, language_prob, lines = lyrics(path)
        result["vocals"] = len(lines) >= 3
        result["language"] = language
        result["language_probability"] = language_prob
        result["lyrics"] = lines
    print(json.dumps(result, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
