#!/bin/bash -i
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@disroot.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://z0n1n0z.helioho.st
# zoninoz@disroot.org
#

## zdl-extension types: streaming
## zdl-extension name: Youtube (HD, livestream)

if [[ "$url_in" =~ youtube\.com(\/playlist|.+\/(videos|featured|playlists)$) ]]
then
    html=$(curl -s "$url_in")
    ## yt_json=$($youtube_dl --dump-json "$url_in")

    if [ -z "$html" ]
    then
        yt_location=$(get_location "$url_in")
        html=$(wget -qO- "$yt_location")
    fi

    while read yt_link
    do
        yt_link="https://www.youtube.com${yt_link%%'&'*}"
        yt_link="${yt_link%%u0026*}"
        
        if url "$yt_link"
        then
            test_livestream_boolean=false
            set_line_in_file + "$yt_link" "$path_tmp/not-livestream-links.txt"
            set_link + "$yt_link" &&
                print_c 4 "$(gettext "Redirection"): $yt_link"
            
            [[ "$url_in" =~ youtube\.com(\/playlist|.+\/(videos|featured|playlists|community|channels)$) ]] &&
                replace_url_in "$yt_link"
        fi
    done < <(grep -oP '[^"]+watch\?v=[^"]+' <<< "$html")
    ##done < <(grep -oP '[^"]+youtube\.com\/watch[^"]+' <<< "$yt_json")
    ##done < <(awk '/data-video-id/{match($0, /data-video-id=\"([^"]+)\"/,m); if(m[1]) print "https://www.youtube.com/watch?v=" m[1]}' <<< "$html")
fi

if [ "$url_in" != "${url_in//'youtube.com/embed/'}" ]
then
    url_new="${url_in//embed\//watch\?v=}"
    url "$url_new" &&
        replace_url_in "$url_new"
fi

# System prerequisites check
if ! command -v jq &> /dev/null
then
    print_c 3 "Error ZDL: 'jq' (JSON processor) is required but not installed."
    
