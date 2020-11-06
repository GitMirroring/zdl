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
## zdl-extension name: Youtube

if [[ "$url_in" =~ youtube\.com\/playlist ]]
then
    #html=$(curl -s "$url_in")
    yt_json=$(youtube-dl --dump-json "$url_in")
    while read yt_link
    do
        if url "$yt_link"
        then
            set_link + "$yt_link" && print_c 4 "$(gettext "Redirection"): $yt_link"
            [[ "$url_in" =~ youtube.com\/playlist ]] && replace_url_in "$yt_link"
        fi
    done < <(grep -oP '[^"]+youtube\.com\/watch[^"]+' <<< "$yt_json")
#    done < <(awk '/data-video-id/{match($0, /data-video-id=\"([^"]+)\"/,m); if(m[1]) print "https://www.youtube.com/watch?v=" m[1]}' <<< "$html")
fi

if [ "$url_in" != "${url_in//'youtube.com/watch'}" ]
then
    html=$(curl -v "$url_in")
    replace_url_in "$(urldecode "${url_in%%'&'*}")"    

    if check_connection &&
	    [ -z "$html" ]
    then
    	_log 8 

    elif [[ "$html" =~ 'Questo video include contenuti di UMG che sono stati bloccati dallo stesso proprietario per motivi di copyright' ]] ||
	     [[ "$html" =~ 'This video contains content from UMG, who has blocked it on copyright grounds' ]]
    then
	_log 3
	
    elif [[ "$html" =~ \<title\>(.+)\<\/title\> ]]
    then
    	title=$(sed -r 's/([^0-9a-z])+/_/ig' <<< "${BASH_REMATCH[1]}" |
    		       sed -r 's/_youtube//ig'                        |
    		       sed -r 's/^_//ig'                              |
    		       tr '[A-Z]' '[a-z]'                             |
    		       sed -r 's/_amp//ig')

	if command -v youtube-dl &>/dev/null
	then
	    data=$(youtube-dl --get-url -f best --get-filename "${url_in}")
	    file_in="$(tail -n1 <<< "$data")"
	    file_in="${file_in% _ *}"
	    
	    if [[ "$file_in" =~ ^(_|\ )\- ]]
	    then
		file_in="${title}${file_in}"
	    fi
	    url_in_file="$(tail -n2 <<< "$data" | head -n1)"

	    if ! url "$url_in_file"
	    then
		unset file_in url_in_file
	    fi
	fi

	if ! url "$url_in_file"
	then
	    url_in_file=$(wget -t3 -T10 \
			       -qO- \
			       "http://zoninoz.altervista.org/api.php?uri=$url_in" \
			       -o /dev/null |
				 tail -n1)
	    
	    wget --spider -S "$url_in_file" -o "$path_tmp"/videoType.yt

	    if [ -s "$path_tmp"/videoType.yt ]
	    then
		videoType=$(grep 'Content-Type:' "$path_tmp"/videoType.yt)
		videoType="${videoType##*\/}"
	    fi

	    if [ -n "$videoType" ]
	    then
		file_in="$title.$videoType"
		rm -f "$path_tmp"/videoType.yt
	    fi
	fi

	if [ "$downloader_in" == "Axel" ] &&
	       [ -n "$(axel -o /dev/null "$url_in_file" | grep '403 Forbidden')" ]
	then
	    force_dler "Wget"
	fi

	if [[ "$url_in_file" =~ (Age check) ]]
	then
	    _log 19
	else
	    axel_parts=4
	fi
	
    elif check_connection
    then
    	_log 9
    	not_available=true
    fi

    end_extension
fi
