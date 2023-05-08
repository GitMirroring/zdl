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
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

## zdl-extension types: streaming
## zdl-extension name: Youtube (HD, livestream)

if [[ "$url_in" =~ youtube\.com\/playlist ]]
then
    html=$(curl -s "$url_in")
    ## yt_json=$($youtube_dl --dump-json "$url_in")
    
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
            
            [[ "$url_in" =~ youtube.com\/playlist ]] &&
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

if [[ "$url_in" =~ (youtube\.com\/watch|youtu\.be) ]]
then       
    replace_url_in "$(urldecode "${url_in%%'&'*}")"    
    
    data=$($youtube_dl -f b --get-title --get-url "${url_in}")       
    url_in_file="$(tail -n1 <<< "$data")"
    yt_title="$(tail -n2 <<< "$data" | head -n1)"

    if ! url "$url_in_file"
    then
	unset file_in url_in_file
    fi

    if [[ "$url_in_file" =~ \.m3u8 ]]
    then
        livestream_m3u8="$url_in"
        force_dler FFMpeg

        get_livestream_duration_time "$url_in" yt_duration
        get_livestream_start_time "$url_in" yt_start
        yt_title="$yt_title"_$(date +%Y-%m-%d)_"${yt_start//\:/\-}"_"${yt_duration//\:/\-}"
    fi
    file_in="$yt_title".mp4
    
    if [ "$downloader_in" == "Axel" ] &&
	   [ -n "$(axel -o /dev/null "$url_in_file" | grep '403 Forbidden')" ]
    then
	force_dler Wget
    fi

    if [[ "$url_in_file" =~ (Age check) ]]
    then
	_log 19
    else
	axel_parts=4
    fi
    
    if [ -n "$file_in" ]
    then
        file_in="${file_in//🔴}"
        sanitize_file_in
    fi
    
    end_extension
fi
