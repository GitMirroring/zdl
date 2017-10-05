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
## zdl-extension name: Raptu.com/Rapidvideo.com (HD)

if [[ "$url_in" =~ (raptu|rapidvideo)\.com ]]
then
    html=$(curl -A "$user_agent" "$url_in" 2>&1)
    
    if grep 'We are sorry' <<< "$html" &>/dev/null
    then
	_log 3

    else	
	if grep -P 'q=1080p' <<< "$html" >/dev/null
	then
	    html=$(curl -A "$user_agent" "${url_in}&q=1080p" 2>&1)
	    
	elif grep -P 'q=720p' <<< "$html" >/dev/null
	then
	    html=$(curl -A "$user_agent" "${url_in}&q=720p" 2>&1)
	    
	fi

	url_in_file=$(grep source <<< "$html" | tr -d '\\' |tail -n1)
	url_in_file="${url_in_file#*\"}"
	url_in_file="${url_in_file%%\"*}"

	file_in=$(get_title "$html")."${url_in_file##*.}"
	
	end_extension
    fi
fi
