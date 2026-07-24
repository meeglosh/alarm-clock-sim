#!/usr/bin/env python3
"""Synthesizes the game's sound effects as 44.1kHz 16-bit mono WAVs.

Outputs (to AlarmClockSimulator/Resources/):
  alarm.wav  - harsh digital alarm beeps, ~2s, loopable; also used as the
               notification sound
  smash.wav  - clock destruction: noise burst, low thump, metallic ring,
               debris clinks
  snooze.wav - soft two-note relief ding
"""
import math
import os
import random
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "AlarmClockSimulator", "Resources")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    clipped = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in clipped))
    print(f"wrote {path} ({len(samples)/RATE:.2f}s)")


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(base, add, at):
    out = list(base)
    start = int(RATE * at)
    needed = start + len(add)
    if needed > len(out):
        out.extend([0.0] * (needed - len(out)))
    for i, s in enumerate(add):
        out[start + i] += s
    return out


def beep(freq, dur, vol):
    """Square-ish beep with a hard digital edge and short fade."""
    n = int(RATE * dur)
    fade = int(RATE * 0.004)
    out = []
    for i in range(n):
        t = i / RATE
        s = math.sin(2 * math.pi * freq * t)
        s = (1 if s > 0 else -1) * 0.6 + 0.4 * s  # soften the square slightly
        env = min(1.0, i / fade, (n - i) / fade)
        out.append(s * vol * env)
    return out


def alarm():
    """Classic digital alarm: four fast beeps, pause, repeat. 2s loop."""
    out = silence(2.0)
    for rep in (0.0, 1.0):
        for k in range(4):
            out = mix(out, beep(2093, 0.10, 0.55), rep + k * 0.16)
    return out


def noise_burst(dur, tau, vol):
    n = int(RATE * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / RATE
        white = random.uniform(-1, 1)
        # crude high-pass: difference against previous sample, for a
        # glassy/crunchy texture rather than rumble
        s = (white - prev) * 0.7 + white * 0.3
        prev = white
        out.append(s * vol * math.exp(-t / tau))
    return out


def decaying_sine(freq, dur, tau, vol, sweep=1.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (sweep + (1 - sweep) * (1 - t / dur)) if sweep != 1.0 else freq
        phase += 2 * math.pi * f / RATE
        out.append(math.sin(phase) * vol * math.exp(-t / tau))
    return out


def smash():
    random.seed(7)
    out = silence(1.1)
    # impact crunch
    out = mix(out, noise_burst(0.5, 0.09, 0.9), 0.0)
    # low thump, pitch dropping 90 -> 45 Hz
    out = mix(out, decaying_sine(90, 0.35, 0.12, 0.8, sweep=0.5), 0.0)
    # metallic body ring
    for f, v in ((2800, 0.20), (3730, 0.16), (5170, 0.12)):
        out = mix(out, decaying_sine(f, 0.5, 0.16, v), 0.005)
    # debris clinks scattering after the hit
    for _ in range(9):
        at = random.uniform(0.12, 0.7)
        f = random.uniform(4200, 9000)
        out = mix(out, decaying_sine(f, 0.09, 0.02, random.uniform(0.05, 0.14)), at)
    return out


def snooze():
    out = silence(0.5)
    out = mix(out, decaying_sine(880, 0.4, 0.12, 0.35), 0.0)
    out = mix(out, decaying_sine(1318, 0.35, 0.10, 0.25), 0.06)
    return out


write_wav("alarm.wav", alarm())
write_wav("smash.wav", smash())
write_wav("snooze.wav", snooze())
