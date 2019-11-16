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
## zdl-extension name: Deltabit (HD)

function add_deltabit_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/deltabit-definitions
}

function del_deltabit_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/deltabit-definitions
}

function get_deltabit_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/deltabit-definitions
    then
	ref=$(grep -P "^$url_in (o|n|l){1}$" "$path_tmp"/deltabit-definitions |
		     cut -f2 -d' ')
    fi
}

if [[ "$url_in" =~ deltabit ]] 
then
    unset html html2 movie_definition
    
    if [ -z "$(grep -v deltabit "$path_tmp/links_loop.txt" &>/dev/null)" ]
    then
	get_language
        dbmsg_0="$(gettext "Cookies deleted")"
    	print_c 1 "$dbmsg_0"
	get_language_prog	
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
	download_video=$(grep -P 'download_video.+Download' <<< "$html" |head -n1)

	hash_deltabit="${download_video%\'*}"
	hash_deltabit="${hash_deltabit##*\'}"

	id_deltabit="${download_video#*download_video\(\'}"
	id_deltabit="${id_deltabit%%\'*}"

	declare -A movie_definition
	movie_definition=(
	    ['o']="Original"
	    ['n']="Normal"
	    ['l']="Low"
	)

	grep -P "download_video.+','o','.+Download" <<< "$html" &>/dev/null &&
	    o=o

	## file_in:
	input_hidden "$html"
	file_filter "$file_in"
	
	for mode_stream in $o n l
	do
	    get_deltabit_definition mode_stream_test

	    [ -n "$mode_stream_test" ] &&
		mode_stream="$mode_stream_test"

	    get_language
            dbmsg_1="$(gettext "Audio/video definition")"
	    print_c 2 "$dbmsg_1: ${movie_definition[$mode_stream]}"
	    get_language_prog
	    
	    deltabit_loops=0
	    while ! url "$url_in_file" &&
		    ((deltabit_loops < 2))
	    do
		((deltabit_loops++))
		html2=$(wget -qO- -t1 -T$max_waiting           \
			     "http://deltabit.co/dl?op=download_orig&id=${id_deltabit}&mode=${mode_stream}&hash=${hash_deltabit}" \
			     -o /dev/null)

		url_in_file=$(grep -P 'http.+Download' <<< "$html2" |
				     sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

		((deltabit_loops < 2)) && sleep 1
	    done

	    if ! url "$url_in_file" &&
		    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
	    then
		url_in_timer=$((${BASH_REMATCH[1]} * 60))
		set_link_timer "$url_in" $url_in_timer
		_log 33 $url_in_timer

		add_deltabit_definition $mode_stream
		break

	    elif url "$url_in_file"
	    then
		get_language
                sbmsg_2="$(gettext "The movie with %s definition is available")"
		print_c 1 "$dbmsg_2" "${movie_definition[$mode_stream]}"
		get_language_prog	
		set_deltabit_definition $mode_stream
		break

	    else
		get_language
                dbmsg_2="$(gettext "The movie with %s definition is not available")"
		print_c 3 "$dbmsg_2" "${movie_definition[$mode_stream]}"
		get_language_prog	
		del_deltabit_definition $mode_stream
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

	[ -z "$url_in_timer" ] &&
	    end_extension ||
		unset url_in_timer
    fi
fi
