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
## zdl-extension name: Dailymotion (HD, livestream)


if [ "$url_in" != "${url_in//dailymotion.com\/video}" ]
then
    dailymotion_data=$($youtube_dl --get-url --get-filename "$url_in")

    url_in_file=$(head -n1 <<< "$dailymotion_data")
    url_in_file=$(sanitize_url "$url_in_file")
    
    file_in=$(tail -n1 <<< "$dailymotion_data")
    file_filter "$file_in"
    
    if check_livestream "$url_in_file"
    then
        get_livestream_start_time "$url_in" dm_start_time
        get_livestream_duration_time "$url_in" dm_duration_time

        file_in="${file_in%.mp4}"_$(date +%Y-%m-%d)_dalle_$(date +%H-%M-%S)__prog_inizio_${dm_start_time//\:/-}_durata_${dm_duration_time//\:/-}.mp4

        if [ -n "$dm_duration_time" ]
	then
	    print_c 4 "Diretta Dailymotion dalle $dm_start_time per la durata di $dm_duration_time"
	    livestream_m3u8="$url_in_file"
            force_dler FFMpeg
	else
	    [ -n "$gui_alive" ] &&
		check_linksloop_livestream ||
		    _log 43
	fi
      
    else    
        [ -n "$file_in" ] &&
            file_in="${file_in%.mp4}".mp4

        [[ "$url_in_file" =~ \.m3u8 ]] &&
            force_dler FFMPeg
    fi
    
    end_extension
    # echo -e ".dailymotion.com\tTRUE\t/\tFALSE\t0\tff\toff" > "$path_tmp"/cookies.zdl
    # html=$(wget -t 1 -T $max_waiting \
    # 		--load-cookies="$path_tmp"/cookies.zdl \
    # 		"$url_in" \
    # 		-qO- -o /dev/null)

    # if [ -n "$html" ]
    # then
    # 	file_in=$(grep "title>" <<< "$html")
    # 	file_in="${file_in#*'<title>'}"
    # 	file_in="${file_in%'</title>'*}.mp4"

    # 	url_in2="${url_in//'/video/'//embed/video/}"
    # 	url_in2="${url_in2%%_*}"

    # 	code=$(urldecode "$(wget -t 1 -T $max_waiting -q $url_in2 -O - -o /dev/null)" | grep mp4\?auth)

    # 	if [ -n "$code" ]
    # 	then
    # 	    auth="${code##*'mp4?auth='}"
    # 	    auth="${auth%%\"*}"
    # 	    url_in_file="${code%$auth*}$auth"
    # 	    url_in_file="${url_in_file##*\"}"
    # 	    url_in_file="${url_in_file//'\/'//}"
    # 	else
    # 	    _log 2
    # 	fi
    # else
    # 	_log 2
    # fi
fi
