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
## zdl-extension name: StreamSB/SBFull (+ browser to solve g-recaptcha)

function add_sbdomain_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/sbdomain-definitions
}

function del_sbdomain_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/sbdomain-definitions
}

function get_sbdomain_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/sbdomain-definitions
    then
	ref=$(grep -P "^$url_in (o|h|n|l){1}$" "$path_tmp"/sbdomain-definitions |
		     cut -f2 -d' ')
    fi
}


if [[ "$url_in" =~ (streamsb|sbfull|sblongvu)\. ]]
then
    sbdomain=${BASH_REMATCH[1]}
    
    if [[ ! "$url_in" =~ \/d\/ ]]
    then
        replace_url_in "${url_in//${sbdomain}.com\//${sbdomain}.com\/d\/}"
    fi

    html=$(curl -s \
                -A "$user_agent" \
                -c "$path_tmp"/cookies.zdl \
                "$url_in")
    
    file_in=$(get_title "$html")
    
    download_video=$(grep -P 'download_video' <<< "$html" |head -n1)

    hash_sbdomain="${download_video%\'*}"
    hash_sbdomain="${hash_sbdomain##*\'}"

    id_sbdomain="${download_video#*download_video\(\'}"
    id_sbdomain="${id_sbdomain%%\'*}"

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
    file_filter "$file_in"
    
    for mode_stream in $o h n l
    do
        get_sbdomain_definition mode_stream_test
        
        [ -n "$mode_stream_test" ] &&
            mode_stream="$mode_stream_test"

        print_c 2 "$(gettext "Audio/video definition"): ${movie_definition[$mode_stream]}"
	
        # sbdomain_loops=0
        # while ! url "$url_in_file" &&
        #         ((sbdomain_loops < 2))
        # do
        #     ((sbdomain_loops++))

        get_language_prog

        html2=$(curl -s "https://${sbdomain}.com/dl?op=view&id=${id_sbdomain}&mode=${mode_stream}&hash=${hash_sbdomain}")
        
        # html2=$(wget -qO- -t1 -T$max_waiting           \
            # 	     "https://sbdomain.tv/dl?op=download_orig&id=${id_sbdomain}&mode=${mode_stream}&hash=${hash_sbdomain}" \
            # 	     -o /dev/null)
        
        html2=$(curl -s \
                     -A "$user_agent" \
                     -b "$path_tmp"/cookies.zdl \
                     -c "$path_tmp"/cookies2.zdl \
                     "https://${sbdomain}.com/dl?op=download_orig&id=${id_sbdomain}&mode=${mode_stream}&hash=${hash_sbdomain}")
        cat "$path_tmp"/cookies2.zdl >> "$path_tmp"/cookies.zdl

        get_language  
        
        if grep -q hidden <<< "$html2"
        then
            if command -v "$browser" &>/dev/null
            then
                $browser "https://${sbdomain}.com/dl?op=download_orig&id=${id_sbdomain}&mode=${mode_stream}&hash=${hash_sbdomain}"
            fi
            # input_hidden "$html2"

            # echo "POST: $post_data"
            
            # html3=$(curl -s \
                #          -A "$user_agent" \
                #          -b "$path_tmp"/cookies.zdl \
                #          -c "$path_tmp"/cookies2.zdl \
                #          -d "$post_data" \
                #          "$url_in")

            # echo "$html3"
            break
        fi

        #     ((sbdomain_loops < 2)) && sleep 1
        # done

        # if ! url "$url_in_file" &&
        #         [[ "$html2" =~ 'have to wait '([0-9]+) ]]
        # then
        #     url_in_timer=$((${BASH_REMATCH[1]} * 60))
        #     set_link_timer "$url_in" $url_in_timer
        #     _log 33 $url_in_timer

        #     add_sbdomain_definition $mode_stream
        #     break

        # elif url "$url_in_file"
        # then
        #     print_c 1 "$(gettext "The movie with %s definition is available")" "${movie_definition[$mode_stream]}" 
        #     set_sbdomain_definition $mode_stream
        #     break

        # else
        #     print_c 3 "$(gettext "The movie with %s definition is not available")" "${movie_definition[$mode_stream]}" 
        #     del_sbdomain_definition $mode_stream
        # fi
    done

    _log 36
fi

