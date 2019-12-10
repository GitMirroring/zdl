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

## zdl-extension types: streaming download
## zdl-extension name: Onlystream

function add_onlystream_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/onlystream-definitions
}

function del_onlystream_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/onlystream-definitions
}

function get_onlystream_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/onlystream-definitions
    then
	ref=$(grep -P "^$url_in (o|h|n|l){1}$" "$path_tmp"/onlystream-definitions |
		     cut -f2 -d' ')
    fi
}


if [[ "$url_in" =~ onlystream\. ]]
then
    if command -v youtube-dl &>/dev/null
    then
        html=$(youtube-dl --get-url --get-filename "$url_in")
	url_in_file=$(head -n1 <<< "$html")
	file_in=$(tail -n1 <<< "$html")
    fi

    if ! url "$url_in_file" ||
            [ -z "$file_in" ] 
    then
        if check_cloudflare "$url_in"
        then
            get_by_cloudflare "$url_in" html
            
        else
            html=$(curl "$url_in")
        fi
        
        if [[ "$html" =~ (The file was deleted|File Not Found|File doesn\'t exists) ]]
        then
	    _log 3
            
        elif [[ "$html" =~ (Video is processing now) ]]
        then
	    _log 17
        fi
    fi

    if ! url "$url_in_file" ||
            [ -z "$file_in" ] 
    then
        url_in_file=$(grep 'player.updateSrc' <<< "$html")
        url_in_file="${url_in_file#*\"}"
        url_in_file="${url_in_file%%\"*}"

        file_in=$(get_title "$html")
        
        # download_video=$(grep -P 'download_video' <<< "$html" |head -n1)

        # hash_onlystream="${download_video%\'*}"
        # hash_onlystream="${hash_onlystream##*\'}"

        # id_onlystream="${download_video#*download_video\(\'}"
        # id_onlystream="${id_onlystream%%\'*}"

        # declare -A movie_definition
        # movie_definition=(
        #     ['o']="Original"
        #     ['h']="High"
        #     ['n']="Normal"
        #     ['l']="Low"
        # )

        # grep -P "download_video.+','o','.+Original" <<< "$html" &>/dev/null &&
        #     o=o

        # ## file_in:
        # input_hidden "$html"
        # file_filter "$file_in"
	
        # for mode_stream in $o h n l
        # do
        #     get_onlystream_definition mode_stream_test

        #     [ -n "$mode_stream_test" ] &&
        # 	mode_stream="$mode_stream_test"

        #     print_c 2 "$(gettext "Audio/video definition"): ${movie_definition[$mode_stream]}"
	    
        #     onlystream_loops=0
        #     while ! url "$url_in_file" &&
        # 	    ((onlystream_loops < 2))
        #     do
        # 	((onlystream_loops++))

        # 	get_language_prog
        # 	html2=$(curl           \
        # 		     "https://onlystream.tv/dl?op=view&id=${id_onlystream}&mode=${mode_stream}&hash=${hash_onlystream}" \
        # 		     -o /dev/null)
        # 	# html2=$(wget -qO- -t1 -T$max_waiting           \
        # 	# 	     "https://onlystream.tv/dl?op=download_orig&id=${id_onlystream}&mode=${mode_stream}&hash=${hash_onlystream}" \
        # 	# 	     -o /dev/null)
        # 	get_language
		
        # 	url_in_file=$(grep -B1 'Direct Download' <<< "$html2" |
        # 			  head -n1 |
        # 			  sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')

        # 	! url "$url_in_file" &&
        # 	    url_in_file=$(grep 'Direct Download' <<< "$html2" |
        # 			      sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')

        # 	((onlystream_loops < 2)) && sleep 1
        #     done

        #     if ! url "$url_in_file" &&
        # 	    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
        #     then
        # 	url_in_timer=$((${BASH_REMATCH[1]} * 60))
        # 	set_link_timer "$url_in" $url_in_timer
        # 	_log 33 $url_in_timer

        # 	add_onlystream_definition $mode_stream
        # 	break

        #     elif url "$url_in_file"
        #     then
        # 	print_c 1 "$(gettext "The movie with %s definition is available")" "${movie_definition[$mode_stream]}" 
        # 	set_onlystream_definition $mode_stream
        # 	break

        #     else
        # 	print_c 3 "$(gettext "The movie with %s definition is not available")" "${movie_definition[$mode_stream]}" 
        # 	del_onlystream_definition $mode_stream
        #     fi
        # done

        
    fi
    
    end_extension
fi

