# Driving-Speed-JND

Experiment and analysis code for measuring the **just-noticeable difference (JND)
in driving speed** under three interior-noise conditions — internal-combustion-engine
vehicle (**ICEV**), electric vehicle (**EV**), and **silence** — at reference speeds
of **40 km/h** and **100 km/h**.

This repository accompanies the paper:

> Zhenxian LI, *"The Influence of Interior Noise on Just-Noticeable Speed Differences
> in Conventional and Electric Vehicles"*, **SAE Technical Paper 2026-01-0671**, 2026.
> https://www.sae.org/papers/influence-interior-noise-noticeable-speed-differences-conventional-electric-vehicles-2026-01-0671

[![DOI](https://img.shields.io/badge/Zenodo-DOI%20pending-blue)](https://zenodo.org)
[![Code: MIT](https://img.shields.io/badge/Code-MIT-green.svg)](LICENSE)
[![Stimuli: CC BY 4.0](https://img.shields.io/badge/Stimuli-CC%20BY%204.0-lightgrey.svg)](LICENSE-stimuli.md)

---

## Code here, stimuli on Zenodo

This Git repository holds the **code** only. The **stimuli** (audio and video) are
large, so they live in the project's **Zenodo record**, which carries the single
citable **DOI** for the whole project and also includes a snapshot of this code and
the stimulus-generation report.

| Part | Where | License |
|------|-------|---------|
| Code (experiment, analysis, stimulus generation) | this GitHub repo | **MIT** ([LICENSE](LICENSE)) |
| Stimuli (audio + video) + generation report | Zenodo record (one DOI) | **CC BY 4.0** ([LICENSE-stimuli.md](LICENSE-stimuli.md)) |

On Zenodo you can choose to download the **full stimulus set**, or just the
**audio + a few sample clips** and regenerate the rest with the scripts here.

## What this is

Drivers partly judge their speed from the sound of the cabin. As cars electrify,
that auditory cue changes. Using a two-interval, two-alternative forced-choice
(2AFC) task with an adaptive staircase, this study measures how small a speed
change a viewer can reliably detect under each sound condition.

On each trial the participant watches two short first-person highway clips
(a *reference* speed and a slightly different *comparison* speed) and reports
which looked faster. The speed difference Δv is adjusted trial-by-trial with a
**2-down / 1-up staircase combined with PEST** adaptive step sizing. The JND is
derived from the staircase reversals.

**Headline result** (mean JND after outlier removal): at 100 km/h, **ICEV 1.93**,
**EV 3.48**, **Silence 5.15 km/h** — removing engine sound roughly doubles the
detectable speed change, and the EV's quieter, less tonal sound sits in between.

## Repository layout (code)

```
Driving-Speed-JND/
├── src/
│   ├── experiment/                  MATLAB experiment (run this to test a participant)
│   │   ├── run2down1upPEST40.m        40 km/h reference block (EV, MUTE, ICEV)
│   │   ├── run2down1upPEST100.m       100 km/h reference block (EV, MUTE, ICEV)
│   │   ├── run40100PESTtogether.m     runs both blocks in one session
│   │   ├── listenTestUseVLC.m         plays a stimulus pair in VLC, collects the 2AFC choice
│   │   ├── CharMapper.m               reversible file-name scrambler (experimenter blinding)
│   │   └── charMapping.mat            the mapping used in the original study
│   ├── analysis/
│   │   └── calcJND_reversalMeans.m    computes JND from staircase reversals + plots
│   └── stimulus_generation/
│       ├── batch_speed_adjust.sh      ffmpeg: make speed-adjusted muted clips
│       └── merge_video_audio.sh       ffmpeg: add cabin sound to each clip
├── data/
│   └── sample_staircase/            6 anonymised sample staircases (2 speeds × 3 sounds)
├── docs/
│   └── STIMULI_GENERATION.md        how the audio and video stimuli were produced
├── stimuli/  video/                 empty placeholders — drop the Zenodo download here
├── results/                         experiment output is written here (git-ignored)
├── CITATION.cff   .zenodo.json   LICENSE   LICENSE-stimuli.md
└── README.md
```

## Requirements

- **MATLAB R2019b or newer** (the analysis plots use `tiledlayout`/`nexttile`;
  the experiment scripts alone run on R2016b+). No extra toolboxes are needed.
- **[VLC media player](https://www.videolan.org/)** — used to play the stimuli.
  The path is detected automatically on macOS, Windows and Linux; edit
  `getVlcPath()` in [`listenTestUseVLC.m`](src/experiment/listenTestUseVLC.m) if
  VLC is installed elsewhere.
- **[ffmpeg](https://ffmpeg.org/)** — only needed to (re)generate the video stimuli.

All paths in the code are resolved **relative to the repository**, so you can
clone it anywhere.

## Quick start

### A. Analyse the bundled demo data (no downloads needed)

In MATLAB, open this repository folder and run:

```matlab
run src/analysis/calcJND_reversalMeans.m
```

It reads the six anonymised staircases in
[`data/sample_staircase/`](data/sample_staircase), plots each one (all trials,
reversals, the last-six reversals, the trimmed outlier, and the raw vs. pruned
JND lines), and prints a JND summary table. This reproduces the per-staircase
analysis shown in Figure 3 of the paper.

### B. Run the experiment

1. **Get the stimuli from Zenodo.** Download the audio and video archives from the
   Zenodo record and unzip them into `stimuli/` and `video/` (see
   [`stimuli/README.md`](stimuli/README.md) and [`video/README.md`](video/README.md)
   for the exact layout). You can take the full set, or just the audio + sample
   clips and regenerate the rest (step C).
2. In MATLAB, open the repository folder and edit the participant ID near the top
   of the runner (`Name = "TestSubject01";`).
3. Run one of:
   ```matlab
   run src/experiment/run2down1upPEST40.m        % 40 km/h block
   run src/experiment/run2down1upPEST100.m       % 100 km/h block
   run src/experiment/run40100PESTtogether.m     % both blocks
   ```
   Each block tests the EV, MUTE and ICEV conditions in turn, with a 1-minute
   break between them. For every trial two clips play fullscreen in VLC, then a
   dialog asks which was faster.
4. Raw staircases are saved to `results/StaircaseResult_<timestamp>_<ID>_2down1up<COND>.mat`.
5. Compute JNDs by setting `folderPath = fullfile(repoRoot,'results')` in
   [`calcJND_reversalMeans.m`](src/analysis/calcJND_reversalMeans.m) and running it.

> **Experimenter blinding.** In the original study the on-screen file names were
> scrambled (via `CharMapper`/`charMapping.mat`) so the tester could not see the
> encoded speed. This is **off by default** (`doHideName = 0`) so the plainly
> named stimuli run out-of-the-box. To reproduce the blinding, generate a
> `hidename/` subfolder of scrambled copies and set `doHideName = 1`.

### C. (Re)generate the video stimuli

The visual scene is identical across conditions — only the cabin sound differs —
so all speeds come from re-timing one source clip and then adding sound:

```bash
# 1) muted, speed-adjusted base clips -> video/source_muted/
src/stimulus_generation/batch_speed_adjust.sh

# 2) add the matching cabin sound -> video/mergeEV|mergeICEV|mergeMUTE/
src/stimulus_generation/merge_video_audio.sh EV
src/stimulus_generation/merge_video_audio.sh ICEV
src/stimulus_generation/merge_video_audio.sh MUTE
```

By default `batch_speed_adjust.sh` re-times the 100 km/h sample (in the Zenodo
"audio + samples" download) into the 100–132 km/h range. To regenerate everything
at the original quality, start from the raw recording `ICEV24.mkv` (also on Zenodo)
— see [`video/README.md`](video/README.md).

## Method summary

- **Visual stimulus:** ~7 s first-person highway clip rendered in Siemens Prescan,
  played at a constant speed; the comparison clip is the same scene re-timed.
- **Auditory conditions:** ICEV engine sound, EV motor sound, or silence — each
  with matched wind/tyre noise, calibrated to real-vehicle SPLs.
- **Task:** 2AFC — "which clip was faster?", presentation order counter-balanced.
- **Adaptive rule:** 2-down/1-up staircase with PEST step sizing
  ([Taylor & Creelman, 1967](https://doi.org/10.1121/1.1910407)). Initial offset
  ±10 km/h (40 block) / ±32 km/h (100 block); minimum step 1 / 2 km/h. A block ends
  at ~6 reversals near the minimum step, 12 reversals total, or 50 trials.
- **JND:** mean of the last 6 reversal levels, after discarding the single
  reversal whose absolute deviation from the median exceeds twice the mean
  absolute deviation. Implemented in
  [`calcJND_reversalMeans.m`](src/analysis/calcJND_reversalMeans.m).

Full details of how the stimuli were produced are in
[`docs/STIMULI_GENERATION.md`](docs/STIMULI_GENERATION.md).

## Data format

Each result `.mat` holds a struct array `resultsArray`, one element per trial:

| field | meaning |
|---|---|
| `trialIndex` | trial number |
| `speed_ref` | reference speed (40 or 100 km/h) |
| `speed_compare` | comparison speed this trial |
| `diffBeforeStep` / `diffAfterStep` | Δv before / after the staircase update |
| `reversalFlag` | true if this trial was a reversal |
| `directionThisStep` | `'up'`, `'down'` or `'none'` |
| `choice` | participant choice: 1, 2, or `'Cancel'` |
| `choiceIsEV` | whether the choice was correct |
| `playOrder` | playback order (experiment output only) |

The bundled demo files in `data/sample_staircase/` contain only the numeric and
logical fields (the analysis uses `diffBeforeStep` and `reversalFlag`).

## Participant data

Only six fully **anonymised** sample staircases are shared (file names carry no
identity; only trial-level numbers are stored). The full raw dataset is not
redistributed, in line with the participants' consent.

## How to cite

Please cite **both** the paper and the Zenodo record.

- **Paper:** Z. LI, "The Influence of Interior Noise on Just-Noticeable Speed
  Differences in Conventional and Electric Vehicles," SAE Technical Paper
  2026-01-0671, 2026. doi:10.4271/2026-01-0671
- **Code + stimuli:** the Zenodo DOI (added on first release; see
  [`CITATION.cff`](CITATION.cff)). Because the Zenodo record contains both the code
  and the stimuli, that single DOI covers whichever part you use.

## License

- **Code:** [MIT License](LICENSE).
- **Stimuli and the generation report:** [CC BY 4.0](LICENSE-stimuli.md).

The SAE Technical Paper itself is © SAE International and is not redistributed here.
Please respect any third-party terms attached to the vehicle recordings and
simulation tools used to create the stimuli.

## Acknowledgements

This work was supported by the European Commission through the Horizon Europe
Programme (**GAP-Noise** project, Grant Agreement No. **101073014**).

## Contact

Zhenxian LI — zhenxian.li@insa-lyon.fr — INSA Lyon, Villeurbanne, France
