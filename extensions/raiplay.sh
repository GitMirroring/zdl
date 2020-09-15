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
## zdl-extension name: RaiPlay (HD)


if [[ "$url_in" =~ raiplay ]]
then
    if check_livestream "$url_in" ## in libs/extension_utils.sh
    then
        raiplay_json=$(curl -s "${url_in%\#*}.json")

        if [[ ! "$raiplay_json" =~ content_url ]] &&
               [[ "$raiplay_json" =~ first_item_path ]]
        then
            raiplay_url="${raiplay_json#*first_item_path \": \"}"
            raiplay_url="https://www.raiplay.it${raiplay_url%%\"*}"
            raiplay_json=$(curl -s \
                                -c "$path_tmp"/cookies.zdl \
                                -A "$user_agent" \
                                "$raiplay_url")
        fi
        
        raiplay_url="${raiplay_json#*content_url\": \"}"
        raiplay_url="${raiplay_url%%\"*}"

        get_language_prog
	url_in_file=$(get_location "$raiplay_url")
        get_language
        
        if ! url "$url_in_file"
        then
            get_language_prog
            url_in_file=$(wget -SO- "$raiplay_url" 2>&1 |
                              grep ocation)
            get_language
        fi
	get_livestream_start_time "$url_in" rai_start_time

	get_livestream_duration_time "$url_in" rai_duration_time
	rai_start_time="${rai_start_time//\:tomorrow}"
	
        file_in="${raiplay_json#*\"name\":\"}"
        file_in="${file_in%%\"*}"
        sanitize_file_in
        file_in="${file_in%.mp4}"_$(date +%Y-%m-%d)_dalle_$(date +%H-%M-%S)__prog_inizio_${rai_start_time//\:/-}_durata_${rai_duration_time//\:/-}

	if [ -n "$rai_duration_time" ]
	then
	    print_c 4 "Diretta Rai dalle $rai_start_time per la durata di $rai_duration_time"
	    livestream_m3u8="$url_in_file"
	else
	    [ -n "$gui_alive" ] &&
		check_linksloop_livestream ||
		    _log 43
	fi
	
    else
        if [[ "$url_in" =~ \/programmi\/ ]]
        then
            raiplay_item_path=$(curl -s "${url_in}.json")
            raiplay_item_path="${raiplay_item_path#*\"first_item_path\" \: \"}"
            raiplay_item_path="${raiplay_item_path%%\"*}"
            test -n "${raiplay_item_path}" &&
                raiplay_item_path="https://www.raiplay.it${raiplay_item_path}"

            url "${raiplay_item_path}" &&
                replace_url_in "${raiplay_item_path}"
        fi
        raiplay_json=$(curl -s "${url_in//html/json}" -c "$path_tmp"/cookies.zdl)

        raiplay_url="${raiplay_json#*content_url\": \"}"
        raiplay_url="${raiplay_url%%\"*}"
        
        if url "$raiplay_url"
        then
            countdown- 120
            raiplay_url=$(get_location "$raiplay_url")

            if url "$raiplay_url"
            then
                url_in_file=$(curl -v "$raiplay_url" |tail -n1)
            else
                _log 45
            fi
        fi

        file_in="${raiplay_json#*name\": \"}"
        file_in="${file_in%%\"*}"
    fi
        
    downwait_extra=20

    end_extension
fi
									   