elif [[ "$url_in" =~ (youtube\.com\/watch|youtube\.com\/shorts|youtu\.be) ]]
then
    replace_url_in "$(urldecode "$(sed -r 's|(^[^\?]+\?).*&*(v{1}=[^&]+)|\1\2|g' <<< "$url_in")")"    
    replace_url_in "$(sed -r 's|\&list\=[^&]+||g' <<< "$url_in")"    

    # Create a secure temporary sandbox directory in the filesystem for subtitle isolation
    TMP_DIR=$(mktemp -d -t zdl-subs-XXXXXXXXXX)
    print_c 4 "Temporary sandbox initialized: $TMP_DIR"

    print_c 4 "Extracting metadata and analyzing media streams..."
    # Atomic call to $youtube_dl to minimize network overhead and store JSON payload
    JSON_DATA=$($youtube_dl -J "$url_in")

    # Sanitize video title to make it compatible with standard filesystem naming conventions
    TITLE=$(echo "$JSON_DATA" | jq -r '.title | gsub("[\\\\/:*?\"<>|]"; "_")')

    # Detect original video language (fallback to 'und' if missing)
    ORIGINAL_LANG=$(echo "$JSON_DATA" | jq -r '.language // "und"')
    ORIGINAL_LANG=$(echo "$ORIGINAL_LANG" | cut -d'-' -f1)

    # Determine target user language (from $LANG or $LANGUAGE)
    get_language
    USER_LANG=""
    if [ -n "$LANG" ]
    then
        USER_LANG=$(echo "$LANG" | cut -d'_' -f1 | cut -d'.' -f1 | cut -d'-' -f1)

    elif [ -n "$LANGUAGE" ]
    then
        USER_LANG=$(echo "$LANGUAGE" | cut -d':' -f1 | cut -d'_' -f1 | cut -d'-' -f1)
    fi
    get_language_prog
    
    # Preferred subtitle language: use USER_LANG if it exists, otherwise the original language
    PREFERRED_SUB_LANG="${USER_LANG:-$ORIGINAL_LANG}"

    print_c 1 "Original language detected: $ORIGINAL_LANG"

    if [ -n "$USER_LANG" ]
    then
        print_c 1 "User requested language (\$LANG/\$LANGUAGE): $USER_LANG"

    else
        print_c 3 "No \$LANG/\$LANGUAGE variable detected"
    fi

    # ---------------------------------------------------------------------
    # 1. Video Stream Selection (Optimized target <= 1080p)
    # ---------------------------------------------------------------------
    VIDEO_ID=$(echo "$JSON_DATA" | jq -r '[.formats[] | select(.vcodec != "none" and .acodec == "none" and .height <= 1080)] | sort_by(.height) | last | .format_id')

    if [ "$VIDEO_ID" = "null" ] ||
           [ -z "$VIDEO_ID" ]
    then
        print_c 2 "Warning: No video-only stream <= 1080p detected. Falling back to best combined format..."
        VIDEO_ID=$(echo "$JSON_DATA" | jq -r '[.formats[] | select(.height <= 1080)] | sort_by(.height) | last | .format_id')
    fi
    print_c 4 "Selected Video ID for streaming: $VIDEO_ID"

    # ---------------------------------------------------------------------
    # 2. Multi-language Audio Tracks Analysis & Parsing (Conditional)
    # ---------------------------------------------------------------------
    print_c 4 "Mapping and de-duplicating audio tracks..."
    AUDIO_IDS=()
    AUDIO_LANGS=()
    DEFAULT_AUDIO_INDEX=0
    CURRENT_INDEX=0
    FOUND_USER_AUDIO=false

    if [ -n "$USER_LANG" ]
    then
        print_c 4 "Fast audio mode: targeted extraction for original ($ORIGINAL_LANG) and requested ($USER_LANG) languages..."
    #     AUDIO_LIST=$(echo "$JSON_DATA" | jq -r --arg orig "$ORIGINAL_LANG" --arg user "$USER_LANG" '
    #   .formats[] | select(.vcodec == "none" and .acodec != "none") | 
    #   . as $f |
    #   (($f.language // "und") | split("-")[0]) as $lang |
    #   select($lang == $orig or $lang == $user) |
    #   "\(.format_id) \($f.language // "und") \((.language_preference // 0))"
    # ')
        AUDIO_LIST=$(echo "$JSON_DATA" | jq -r --arg orig "$ORIGINAL_LANG" --arg user "$USER_LANG" '
      [.formats[] | select(.vcodec == "none" and .acodec != "none")] |
      group_by(.language // "und") |
      map(
        sort_by(.abr // .tbr // 0) | last
      )[] |
      . as $f |
      (($f.language // "und") | split("-")[0]) as $lang |
      select($lang == $orig or $lang == $user) |
      "\(.format_id) \($f.language // "und") \((.language_preference // 0))"
    ')
    else
        echo "Full scan of all available audio tracks..."
        # AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '.formats[] | select(.vcodec == "none" and .acodec != "none") | "\(.format_id) \(.language // "und") \((.language_preference // 0))"')
        AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '
      [.formats[] | select(.vcodec == "none" and .acodec != "none")] |
      group_by(.language // "und") |
      map(
        sort_by(.abr // .tbr // 0) | last
      )[] |
      "\(.format_id) \(.language // "und") \((.language_preference // 0))"
    ')
    fi

    while IFS= read -r line
    do
        if [ -z "$line" ]
        then
            continue
        fi
        
        format_id=$(echo "$line" | awk '{print $1}')
        lang=$(echo "$line" | awk '{print $2}')
        pref=$(echo "$line" | awk '{print $3}')
        
        clean_audio_lang=$(echo "$lang" | cut -d'-' -f1)
        
        AUDIO_IDS+=("$format_id")
        AUDIO_LANGS+=("$lang")
        
        if [ -n "$USER_LANG" ] &&
               [ "$clean_audio_lang" = "$USER_LANG" ] &&
               [ "$FOUND_USER_AUDIO" = false ]
        then
            DEFAULT_AUDIO_INDEX=$CURRENT_INDEX
            FOUND_USER_AUDIO=true

        elif [ -z "$USER_LANG" ] && [ "$pref" -ge 0 ]
        then
            DEFAULT_AUDIO_INDEX=$CURRENT_INDEX

        elif [ -z "$USER_LANG" ] &&
                 [ "$DEFAULT_AUDIO_INDEX" -eq 0 ] &&
                 [ "$clean_audio_lang" = "$ORIGINAL_LANG" ]
        then
            DEFAULT_AUDIO_INDEX=$CURRENT_INDEX
        fi
        
        CURRENT_INDEX=$((CURRENT_INDEX + 1))
        
    done <<< "$AUDIO_LIST"

    if [ ${#AUDIO_IDS[@]} -eq 0 ]
    then
        print_c 2 "Warning: No audio streams found with applied filters. Restoring full audio scan..."
        # AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '.formats[] | select(.vcodec == "none" and .acodec != "none") | "\(.format_id) \(.language // "und") \((.language_preference // 0))"')

        AUDIO_LIST=$(echo "$JSON_DATA" | jq -r '
      [.formats[] | select(.vcodec == "none" and .acodec != "none")] |
      group_by(.language // "und") |
      map(
        sort_by(.abr // .tbr // 0) | last
      )[] |
      "\(.format_id) \(.language // "und") \((.language_preference // 0))"
    ')

        while IFS= read -r line
        do
            [ -z "$line" ] && continue
            
            format_id=$(echo "$line" | awk '{print $1}')
            lang=$(echo "$line" | awk '{print $2}')
            pref=$(echo "$line" | awk '{print $3}')
            AUDIO_IDS+=("$format_id")
            AUDIO_LANGS+=("$lang")
            
        done <<< "$AUDIO_LIST"
    fi

    print_c 4 "Mapped Audio streams: ${AUDIO_IDS[*]}"
    print_c 4 "Default audio track set to stream index: $DEFAULT_AUDIO_INDEX"

    # ---------------------------------------------------------------------
    # 3. Subtitles Download and Structural Inspection (Conditional)
    # ---------------------------------------------------------------------
    HAS_SUBS=false
    SUB_FILES=()
    SUB_LANGS=()

    if [ -n "$USER_LANG" ]
    then
        print_c 1 "Fast subtitle mode: targeted extraction for original ($ORIGINAL_LANG) and requested ($USER_LANG) languages..."

        SUB_LIST=$(echo "$JSON_DATA" | jq -r --arg orig "$ORIGINAL_LANG" --arg user "$USER_LANG" '
      (.subtitles, .automatic_captions) | select(. != null) | to_entries[] | 
      select(.key == $orig or .key == $user) |
      .key as $lang | .value[] | select(.ext == "vtt") | "\($lang) \(.url)"
    ' 2>/dev/null || true)
        
    else
        print_c 3 "No \$LANG/\$LANGUAGE variable detected: full scan of all available subtitles..."

        SUB_LIST=$(echo "$JSON_DATA" | jq -r '
      (.subtitles, .automatic_captions) | select(. != null) | to_entries[] | .key as $lang | .value[] | select(.ext == "vtt") | "\($lang) \(.url)"
    ' 2>/dev/null || true)
    fi

    if [ -n "$SUB_LIST" ]
    then
        while IFS= read -r sub_line
        do
            if [ -z "$sub_line" ]
            then
                continue
            fi
            
            sub_lang=$(echo "$sub_line" | awk '{print $1}')
            sub_url=$(echo "$sub_line" | awk '{print $2}')
            
            if [[ " ${SUB_LANGS[*]} " =~ " ${sub_lang} " ]]
            then
                continue
            fi

            if [ -n "$sub_url" ] &&
                   [ "$sub_url" != "null" ]
            then
                output_file="$TMP_DIR/sub_${sub_lang}.vtt"
                
                if command -v curl &> /dev/null
                then
                    curl -s -L "$sub_url" -o "$output_file" || true

                else
                    wget -q -O "$output_file" "$sub_url" || true
                fi

                NUM_RIGHE=$(grep -v -E '(^[0-9]:|^[0-9][0-9]:|^$|^Style:|^Kind:|^Language:|^WEBVTT)' "$output_file" 2>/dev/null | wc -l || echo 0)

                if [ -s "$output_file" ] &&
                       [ "$NUM_RIGHE" -gt 5 ]
                then
                    SUB_FILES+=("$output_file")
                    SUB_LANGS+=("$sub_lang")
                    HAS_SUBS=true
                    print_c 1 "   -> [OK] Valid subtitle intercepted: [$sub_lang] ($NUM_RIGHE lines of text)"
                    
                else
                    rm -f "$output_file"
                fi
            fi
            
        done <<< "$SUB_LIST"
    fi

    # ---------------------------------------------------------------------
    # 4. Direct URL Generation for Audio and Video Streaming
    # ---------------------------------------------------------------------
    print_c 4 "Resolving remote streaming endpoints..."
    URL_V=$($youtube_dl -g -f "$VIDEO_ID" "$url_in")

    ARRAY_URL_AUDIO=()
    for aid in "${AUDIO_IDS[@]}"
    do
        URL_A=$($youtube_dl -g -f "$aid" "$url_in")
        ARRAY_URL_AUDIO+=("$URL_A")
    done

    # ---------------------------------------------------------------------
    # 5. Dynamic Compilation of FFmpeg Arguments Array
    # ---------------------------------------------------------------------
    ffmpeg_opts=()

    ffmpeg_opts+=("-i" "$URL_V")

    for url_a in "${ARRAY_URL_AUDIO[@]}"
    do
        ffmpeg_opts+=("-i" "$url_a")
    done

    if [ "$HAS_SUBS" = true ]
    then
        for sub in "${SUB_FILES[@]}"
        do
            ffmpeg_opts+=("-i" "$sub")
        done
    fi

    ffmpeg_opts+=("-map" "0:v")

    INPUT_INDEX=1
    AUDIO_STREAM_INDEX=0
    
    for _ in "${ARRAY_URL_AUDIO[@]}"
    do
        ffmpeg_opts+=("-map" "${INPUT_INDEX}:a")
        clean_lang=$(echo "${AUDIO_LANGS[$AUDIO_STREAM_INDEX]}" | cut -d'-' -f1)
        ffmpeg_opts+=("-metadata:s:a:${AUDIO_STREAM_INDEX}" "language=${clean_lang}")
        
        AUDIO_STREAM_INDEX=$((AUDIO_STREAM_INDEX + 1))
        INPUT_INDEX=$((INPUT_INDEX + 1))
    done

    DEFAULT_SUB_INDEX=-1

    if [ "$HAS_SUBS" = true ]
    then
        SUB_STREAM_INDEX=0

        for _ in "${SUB_FILES[@]}"
        do
            ffmpeg_opts+=("-map" "${INPUT_INDEX}:s")
            sub_lang_item="${SUB_LANGS[$SUB_STREAM_INDEX]}"
            clean_sub_lang=$(echo "$sub_lang_item" | cut -d'-' -f1)
            ffmpeg_opts+=("-metadata:s:s:${SUB_STREAM_INDEX}" "language=${clean_sub_lang}")
            
            if [ "$clean_sub_lang" = "$PREFERRED_SUB_LANG" ] &&
                   [ "$DEFAULT_SUB_INDEX" -eq -1 ]
            then
                DEFAULT_SUB_INDEX=$SUB_STREAM_INDEX
            fi
            
            SUB_STREAM_INDEX=$((SUB_STREAM_INDEX + 1))
            INPUT_INDEX=$((INPUT_INDEX + 1))            
        done
    fi

    ffmpeg_opts+=("-disposition:a" "none")
    ffmpeg_opts+=("-disposition:a:${DEFAULT_AUDIO_INDEX}" "default")

    if [ "$HAS_SUBS" = true ]
    then
        ffmpeg_opts+=("-disposition:s" "none")

        if [ "$DEFAULT_SUB_INDEX" -ne -1 ]
        then
            ffmpeg_opts+=("-disposition:s:${DEFAULT_SUB_INDEX}" "default")
        fi
    fi
    
    file_in="${TITLE}.mkv"
    sanitize_file_in

    ffmpeg_opts+=("-fflags" "+genpts" "-avoid_negative_ts" "make_zero" "-max_interleave_delta" "5000000")
    ffmpeg_opts+=("-c" "copy" "-c:s" "srt" "$file_in")
    url_in_file="$url_in"
    
    # ---------------------------------------------------------------------
    # 6. Execution of Finalized Lossless Multiplexing Process
    # ---------------------------------------------------------------------
    #echo "Initializing FFmpeg engine for remote stream multiplexing..."
    #ffmpeg -v warning -stats "${ffmpeg_opts[@]}"

    #echo "[ZDL SUCCESS] Processing complete! File saved locally as: '${TITLE}.mkv'"

    get_language
    force_dler FFMpeg
    get_language_prog

    no_check_links+=( googlevideo youtube youtu\.be )

    end_extension
fi
