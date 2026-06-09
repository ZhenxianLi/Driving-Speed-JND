# `stimuli/` — audio stimuli (downloaded from Zenodo)

The audio stimuli are **not stored in this Git repository**. They are distributed,
together with the videos and a stimulus-generation report, in the project's
**Zenodo record** (one DOI; see the main [README](../README.md)).

Licensed under **CC BY 4.0** (see [`../LICENSE-stimuli.md`](../LICENSE-stimuli.md)).

## Where to put the files

Download the audio archive from Zenodo and unzip it so the folders land here:

```
stimuli/
└── audio/
    ├── EV/     EV40_MIX.wav … EV50_MIX.wav, EV100_MIX.wav … EV132_MIX.wav   (28 files)
    └── ICEV/   ICEV40_MIX.wav … ICEV132_MIX.wav                              (28 files)
```

The experiment and the `merge_video_audio.sh` script resolve `stimuli/audio/`
relative to the repository root, so no path editing is needed.

See [`../docs/STIMULI_GENERATION.md`](../docs/STIMULI_GENERATION.md) for how the
audio was produced.
