#!/bin/bash
# =====================================================================
# ZigzagDownLoader (ZDL) - Core Muxing Function Component
# Module: Advanced YouTube/yt-dlp to FFmpeg Pass-Through Pipeline
# License: GNU GPLv3 - Published on Savannah since 2011
# =====================================================================
# Description: Extracts 1080p video, selective or full audio tracks,
#              and smart/fallback subtitles based on $LANG/$LANGUAGE.
# =====================================================================

# Exit immediately if any unhandled critical error occurs
set -e

# System prerequisites check
if ! command -v jq &> /dev/null; then
    echo "Error ZDL: 'jq' (JSON processor) is required but not installed."
    exit 1
fi

# Retrieve URL argument passed from CLI, TUI, or GUI modules
URL="${1}"
if [ -z "$URL" ]; then
    echo "Usage: $0 <YOUTUBE_URL>"
    exit 1
fi

# Create a secure temporary sandbox directory in the filesystem for subtitle isolation
TMP_DIR=$(mktemp -d -t zdl-subs-XXXXXXXXXX)
echo "Temporary sandbox initialized: $TMP_DIR"

# Define EXIT trap to guarantee atomic cleanup of resources on exit or crash
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Extracting metadata and analyzing media streams..."
# Atomic call to yt-dlp to minimize network overhead and store JSON payload
JSON_DATA=$(yt-dlp -J "$URL")

# Sanitize video title to make it compatible with standard filesystem naming conventions
TITOLO=$(echo "$JSON_DATA" | jq -r '.title | gsub("[\\\\/:*?\"<>|]"; "_")')

# Detect original video language (fallback to 'und' if missing)
ORIGINAL_LANG=$(echo "$JSON_DATA" | jq -r '.language // "und"')
ORIGINAL_LANG=$(echo "$ORIGINAL_LANG" | cut -d'-' -f1)

# Determine target user language (from $LANG or $LANGUAGE)
USER_LANG=""
if [ -n "$LANG" ]; then
    USER_LANG=$(echo "$LANG" | cut -d'_' -f1 | cut -d'.' -f1 | cut -d'-' -f1)
elif [ -n "$LANGUAGE" ]; then
    USER_LANG=$(echo "$LANGUAGE" | cut -d':' -f1 | cut -d'_' -f1 | cut -d'-' -f1)
fi

# Preferred subtitle language: use USER_LANG if it exists, otherwise the original language
PREFERRED_SUB_LANG="${USER_LANG:-$ORIGINAL_LANG}"

echo "Original language detected: $ORIGINAL_LANG"
if [ -n "$USER_LANG" ]; then
    echo "User requested language (\$LANG/\$LANGUAGE): $USER_LANG"
else
    echo "No \$LANG/\$LANGUAGE variable detected"
fi

# ---------------------------------------------------------------------
# 1. Video Stream Selection (Optimized target <= 1080p)
# ---------------------------------------------------------------------
VIDEO_ID=$(echo "$JSON_DATA" | jq -r '[.formats[] | select(.vcodec != "none" and .acodec == "none" and .height <= 1080)] | sort_by(.height) | last | .format_id')

if [ "$VIDEO_ID" = "null" ] || [ -z "$VIDEO_ID" ]; then
    echo "Warning: No video-only stream <= 1080p detected. Falling back to best combined format..."
    VIDEO_ID=$(echo "$JSON_DATA" | jq -r '[.formats[] | select(.height <= 1080)] | sort_by(.height) | last | .format_id')
fi
echo "Selected Video ID for streaming: $VIDEO_ID"

# ---------------------------------------------------------------------
# 2. Multi-language Audio Tracks Analysis & Parsing (Conditional)
# ---------------------------------------------------------------------
echo "Mapping and de-duplicating audio tracks..."
AUDIO_IDS=()
AUDIO_LANGS=()
DEFAULT_AUDIO_INDEX=0
CURRENT_INDEX=0
FOUND_USER_AUDIO=false

