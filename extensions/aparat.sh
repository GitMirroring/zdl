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
## zdl-extension name: Aparat (HD)

function add_aparat_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/aparat-definitions
}

function del_aparat_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/aparat-definitions
}

function get_aparat_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/aparat-definitions
    then
	ref=$(grep -P "^$url_in (o|h|n|l){1}$" "$path_tmp"/aparat-definitions |
		     cut -f2 -d' ')
    fi
}

if [[ "$url_in" =~ aparat\. ]]
then
    if check_cloudflare "$url_in"
    then
        get_by_cloudflare "$url_in" html

    else
        html=$(curl -s "$url_in" \
                    -c "$path_tmp/cookies.zdl")

        [ -s "$html" ] &&
            html=$(wget -qO- -o /dev/null \
                        "$url_in" \
                        --keep-session-cookies \
                        --save-cookies="$path_tmp/cookies.zdl")
    fi

    if [[ "$html" =~ (The file was deleted|File Not Found|File doesn\'t exists) ]]
    then
	_log 3        
    fi

    if ! url "$url_in_file" ||
            [ -z "$file_in" ] 
    then
        download_video=$(grep -P 'download_video' <<< "$html" |head -n1)

        hash_aparat="${download_video%\'*}"
        hash_aparat="${hash_aparat##*\'}"

        id_aparat="${download_video#*download_video\(\'}"
        id_aparat="${id_aparat%%\'*}"

        declare -A movie_definition
        movie_definition=(
            ['o']="Original"
            ['h']="High"
            ['n']="Normal"
            ['l']="Low"
        )

        unset o
        grep -P "download_video.+','o','.+Original" <<< "$html" &>/dev/null &&
            o=o

        for mode_stream in $o h n l
        do
            get_aparat_definition mode_stream_test

            [ -n "$mode_stream_test" ] &&
        	mode_stream="$mode_stream_test"

            print_c 2 "$(gettext "Audio/video definition"): ${movie_definition[$mode_stream]}"
	    
            aparat_loops=0
            while ! url "$url_in_file" &&
        	    ((aparat_loops < 2))
            do
        	((aparat_loops++))

        	get_language_prog
        	html2=$(curl -s \
        		     "https://aparat.cam/dl?op=download_orig&id=${id_aparat}&mode=${mode_stream}&hash=${hash_aparat}" \
                             -A "$user_agent" \
                             -b "$path_tmp/cookies.zdl")
                [ -n "$html2" ] ||
        	    html2=$(wget -qO- -o /dev/null \
        		         "https://aparat.cam/dl?op=download_orig&id=${id_aparat}&mode=${mode_stream}&hash=${hash_aparat}" \
                                 --user-agent="$user_agent" \
                                 --load-cookies="$path_tmp/cookies.zdl")

        	get_language

        	url_in_file=$(grep -B1 'Direct Download' <<< "$html2" |
        			  head -n1 |
        			  sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')

        	! url "$url_in_file" &&
        	    url_in_file=$(grep 'Direct Download' <<< "$html2" |
        			      sed -r 's|[^f]+href=\"([^"]+)\".+|\1|g')
                url_in_file=$(sanitize_url "$url_in_file")

        	((aparat_loops < 2)) && sleep 1
            done

            if ! url "$url_in_file" &&
        	    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
            then
        	url_in_timer=$((${BASH_REMATCH[1]} * 60))
        	set_link_timer "$url_in" $url_in_timer
        	_log 33 $url_in_timer

        	add_aparat_definition $mode_stream
        	break

            elif url "$url_in_file"
            then
        	print_c 1 "$(gettext "The movie with %s definition is available")" "${movie_definition[$mode_stream]}" 
        	set_aparat_definition $mode_stream
        	break

            else
        	print_c 3 "$(gettext "The movie with %s definition is not available")" "${movie_definition[$mode_stream]}" 
        	del_aparat_definition $mode_stream
            fi
        done
    fi

    if ! url "$url_in_file" 
    then
        url_in_file=$(grep 'sources:' <<< "$html")
        url_in_file="${url_in_file#*\"}"
        url_in_file="${url_in_file%%\"*}"
    fi
    
    if [ -z "$file_in" ]
    then
        file_in=$(get_title "$html")
        file_in="${file_in#Watch }"
    fi

    # if check_youtube-dl && (
    #         ! url "$url_in_file" ||
    #             [ -z "$file_in" ]
    #     )
    # then
    #     html=$(youtube-dl --get-url --get-filename "$url_in")
    #     url_in_file=$(head -n1 <<< "$html")
    #     file_in=$(tail -n1 <<< "$html")
    # fi

    ! url "$url_in_file" && [[ "$html" =~ (Video is processing now) ]] && _log 17
    
    end_extension
fi

