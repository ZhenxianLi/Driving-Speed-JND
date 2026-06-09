#!/usr/bin/env bash
# merge_video_audio.sh
# Author: Zhenxian LI (zhenxian.li@insa-lyon.fr), INSA Lyon, LVA
# -----------------------------------------------------------------------------
# Merge each speed's muted video with its matching cabin-sound recording to
# produce the final stimuli played in the experiment.
#
#     video/source_muted/GenerateICEV_<speed>x_no_audio.mkv
#   + stimuli/audio/<COND>/<COND><speed>_MIX.wav
#   = video/merge<COND>/merge<COND><speed>_MIX.mkv
#
# The visual scene is identical for every condition; only the cabin sound
# differs (EV motor vs. ICEV engine). For the MUTE (silence) condition there
# is no audio, so the muted video is simply copied to the merge<MUTE> name.
#
# Usage:
#   ./merge_video_audio.sh EV
#   ./merge_video_audio.sh ICEV
#   ./merge_video_audio.sh MUTE
#
# Requires: ffmpeg, grep, awk.
# -----------------------------------------------------------------------------

set -euo pipefail

COND="${1:-}"
if [[ "$COND" != "EV" && "$COND" != "ICEV" && "$COND" != "MUTE" ]]; then
    echo "Usage: $0 {EV|ICEV|MUTE}" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VIDEO_DIR="$REPO_ROOT/video/source_muted"
OUT_DIR="$REPO_ROOT/video/merge${COND}"
mkdir -p "$OUT_DIR"
shopt -s nullglob

if [[ "$COND" == "MUTE" ]]; then
    # Silence condition: the stimulus is just the muted video, renamed.
    for video_file in "$VIDEO_DIR"/GenerateICEV_*x_no_audio.mkv; do
        num=$(basename "$video_file" | grep -oE '[0-9]+' | head -1)
        out_file="$OUT_DIR/mergeMUTE${num}_MIX.mkv"
        ffmpeg -y -i "$video_file" -c:v copy -an "$out_file"
        echo "Created: $out_file"
    done
    exit 0
fi

AUDIO_DIR="$REPO_ROOT/stimuli/audio/${COND}"
for wav_file in "$AUDIO_DIR"/*.wav; do
    base_name="$(basename "${wav_file%.*}")"                 # e.g. EV100_MIX
    num=$(echo "$base_name" | grep -oE '[0-9]+' | head -1)   # e.g. 100
    video_file="$VIDEO_DIR/GenerateICEV_${num}x_no_audio.mkv"
    out_file="$OUT_DIR/merge${base_name}.mkv"

    if [[ ! -f "$video_file" ]]; then
        echo "Skip ${base_name}: missing video $video_file" >&2
        continue
    fi

    # Copy the video stream, encode the audio to AAC, trim to 15 s.
    ffmpeg -y -i "$video_file" -i "$wav_file" \
        -c:v copy -c:a aac \
        -map 0:v:0 -map 1:a:0 \
        -t 15 \
        "$out_file"
    echo "Created: $out_file"
done
