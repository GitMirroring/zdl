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
## zdl-extension name: Dplay (HD)


if [[ "$url_in" =~ dplay\. ]]
then
    html=$(wget --user-agent="$user_agent" -qO- "$url_in" -o /dev/null)    

    # dplayJSON=$(grep 'JSON.parse' <<< "$html")
    # dplayJSON=${dplayJSON#*\"}
    # dplayJSON=${dplayJSON%\"*}
    # dplayJSON=$(echo -e "$dplayJSON" | tr -d '\')

    # url_in_file=$(nodejs -e "var json = $dplayJSON; console.log(json.data.attributes.streaming.hls.url)")
    # __in_file=$(curl -s "$url_in_file" |tail -n1)

    # if grep -q URI <<< "$__in_file"
    # then
    #     unset url_in_file file_in
    #     _log 32
	
    # else 
    #     url_in_file=$(sed -r "s|[^/]+m3u8|$__in_file|g" <<< "$url_in_file") 
    # fi
    
    ## file_in="${url_in%\/*}"
    ## file_in="${file_in##*\/}"

    if ! url "$url_in_file"
    then
	dplay_data=$(youtube-dl --get-url \
				--get-filename \
				"$url_in" \
				2>/dev/null)
	
	# file_in=$(tail -n1 <<< "$dplay_data")
	# file_in="${file_in%.mp4}"

	url_in_file=$(head -n1 <<< "$dplay_data")

	## problema permessi, usiamo `youtube-dl --hls-prefer-ffmpeg`:
	youtubedl_m3u8="$url_in"
    fi

    file_in="$(get_title "$html" | sed -r 's/\ \|\ Dplay\ *$//g')$(grep episode-season-title -A2 <<< "$html" | tail -n1 | sed -r 's|^\ *||g')"
    file_filter "$file_in"

    end_extension
fi
									   

