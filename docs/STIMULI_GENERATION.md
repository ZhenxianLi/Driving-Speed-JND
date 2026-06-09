# Stimulus generation report

This document describes how the audio-visual stimuli for the *Driving-Speed-JND*
study were produced, so that the dataset can be understood, reused, and cited
independently of the code.

It accompanies:

> Li, Z., Parizet, E., and Colangeli, C., "The Influence of Interior Noise on
> Just-Noticeable Speed Differences in Conventional and Electric Vehicles,"
> SAE Technical Paper 2026-01-0671, 2026. doi:10.4271/2026-01-0671

**How to cite:** please cite the paper above (the study) together with the
Zenodo record (the stimuli and code). See `CITATION.cff` in the code repository.

The stimuli consist of three interior-sound conditions — internal-combustion-engine
vehicle (**ICEV**), electric vehicle (**EV**), and **silence (MUTE)** — each at two
reference speeds, **40 km/h** and **100 km/h**. Every stimulus pairs a first-person
highway video with a speed-matched cabin sound.

---

## 1. Visual stimuli

**Source scene.** A first-person highway driving scene was generated in **Siemens
Simcenter Prescan**. It depicts a straight French highway from the driver's
viewpoint, flanked by guardrails, roadside trees, and distant buildings, with
standard highway signage. Each clip lasts about 7 s and is rendered at a constant
speed. Clips start from different points along the road so that participants cannot
rely on memorised start/end scene cues.

**Capture.** The Prescan playback was **screen-recorded** to a base video file
(e.g. `ICEV24.mkv`), which serves as the constant-speed source for re-timing.

**Speed variants.** Clips at each target speed are produced by **re-timing** the
base recording with ffmpeg's `setpts` filter, using

```
playback factor = target_speed / base_speed
```

so a higher target speed plays the same scene proportionally faster. Each output is
fixed to 60 fps, trimmed, and stripped of audio. This is implemented in
[`src/stimulus_generation/batch_speed_adjust.sh`](../src/stimulus_generation/batch_speed_adjust.sh):

```bash
ffmpeg -i "$INPUT_VIDEO" -vf "setpts=PTS/$FACTOR,fps=60" -t 15 -c:v libx264 -an "$OUTPUT_VIDEO"
```

Output files are named `GenerateICEV_<speed>x_no_audio.mkv` (muted base clips).

## 2. Auditory stimuli

**Framework.** The interior sounds were generated with the NVH sound-simulation
framework of the driving simulator, based on **Simcenter Testlab Real Time** and
co-simulated with the Prescan visual environment. The approach combines measured
vehicle NVH data with real-time auralisation to reproduce realistic in-cabin sound
signatures under controlled, constant-speed driving (see references [24–26] in the
paper).

**Vehicle models.**
- **ICEV:** an NVH model of a compact C-segment car with a diesel engine.
- **EV:** representative NVH models derived from anonymised measurements of
  commercially available electric vehicles.
- Both conditions use **identical tyre and wind-noise components**, so the
  powertrain sound is the only systematic difference.

**Export.** Sounds were rendered per speed and exported as stereo (left/right) WAV
files: `ICEV<speed>_MIX.wav` and `EV<speed>_MIX.wav`, covering **40–50 km/h**
(1 km/h steps) and **100–132 km/h** (2 km/h steps) — the ranges spanned by the
adaptive staircases.

**Level calibration.** Playback levels were calibrated to real-vehicle sound
pressure levels. Delivered SPLs (dB(A); L/R = left/right ear), from Table 1 of the
paper:

| Condition | 40 km/h (L) | 40 km/h (R) | 100 km/h (L) | 100 km/h (R) |
|-----------|:-----------:|:-----------:|:------------:|:------------:|
| ICEV      | 53.5 | 53.1 | 63.7 | 63.6 |
| EV        | 46.4 | 46.5 | 56.2 | 55.8 |

Loudness/level consistency across speeds was checked with LUFS-based analysis
(the helper scripts used for this live alongside the recordings in the original
project; they are not required to use the released WAV files).

**Playback chain (in the experiment).** Audio was delivered through an
**RME Fireface UCX** sound card and **Sennheiser HD650** headphones.

## 3. Merging into audio-visual stimuli

Each muted speed clip is combined with its speed-matched cabin sound to form the
final stimulus, using
[`src/stimulus_generation/merge_video_audio.sh`](../src/stimulus_generation/merge_video_audio.sh):

```
video/source_muted/GenerateICEV_<speed>x_no_audio.mkv
+ stimuli/audio/<COND>/<COND><speed>_MIX.wav
= video/merge<COND>/merge<COND><speed>_MIX.mkv
```

The video stream is copied unchanged and the audio is encoded to AAC. For the
**MUTE** (silence) condition there is no audio, so the muted clip is used directly
as `mergeMUTE<speed>_MIX.mkv`. Because the visual scene is identical across
conditions, EV, ICEV and MUTE share the same underlying video and differ only in
the cabin sound.

## 4. Conditions and speed design

| Block | Reference speed | Comparison speeds | Sound conditions |
|-------|:---------------:|-------------------|------------------|
| Low   | 40 km/h  | 40–50 km/h   | EV, ICEV, MUTE |
| High  | 100 km/h | 100–132 km/h | EV, ICEV, MUTE |

In each trial a reference clip and a comparison clip are shown in counter-balanced
order; the comparison speed is set by the adaptive staircase (see the paper and the
experiment code).

## 5. File and naming conventions

| Item | Pattern | Example |
|------|---------|---------|
| Cabin sound (WAV) | `<COND><speed>_MIX.wav` | `ICEV100_MIX.wav` |
| Muted base clip   | `GenerateICEV_<speed>x_no_audio.mkv` | `GenerateICEV_100x_no_audio.mkv` |
| Merged stimulus   | `merge<COND><speed>_MIX.mkv` | `mergeEV100_MIX.mkv` |

## 6. Regenerating the videos yourself

If you download only the audio and the sample videos, you can rebuild the full
video set with the released scripts (no proprietary software needed — only ffmpeg):

```bash
# 1) muted, speed-adjusted base clips -> video/source_muted/
src/stimulus_generation/batch_speed_adjust.sh
# 2) add the matching cabin sound -> video/merge{EV,ICEV,MUTE}/
src/stimulus_generation/merge_video_audio.sh EV
src/stimulus_generation/merge_video_audio.sh ICEV
src/stimulus_generation/merge_video_audio.sh MUTE
```

See the code repository's `README.md` and `video/README.md` for details and for
where to place downloaded files.

## 7. Licensing and third-party notice

- **Stimuli** (audio and video) and **this report**: Creative Commons Attribution
  4.0 International (**CC BY 4.0**).
- **Code**: MIT License.

The sounds were produced with Siemens Simcenter tooling and NVH models within the
GAP-Noise project; the visual scene was rendered in Siemens Prescan. They are shared
here for research and reproducibility. If you redistribute or build upon them,
please provide attribution as described in `CITATION.cff`.

## References (from the paper)

- Taylor, M.M., Creelman, C.D. (1967). *PEST: Efficient Estimates on Probability
  Functions.* JASA 41(4A):782–787. doi:10.1121/1.1910407
- Salamone et al.; Mordillat et al.; Sarrazin et al. — Simcenter NVH simulator and
  wind/tyre-noise synthesis (paper references [24–26]).
