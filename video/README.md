# `video/` — stimulus videos (downloaded from Zenodo or regenerated)

The stimulus videos are **not stored in this Git repository**. They are
distributed in the project's **Zenodo record** (one DOI; see the main
[README](../README.md)), where you can choose between:

- the **full set** of ready-made audio-visual stimuli, or
- only the **audio + a few sample videos**, then regenerate the rest with the
  scripts in [`../src/stimulus_generation/`](../src/stimulus_generation/).

Videos are licensed under **CC BY 4.0** (see [`../LICENSE-stimuli.md`](../LICENSE-stimuli.md)).

## Layout

```
video/
├── source_muted/   muted, speed-adjusted base clips (visual stimulus, no sound)
│                   e.g. GenerateICEV_100x_no_audio.mkv
├── mergeEV/        EV-sound stimuli   e.g. mergeEV100_MIX.mkv
├── mergeICEV/      ICEV-sound stimuli e.g. mergeICEV100_MIX.mkv
└── mergeMUTE/      silent stimuli     e.g. mergeMUTE100_MIX.mkv
```

The experiment scripts read `video/merge<CONDITION>/merge<CONDITION><speed>_MIX.mkv`.
At 40 km/h the comparison speeds span 40–50 km/h; at 100 km/h they span
100–132 km/h.

## Where to put files downloaded from Zenodo

Unzip the video archive so that the `source_muted/`, `mergeEV/`, `mergeICEV/` and
`mergeMUTE/` folders land **directly inside this `video/` folder**, next to this
file. No path editing is needed — the scripts resolve `video/` relative to the
repository root.

## Regenerating the videos yourself

You only need ffmpeg plus the audio archive and one source clip:

```bash
# 1) muted, speed-adjusted base clips -> video/source_muted/
src/stimulus_generation/batch_speed_adjust.sh

# 2) add the matching cabin sound -> video/merge{EV,ICEV,MUTE}/
src/stimulus_generation/merge_video_audio.sh EV
src/stimulus_generation/merge_video_audio.sh ICEV
src/stimulus_generation/merge_video_audio.sh MUTE
```

For the highest visual fidelity, start from the original raw recording
(`ICEV24.mkv`, in the Zenodo record) instead of the sample clip:

```bash
ORIGIN_SPEED=24 START=100 END=132 STEP=2 \
  src/stimulus_generation/batch_speed_adjust.sh /path/to/ICEV24.mkv
```

See [`../docs/STIMULI_GENERATION.md`](../docs/STIMULI_GENERATION.md) for the full
generation method.
