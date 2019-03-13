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
    html=$(wget --user-agent="$user_agent" -qO- "$url_in" -o /dev/null)    
    echo "$html" >TEST

    raiplay_subtitle=$(grep vodJson <<< "$html")
    raiplay_subtitle="${raiplay_subtitle#*'vodJson='}"
    raiplay_subtitle="${raiplay_subtitle%%';</script>'*}"

    #### non sicuro: serve una sandbox
    ## file_in=$(nodejs -e "var json = $raiplay_subtitle; console.log(json.name + ' - ' + json.subtitle);")

    json_name="${raiplay_subtitle##*\"name\":\"}"
    json_name=$(trim "${json_name%%\"*}")
    json_subtitle="${raiplay_subtitle##*\"subtitle\":\"}"
    json_subtitle=$(trim "${json_subtitle%%\"*}")

    if [ -n "$json_name" ]
    then
	file_in="$json_name"

	if [ -n "$json_subtitle" ]
	then
	   file_in="$file_in - $json_subtitle"
	fi
	
    else
	file_in=$(get_title "$html" | tr -d '\n' | tr -d '\r')
    fi
    file_in="${file_in#Film\: }"

    url_raiplay=$(grep data-video-url <<< "$html" |
		 sed -r 's|.+data-video-url=\"([^"]+)\".+|\1|g')

    if url "$url_raiplay"
    then
	url_raiplay_location=$(get_location "$url_raiplay")
	if url "$url_raiplay_location"
	then
	    url_raiplay="$url_raiplay_location"

	elif [ -n "$ffmpeg" ]
	then
	    url_raiplay_mpd=$(curl "$url_raiplay")
	    url_raiplay_mpd="${url_raiplay_mpd//\(/%28}"
	    url_raiplay_mpd="${url_raiplay_mpd//\)/%29}"

	    if url "$url_raiplay_mpd" &&
		    [[ "$url_raiplay_mpd" =~ (\.mpd\?) ]] &&		    
		    "$ffmpeg" 2>&1 | grep libxml2 &>/dev/null
	    then
		url_in_file="$url_raiplay_mpd"
	    else
		_log 41
	    fi

	else
	    _log 42
	fi
    else
	url_raiplay=$(grep contentUrl <<< "$html" |
			  sed -r 's|.+contentUrl\"\:\"([^"]+)\".+|\1|g')
    fi

    if ! url "$url_in_file"
    then
	url_in_file=$(wget -qO- "$url_raiplay" \
			   --user-agent="$user_agent" \
			   --save-cookies="$path_tmp/cookies.zdl" \
			   -o /dev/null)
	
	url_in_file=$(tail -n1 <<< "$url_in_file")
    fi
    
    downwait_extra=20
fi
									   

