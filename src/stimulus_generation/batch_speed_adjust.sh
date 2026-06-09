#!/usr/bin/env bash
# batch_speed_adjust.sh
# Author: Zhenxian LI (zhenxian.li@insa-lyon.fr), INSA Lyon, LVA
# -----------------------------------------------------------------------------
# Generate constant-speed driving clips at a range of target speeds by
# re-timing a single source recording with ffmpeg (the setpts filter).
#
# Output:  <repo>/video/source_muted/GenerateICEV_<speed>x_no_audio.mkv
# These muted clips are the visual stimuli. merge_video_audio.sh then adds the
# matching cabin sound to produce the final EV / ICEV / MUTE stimuli.
#
# Usage:
#   ./batch_speed_adjust.sh [INPUT_VIDEO]
#
# Configuration via environment variables (defaults in parentheses):
#   INPUT_VIDEO    source recording to re-time
#                  (video/source_muted/GenerateICEV_100x_no_audio.mkv, the
#                   shipped 100 km/h sample)
#   ORIGIN_SPEED   speed in km/h that INPUT_VIDEO represents at 1x play rate (100)
#   START END STEP target speed range in km/h (100 132 2)
#   OUT_DIR        output folder (video/source_muted)
#   VCODEC         ffmpeg video codec (libx264; portable across OSes)
#
# Examples:
#   # Regenerate the high-speed block from the shipped 100 km/h sample:
#   ./batch_speed_adjust.sh
#
#   # Regenerate from the original raw recording (downloaded from Zenodo),
#   # which represents ~24 km/h at 1x:
#   ORIGIN_SPEED=24 START=100 END=132 STEP=2 ./batch_speed_adjust.sh /path/to/ICEV24.mkv
#
# Requires: ffmpeg, awk. On macOS you may set VCODEC=h264_videotoolbox for
# hardware-accelerated encoding.
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

INPUT_VIDEO="${1:-${INPUT_VIDEO:-$REPO_ROOT/video/source_muted/GenerateICEV_100x_no_audio.mkv}}"
ORIGIN_SPEED="${ORIGIN_SPEED:-100}"
START="${START:-100}"
END="${END:-132}"
STEP="${STEP:-2}"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/video/source_muted}"
VCODEC="${VCODEC:-libx264}"
LOG_FILE="$OUT_DIR/batch_speed_adjust.log"

mkdir -p "$OUT_DIR"

if [ ! -f "$INPUT_VIDEO" ]; then
    echo "Input video not found: $INPUT_VIDEO" >&2
    echo "Pass one as the first argument, or download the full source video set from Zenodo." >&2
    exit 1
fi

echo "[$(date)] Source: $INPUT_VIDEO (treated as ${ORIGIN_SPEED} km/h at 1x)" | tee -a "$LOG_FILE"

for num in $(seq "$START" "$STEP" "$END"); do
    # Playback-rate factor: speed_desired / origin_speed.
    FACTOR=$(awk "BEGIN {printf \"%.4f\", $num / $ORIGIN_SPEED}")
    OUTPUT_VIDEO="$OUT_DIR/GenerateICEV_${num}x_no_audio.mkv"
    echo "[$(date)] speed ${num} km/h (factor ${FACTOR}x) -> $(basename "$OUTPUT_VIDEO")" | tee -a "$LOG_FILE"

    # setpts re-times the video; fps=60 fixes the frame rate; -t 15 trims to
    # at most 15 s; -an drops audio (added later by merge_video_audio.sh).
    ffmpeg -y -i "$INPUT_VIDEO" \
        -vf "setpts=PTS/${FACTOR},fps=60" \
        -t 15 -c:v "$VCODEC" -an "$OUTPUT_VIDEO" \
        >>"$LOG_FILE" 2>&1

    echo "[$(date)] done: $(basename "$OUTPUT_VIDEO")" | tee -a "$LOG_FILE"
done

echo "[$(date)] Batch complete. Output in $OUT_DIR" | tee -a "$LOG_FILE"
