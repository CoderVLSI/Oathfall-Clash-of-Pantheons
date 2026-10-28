<#
.SYNOPSIS
  Generates Oathfall's sound effects and music loop with the ElevenLabs Sound Effects API.

.DESCRIPTION
  Reads the API key from the ELEVENLABS_API_KEY environment variable, or from a line
  `ELEVENLABS_API_KEY=...` in a .env file at the project root (.env is git-ignored).
  The key is never printed or written anywhere. Each sound is requested as MP3, then converted
  with ffmpeg to a mono WAV in assets/audio/ under the name the game already loads.

  Existing files are skipped unless -Force is given, so a partial run can be resumed.
  Credits are only spent on sounds that are actually generated.

.EXAMPLE
  .\tools\generate_sfx_elevenlabs.ps1 -DryRun          # list what would be generated
  .\tools\generate_sfx_elevenlabs.ps1 -Only click,heal # just these two
  .\tools\generate_sfx_elevenlabs.ps1 -Force           # regenerate everything
#>
param(
  [string[]]$Only,
  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
if ($Only) { $Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'assets\audio'

# --- API key: environment first, then the git-ignored .env file --------------------------
$key = $env:ELEVENLABS_API_KEY
if (-not $key) { $key = [Environment]::GetEnvironmentVariable('ELEVENLABS_API_KEY','User') }
if (-not $key) {
  $envFile = Join-Path $root '.env'
  if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
      if ($line -match '^\s*ELEVENLABS_API_KEY\s*=\s*(.+?)\s*$') { $key = $Matches[1].Trim('"').Trim("'") }
    }
  }
}
if (-not $key -and -not $DryRun) {
  throw "No ElevenLabs key found. Set the ELEVENLABS_API_KEY environment variable, or add a line ELEVENLABS_API_KEY=... to $root\.env"
}
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { throw 'ffmpeg is required to convert the MP3s to WAV.' }

# --- The sound set: name (matches res://assets/audio/<name>.wav), prompt, length, loop -----
$sounds = [ordered]@{
  click   = @{ text = 'crisp short user interface button click, subtle polished metal tap, fantasy game menu'; seconds = 0.5 }
  summon  = @{ text = 'magical summoning whoosh with a rising shimmer and a soft heavy thud, fantasy card game, a creature appears'; seconds = 1.5 }
  attack  = @{ text = 'quick sword slash impact with a metallic clang, fantasy battle, punchy'; seconds = 1.0 }
  damage  = @{ text = 'heavy punchy impact hit with a low thump and a crack, fantasy card game damage'; seconds = 0.8 }
  heal    = @{ text = 'warm gentle healing chime, rising harp glissando with soft sparkles, fantasy'; seconds = 1.6 }
  buff    = @{ text = 'bright magical empowerment sparkle, quick rising chime shimmer, fantasy power up'; seconds = 1.2 }
  ward    = @{ text = 'metallic magical shield ping, a bright ringing barrier shimmer, fantasy'; seconds = 1.2 }
  draw    = @{ text = 'soft card draw swish, a paper card slide with a light flick, tabletop card game'; seconds = 0.6 }
  death   = @{ text = 'creature defeated, a short dramatic descending tone with a crumbling impact, fantasy'; seconds = 1.5 }
  turn    = @{ text = 'deep resonant gong strike with a long shimmering tail, announcing a new turn, epic fantasy'; seconds = 2.5 }
  omen    = @{ text = 'ominous cosmic omen, low rumbling drone with an eerie rising choir swell, mythic fate'; seconds = 3.0 }
  oath    = @{ text = 'triumphant sacred oath fulfilled, epic brass and choir fanfare with a ringing bell, mythic victory'; seconds = 4.0 }
  win     = @{ text = 'victorious fantasy fanfare, heroic horns and choir, short triumphant cinematic sting'; seconds = 4.0 }
  lose    = @{ text = 'somber defeat sting, low mournful strings and a fading drum, short cinematic'; seconds = 3.5 }
  music   = @{ text = 'epic atmospheric mythological fantasy card game background music, slow cinematic strings, soft choir pads and distant war drums, calm and majestic, no melody changes, seamless loop'; seconds = 22; loop = $true }
}

$names = if ($Only) { $Only } else { $sounds.Keys }
foreach ($name in $names) { if (-not $sounds.Contains($name)) { throw "Unknown sound '$name'. Known: $($sounds.Keys -join ', ')" } }

New-Item -ItemType Directory -Force $outDir | Out-Null
$made = 0
foreach ($name in $names) {
  $spec = $sounds[$name]
  $wav = Join-Path $outDir "$name.wav"
  $label = '{0,-7} {1,4:N1}s{2}' -f $name, $spec.seconds, $(if ($spec.loop) { ' loop' } else { '' })
  if ((Test-Path $wav) -and -not $Force -and -not $Only) {
    Write-Host "skip     $label (exists; use -Force or -Only to regenerate)" -ForegroundColor DarkGray
    continue
  }
  if ($DryRun) { Write-Host "would make $label : $($spec.text)"; continue }

  $payload = @{
    text             = $spec.text
    duration_seconds = $spec.seconds
    prompt_influence = 0.6
    model_id         = 'eleven_text_to_sound_v2'
  }
  if ($spec.loop) { $payload.loop = $true }
  $tmp = Join-Path $env:TEMP "oathfall_$name.mp3"
  try {
    Invoke-WebRequest -Uri 'https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128' `
      -Method Post -Headers @{ 'xi-api-key' = $key } -ContentType 'application/json' `
      -Body ($payload | ConvertTo-Json) -OutFile $tmp | Out-Null
  } catch {
    $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    throw "ElevenLabs request for '$name' failed (HTTP $status). Check the key, plan credits and model access."
  }
  $rate = if ($name -eq 'music') { 22050 } else { 44100 }
  & ffmpeg -y -loglevel error -i $tmp -ac 1 -ar $rate -c:a pcm_s16le $wav
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  $kb = [math]::Round((Get-Item $wav).Length / 1KB)
  Write-Host "made     $label -> $name.wav ($kb KB)" -ForegroundColor Green
  $made++
}
Write-Host "Done: $made generated." -ForegroundColor Cyan