if [ -n "$USER_LANG" ]; then
    echo "Fast audio mode: targeted extraction for original ($ORIGINAL_LANG) and requested ($USER_LANG) languages..."
    AUDIO_LIST=$(echo "$JSON_DATA" | jq -r --arg orig "$ORIGINAL_LANG" --arg user "$USER_LANG" '
      .formats[] | select(.vcodec == "none" and .acodec != "none") | 
      . as $f |
      (($f.language // "und") | split("-")[0]) as $lang |
      select($lang == $orig or $lang == $user) |
      "\(.format_id) \($f.language // "und") \((.language_preference // 0))"
    ')
else
    echo "Full scan of all available audio tracks..."
    AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '.formats[] | select(.vcodec == "none" and .acodec != "none") | "\(.format_id) \(.language // "und") \((.language_preference // 0))"')
fi

while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi
    
    format_id=$(echo "$line" | awk '{print $1}')
    lang=$(echo "$line" | awk '{print $2}')
    pref=$(echo "$line" | awk '{print $3}')
    
    clean_audio_lang=$(echo "$lang" | cut -d'-' -f1)
    
    AUDIO_IDS+=("$format_id")
    AUDIO_LANGS+=("$lang")
    
    if [ -n "$USER_LANG" ] && [ "$clean_audio_lang" = "$USER_LANG" ] && [ "$FOUND_USER_AUDIO" = false ]; then
        DEFAULT_AUDIO_INDEX=$CURRENT_INDEX
        FOUND_USER_AUDIO=true
    elif [ -z "$USER_LANG" ] && [ "$pref" -ge 0 ]; then
        DEFAULT_AUDIO_INDEX=$CURRENT_INDEX
    elif [ -z "$USER_LANG" ] && [ "$DEFAULT_AUDIO_INDEX" -eq 0 ] && [ "$clean_audio_lang" = "$ORIGINAL_LANG" ]; then
        DEFAULT_AUDIO_INDEX=$CURRENT_INDEX
    fi
    
    CURRENT_INDEX=$((CURRENT_INDEX + 1))
done <<< "$AUDIO_LIST"

if [ ${#AUDIO_IDS[@]} -eq 0 ]; then
    echo "Warning: No audio streams found with applied filters. Restoring full audio scan..."
    AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '.formats[] | select(.vcodec == "none" and .acodec != "none") | "\(.format_id) \(.language // "und") \((.language_preference // 0))"')
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        format_id=$(echo "$line" | awk '{print $1}')
        lang=$(echo "$line" | awk '{print $2}')
        pref=$(echo "$line" | awk '{print $3}')
        AUDIO_IDS+=("$format_id")
        AUDIO_LANGS+=("$lang")
    done <<< "$AUDIO_LIST"
fi

echo "Mapped Audio streams: ${AUDIO_IDS[*]}"
echo "Default audio track set to stream index: $DEFAULT_AUDIO_INDEX"

# ---------------------------------------------------------------------
# 3. Subtitles Download and Structural Inspection (Conditional)
# ---------------------------------------------------------------------
HAS_SUBS=false
SUB_FILES=()
SUB_LANGS=()

if [ -n "$USER_LANG" ]; then
    echo "Fast subtitle mode: targeted extraction for original ($ORIGINAL_LANG) and requested ($USER_LANG) languages..."
    SUB_LIST=$(echo "$JSON_DATA" | jq -r --arg orig "$ORIGINAL_LANG" --arg user "$USER_LANG" '
      (.subtitles, .automatic_captions) | select(. != null) | to_entries[] | 
      select(.key == $orig or .key == $user) |
      .key as $lang | .value[] | select(.ext == "vtt") | "\($lang) \(.url)"
    ' 2>/dev/null || true)
else
    echo "No \$LANG/\$LANGUAGE variable detected: full scan of all available subtitles..."
    SUB_LIST=$(echo "$JSON_DATA" | jq -r '
      (.subtitles, .automatic_captions) | select(. != null) | to_entries[] | .key as $lang | .value[] | select(.ext == "vtt") | "\($lang) \(.url)"
    ' 2>/dev/null || true)
fi

if [ -n "$SUB_LIST" ]; then
    while IFS= read -r sub_line; do
        if [ -z "$sub_line" ]; then
            continue
        fi
        
        sub_lang=$(echo "$sub_line" | awk '{print $1}')
        sub_url=$(echo "$sub_line" | awk '{print $2}')
        
        if [[ " ${SUB_LANGS[*]} " =~ " ${sub_lang} " ]]; then
            continue
        fi

        if [ -n "$sub_url" ] && [ "$sub_url" != "null" ]; then
            output_file="$TMP_DIR/sub_${sub_lang}.vtt"
            
            if command -v curl &> /dev/null; then
                curl -s -L "$sub_url" -o "$output_file" || true
            else
                wget -q -O "$output_file" "$sub_url" || true
            fi

            NUM_RIGHE=$(grep -v -E '(^[0-9]:|^[0-9][0-9]:|^$|^Style:|^Kind:|^Language:|^WEBVTT)' "$output_file" 2>/dev/null | wc -l || echo 0)

            if [ -s "$output_file" ] && [ "$NUM_RIGHE" -gt 5 ]; then
                SUB_FILES+=("$output_file")
                SUB_LANGS+=("$sub_lang")
                HAS_SUBS=true
                echo "   -> [OK] Valid subtitle intercepted: [$sub_lang] ($NUM_RIGHE lines of text)"
            else
                rm -f "$output_file"
            fi
        fi
    done <<< "$SUB_LIST"
fi

# ---------------------------------------------------------------------
# 4. Direct URL Generation for Audio and Video Streaming
# ---------------------------------------------------------------------
echo "Resolving remote streaming endpoints..."
URL_V=$(yt-dlp -g -f "$VIDEO_ID" "$URL")

ARRAY_URL_AUDIO=()
for aid in "${AUDIO_IDS[@]}"; do
    URL_A=$(yt-dlp -g -f "$aid" "$URL")
    ARRAY_URL_AUDIO+=("$URL_A")
done

# ---------------------------------------------------------------------
# 5. Dynamic Compilation of FFmpeg Arguments Array
# ---------------------------------------------------------------------
FFMPEG_ARGS=()

FFMPEG_ARGS+=("-i" "$URL_V")
for url_a in "${ARRAY_URL_AUDIO[@]}"; do
    FFMPEG_ARGS+=("-i" "$url_a")
done

if [ "$HAS_SUBS" = true ]; then
    for sub in "${SUB_FILES[@]}"; do
        FFMPEG_ARGS+=("-i" "$sub")
    done
fi

FFMPEG_ARGS+=("-map" "0:v")

INPUT_INDEX=1
AUDIO_STREAM_INDEX=0
for _ in "${ARRAY_URL_AUDIO[@]}"; do
    FFMPEG_ARGS+=("-map" "${INPUT_INDEX}:a")
    clean_lang=$(echo "${AUDIO_LANGS[$AUDIO_STREAM_INDEX]}" | cut -d'-' -f1)
    FFMPEG_ARGS+=("-metadata:s:a:${AUDIO_STREAM_INDEX}" "language=${clean_lang}")
    
    AUDIO_STREAM_INDEX=$((AUDIO_STREAM_INDEX + 1))
    INPUT_INDEX=$((INPUT_INDEX + 1))
done

DEFAULT_SUB_INDEX=-1
if [ "$HAS_SUBS" = true ]; then
    SUB_STREAM_INDEX=0
    for _ in "${SUB_FILES[@]}"; do
        FFMPEG_ARGS+=("-map" "${INPUT_INDEX}:s")
        sub_lang_item="${SUB_LANGS[$SUB_STREAM_INDEX]}"
        clean_sub_lang=$(echo "$sub_lang_item" | cut -d'-' -f1)
        FFMPEG_ARGS+=("-metadata:s:s:${SUB_STREAM_INDEX}" "language=${clean_sub_lang}")
        
        if [ "$clean_sub_lang" = "$PREFERRED_SUB_LANG" ] && [ "$DEFAULT_SUB_INDEX" -eq -1 ]; then
            DEFAULT_SUB_INDEX=$SUB_STREAM_INDEX
        fi
        
        SUB_STREAM_INDEX=$((SUB_STREAM_INDEX + 1))
        INPUT_INDEX=$((INPUT_INDEX + 1))
    done
fi

FFMPEG_ARGS+=("-disposition:a" "none")
FFMPEG_ARGS+=("-disposition:a:${DEFAULT_AUDIO_INDEX}" "default")

if [ "$HAS_SUBS" = true ]; then
    FFMPEG_ARGS+=("-disposition:s" "none")
    if [ "$DEFAULT_SUB_INDEX" -ne -1 ]; then
        FFMPEG_ARGS+=("-disposition:s:${DEFAULT_SUB_INDEX}" "default")
    fi
fi

FFMPEG_ARGS+=("-c" "copy" "-c:s" "srt" "${TITOLO}.mkv")

# ---------------------------------------------------------------------
# 6. Execution of Finalized Lossless Multiplexing Process
# ---------------------------------------------------------------------
echo "Initializing FFmpeg engine for remote stream multiplexing..."
ffmpeg -v warning -stats "${FFMPEG_ARGS[@]}"

echo "[ZDL SUCCESS] Processing complete! File saved locally as: '${TITOLO}.mkv'"