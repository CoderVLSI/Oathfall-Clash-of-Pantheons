extends SceneTree
# Procedural sound effects and a looping music bed. Run:
#   godot --headless --path . --script res://tools/generate_sfx.gd
# Writes 16-bit mono WAVs into assets/audio/.

const RATE := 22050

func _initialize() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 7
 save("heal",chime([523.25,659.25,783.99,1046.5],.11,.55))
 save("buff",chime([659.25,830.6,987.77,1318.5,1661.2],.06,.35))
 save("ward",ping([1760.0,2349.3],.5))
 save("draw",swish(.22,rng,400.0,2400.0))
 save("damage",thump(.28,rng))
 save("death",fall(.55,rng))
 save("turn",gong(.9))
 save_music(rng)
 print("SFX written")
 quit(0)

func save(name: String, samples: PackedFloat32Array) -> void:
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = RATE
 stream.stereo = false
 stream.data = to_pcm(samples)
 stream.save_to_wav("res://assets/audio/%s.wav" % name)

func to_pcm(samples: PackedFloat32Array) -> PackedByteArray:
 var bytes := PackedByteArray()
 bytes.resize(samples.size() * 2)
 for i in range(samples.size()):
  bytes.encode_s16(i * 2,int(clampf(samples[i],-1.0,1.0) * 30000.0))
 return bytes

func envelope(i: int, total: int, attack: float = .01, release: float = .3) -> float:
 var t := float(i) / RATE
 var duration := float(total) / RATE
 return minf(1.0,t / maxf(attack,.001)) * clampf((duration - t) / maxf(release,.001),0.0,1.0)

func chime(notes: Array, spacing: float, length: float) -> PackedFloat32Array:
 var total := int(RATE * (spacing * notes.size() + length))
 var out := PackedFloat32Array()
 out.resize(total)
 for n in range(notes.size()):
  var start := int(RATE * spacing * n)
  for i in range(start,total):
   var t := float(i - start) / RATE
   out[i] += sin(TAU * notes[n] * t) * exp(-t * 5.0) * .32 + sin(TAU * notes[n] * 2.0 * t) * exp(-t * 8.0) * .08
 return out

func ping(freqs: Array, length: float) -> PackedFloat32Array:
 var total := int(RATE * length)
 var out := PackedFloat32Array()
 out.resize(total)
 for i in range(total):
  var t := float(i) / RATE
  var v := 0.0
  for f in freqs: v += sin(TAU * f * t) * exp(-t * 9.0)
  out[i] = v * .3 + sin(TAU * 220.0 * t) * exp(-t * 14.0) * .2
 return out

func swish(length: float, rng: RandomNumberGenerator, low: float, high: float) -> PackedFloat32Array:
 var total := int(RATE * length)
 var out := PackedFloat32Array()
 out.resize(total)
 var lp := 0.0
 for i in range(total):
  var progress := float(i) / total
  var alpha := clampf((low + (high - low) * progress) / RATE * 1.6,0.02,0.9)
  lp += alpha * (rng.randf_range(-1.0,1.0) - lp)
  out[i] = lp * envelope(i,total,.02,.12) * .8
 return out

func thump(length: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
 var total := int(RATE * length)
 var out := PackedFloat32Array()
 out.resize(total)
 for i in range(total):
  var t := float(i) / RATE
  var body := sin(TAU * (140.0 - 90.0 * t * 3.0) * t) * exp(-t * 14.0)
  var crack := rng.randf_range(-1.0,1.0) * exp(-t * 40.0)
  out[i] = body * .7 + crack * .45
 return out

func fall(length: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
 var total := int(RATE * length)
 var out := PackedFloat32Array()
 out.resize(total)
 var phase := 0.0
 for i in range(total):
  var progress := float(i) / total
  phase += TAU * (420.0 * (1.0 - progress * .8)) / RATE
  var saw := fposmod(phase,TAU) / PI - 1.0
  out[i] = (saw * .3 + rng.randf_range(-1.0,1.0) * .22 * (1.0 - progress)) * envelope(i,total,.005,.35)
 return out

func gong(length: float) -> PackedFloat32Array:
 var total := int(RATE * length)
 var out := PackedFloat32Array()
 out.resize(total)
 for i in range(total):
  var t := float(i) / RATE
  out[i] = (sin(TAU * 110.0 * t) * .5 + sin(TAU * 164.8 * t) * .25 + sin(TAU * 277.2 * t) * .15) * exp(-t * 3.2) * envelope(i,total,.005,.1)
 return out

# 16-second looping pad: Am - F - C - G drone, slow shimmer, sparse pentatonic plucks.
func save_music(rng: RandomNumberGenerator) -> void:
 var rate := 16000
 var seconds := 16
 var total := rate * seconds
 var out := PackedFloat32Array()
 out.resize(total)
 var chords := [[110.0,164.8,220.0,261.6],[87.3,130.8,174.6,220.0],[130.8,196.0,261.6,329.6],[98.0,146.8,196.0,246.9]]
 for i in range(total):
  var t := float(i) / rate
  var bar := int(t / 4.0) % 4
  var local := fmod(t,4.0)
  var swell := sin(PI * local / 4.0)
  var v := 0.0
  for f in chords[bar]: v += sin(TAU * f * t) * .05 + sin(TAU * f * 1.003 * t) * .04
  out[i] = v * (0.45 + 0.55 * swell)
 var scale := [440.0,523.25,587.33,659.25,783.99,880.0]
 for n in range(16):
  var start := int(rate * (n * 1.0 + (0.0 if n % 3 != 0 else 0.5)))
  var f: float = scale[rng.randi_range(0,scale.size() - 1)]
  for i in range(start,mini(start + rate,total)):
   var t := float(i - start) / rate
   out[i] += sin(TAU * f * t) * exp(-t * 4.0) * .07
 # Fade the loop point so the seam is inaudible.
 var fade := rate / 4
 for i in range(fade):
  var k := float(i) / fade
  out[i] *= k
  out[total - 1 - i] *= k
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.stereo = false
 stream.data = to_pcm(out)
 stream.save_to_wav("res://assets/audio/music.wav")
