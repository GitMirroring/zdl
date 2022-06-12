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
## ZDL add-on
## zdl-extension types: streaming
## zdl-extension name: La7 (HD)


if [[ "$url_in" =~ la7\.it ]]
then
    html=$(curl -s \
		-H 'Connection: keep-alive' \
		-H 'TE: Trailers' \
		-H 'Upgrade-Insecure-Requests: 1' \
		-A "$user_agent" \
		-c "$path_tmp"/cookies.zdl \
		"$url_in")

    file_in=$(grep -P 'title\s*:' <<< "$html")
    file_in="${file_in#*\"}"
    file_in="${file_in%\"*}"
    file_in="${file_in//\//-}"
    file_filter "$file_in"
    
    url_in_file=$(grep -oP "[^\']+\.m3u8[^\']*" <<< "$html" |
                          head -n1 |
                          grep -oP "[^\"]+\.m3u8[^\"]*")


    url "$url_in_file" ||
	url_in_file=$(grep -oP "[^\"]+\.m3u8[^\"]*" <<< "$html" |
                          head -n1 |
                          grep -oP "[^\"]+\.m3u8[^\"]*")
    
    url_in_file="${url_in_file//index./index_1.}"
    
    if url "$url_in_file" &&
            [[ "$url_in_file" =~ csmil ]]
    then
	url_in_file="https://vodpkg.iltrovatore.it/local/hls/,${url_in_file#*\,}"
	url_in_file="${url_in_file//csmil/urlset}"

        if [[ "$url_in_file" =~ master\.m3u8 ]]
        then
            url_in_file=$(curl -s "$url_in_file" | head -n3 | tail -n1)
        fi
        
    elif [ -n "$url_in_file" ] &&
	   ! url "$url_in_file"
    then
	url_in_file="${url_in_file#*\'m3u8\'\ \:\ \'}"
	url_in_file="${url_in_file#*\'m3u8\'}"
	url_in_file="${url_in_file%%\'*}"

	url_in_file="${url_in_file#*\"m3u8\"\ \:\ \"}"
	url_in_file="${url_in_file#*\"}"
	url_in_file="${url_in_file%%\"*}"

	url_in_file=http://"${url_in_file##*\/\/}"
    fi

    if [[ "$file_in" =~ Diretta ]]
    then
	get_livestream_start_time "$url_in" la7_start_time
	la7_start_time="${la7_start_time//\:tomorrow}"
	
	get_livestream_duration_time "$url_in" la7_duration_time
	file_in+=_$(date +%Y-%m-%d)_dalle_$(date +%H-%M-%S)__prog_inizio_${la7_start_time//\:/-}_durata_${la7_duration_time//\:/-}

	if [ -n "$la7_duration_time" ]
	then
	    print_c 4 "Diretta La7 dalle $la7_start_time per la durata di $la7_duration_time"
	    livestream_m3u8="$url_in_file"

	else
	    [ -n "$gui_alive" ] &&
		check_linksloop_livestream ||
		    _log 43
	fi

    elif [ -n "$file_in" ]
    then
	file_in+=_scaricato_il_$(date +%Y-%m-%d)_alle_$(date +%H-%M-%S)
    fi

    get_language
    force_dler FFMpeg
    get_language_prog
 
    youtubedl_m3u8="$url_in_file"
    end_extension
fi
									   

