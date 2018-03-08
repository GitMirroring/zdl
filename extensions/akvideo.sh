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
## zdl-extension types: streaming download
## zdl-extension name: Akvideo (HD)

function add_akvideo_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/akvideo-definitions
}

function del_akvideo_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/akvideo-definitions
}

function get_akvideo_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/akvideo-definitions
    then
	ref=$(grep -P "^$url_in (o|h|n|l){1}$" "$path_tmp"/akvideo-definitions |
		     cut -f2 -d' ')
    fi
}

if [[ "$url_in" =~ akvideo ]] 
then
    unset html html2 movie_definition
    
    if [ -z "$(grep -v akvideo "$path_tmp/links_loop.txt" &>/dev/null)" ]
    then
    	print_c 1 "Cookies cancellati"
    	rm -rf "$path_tmp/cookies.zdl"           
    fi
    
    html=$(wget -t1 -T$max_waiting                               \
    		"$url_in"                                        \
    		--user-agent="Firefox"                           \
    		--keep-session-cookies                           \
    		--save-cookies="$path_tmp/cookies.zdl"           \
    		-qO- -o /dev/null)

    if [[ "$html" =~ (The file was deleted|File Not Found|File doesn\'t exits) ]]
    then
	_log 3

    else
	download_video=$(grep -P 'download_video' <<< "$html" |head -n1)

	hash_akvideo="${download_video%\'*}"
	hash_akvideo="${hash_akvideo##*\'}"

	id_akvideo="${download_video#*download_video\(\'}"
	id_akvideo="${id_akvideo%%\'*}"

	declare -A movie_definition
	movie_definition=(
	    ['o']="Original"
	    ['h']="High"
	    ['n']="Normal"
	    ['l']="Low"
	)

	grep -P "download_video.+','o','.+Original" <<< "$html" &>/dev/null &&
	    o=o

	## file_in:
	input_hidden "$html"
						       
	for mode_stream in $o h n l
	do
	    get_akvideo_definition mode_stream_test

	    [ -n "$mode_stream_test" ] &&
		mode_stream="$mode_stream_test"

	    print_c 2 "Filmato con definizione ${movie_definition[$mode_stream]}..."
	    
	    akvideo_loops=0
	    while ! url "$url_in_file" &&
		    ((akvideo_loops < 2))
	    do
		((akvideo_loops++))

		html2=$(wget -qO- -t1 -T$max_waiting           \
			     "https://akvideo.stream/dl?op=download_orig&id=${id_akvideo}&mode=${mode_stream}&hash=${hash_akvideo}" \
			     -o /dev/null)

		url_in_file=$(grep -B1 'Direct Download' <<< "$html2" |
				     head -n1 |
				     sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')

		! url "$url_in_file" &&
		    url_in_file=$(grep 'Direct Download' <<< "$html2" |
					 sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')

		((akvideo_loops < 2)) && sleep 1
	    done

	    if ! url "$url_in_file" &&
		    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
	    then
		url_in_timer=$((${BASH_REMATCH[1]} * 60))
		set_link_timer "$url_in" $url_in_timer
		_log 33 $url_in_timer

		add_akvideo_definition $mode_stream
		break

	    elif url "$url_in_file"
	    then
		print_c 1 "Disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
		set_akvideo_definition $mode_stream
		break

	    else
		print_c 3 "Non è disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
		del_akvideo_definition $mode_stream
	    fi
	done
	
	if url "$url_in_file"
	then
	    url_in_file="${url_in_file//https\:/http:}"

	    if [ -z "$file_in" ]
	    then
		file_in="${url_in_file##*\/}"
		file_in="${file_in%\&file_id=*}"
	    fi
	fi

	max_dl=$(cat "$path_tmp/max-dl" 2>/dev/null)
	(( max_dl > 1 )) &&
	    set_temp_proxy
	
	[ -z "$url_in_timer" ] &&
	    end_extension ||
		unset url_in_timer
    fi
fi
