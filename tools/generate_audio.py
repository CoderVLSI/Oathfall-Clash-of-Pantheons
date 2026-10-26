"""Rebuild the original lightweight UI/gameplay sound effects (standard library only)."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
random.seed(14)
SOUNDS = {
    "click": (0.10, [660, 990]),
    "summon": (0.38, [220, 330, 440]),
    "attack": (0.23, [90, 135]),
    "win": (0.85, [330, 415, 494, 660]),
    "lose": (0.75, [220, 196, 164]),
}
for name, (duration, notes) in SOUNDS.items():
    data = bytearray()
    for index in range(int(RATE * duration)):
        t = index / RATE
        envelope = min(1.0, t / 0.008) * max(0.0, 1 - t / duration) ** 2
        if name in ("win", "lose"):
            active = min(len(notes) - 1, int(t / duration * len(notes)))
            sample = sum(math.sin(2 * math.pi * f * t) for f in notes[:active + 1]) / len(notes)
        else:
            sample = sum(math.sin(2 * math.pi * f * t) for f in notes) / len(notes)
        if name == "attack":
            sample = sample * 0.7 + random.uniform(-0.3, 0.3)
        data.extend(struct.pack("<h", int(sample * envelope * 12500)))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(data)
print("Generated five original sound effects.")
