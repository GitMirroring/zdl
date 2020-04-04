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
## zdl-extension name: Supervideo (HD)

function add_supervideo_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/supervideo-definitions
}

function del_supervideo_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/supervideo-definitions
}

function get_supervideo_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/supervideo-definitions
    then
        ref=$(grep -P "^$url_in (o|n|l){1}$" "$path_tmp"/supervideo-definitions |
                     cut -f2 -d' ')
    fi
}

if [[ "$url_in" =~ supervideo ]] 
then
    unset html html2 movie_definition
    
    if [ -z "$(grep -v supervideo "$path_tmp/links_loop.txt" &>/dev/null)" ]
    then
        get_language
        svmsg_0="$(gettext "Cookies deleted")"
        print_c 1 "$svmsg_0" 
        get_language_prog       
        rm -rf "$path_tmp/cookies.zdl"           
    fi
    
    html=$(wget -t1 -T$max_waiting                               \
                "$url_in"                                        \
                --user-agent="$user_agent"                       \
                --keep-session-cookies                           \
                --save-cookies="$path_tmp/cookies.zdl"           \
                -qO- -o /dev/null)

    if [[ "$html" =~ (The file was deleted|File Not Found|File doesn\'t exits) ]]
    then
        _log 3

    else
        input_hidden "$html"

        declare -A movie_definition
        movie_definition=(
            ['o']="Original"
            ['h']="High"
            ['n']="Normal"
            ['l']="Low"
        )

        for mode_stream in o h n l
        do
            get_supervideo_definition mode_stream_test
            [ -n "$mode_stream_test" ] &&
                mode_stream="$mode_stream_test"

            download_video=$(grep -P "download_video\(.+'$mode_stream'" <<< "$html")

            hash_supervideo="${download_video%\'*}"
            hash_supervideo="${hash_supervideo##*\'}"
            
            id_supervideo="${download_video#*download_video\(\'}"
            id_supervideo="${id_supervideo%%\'*}"

            get_language
            svmsg_1="$(gettext "Audio/video definition")"
            print_c 2 "$svmsg_1: ${movie_definition[$mode_stream]}"
            get_language_prog

            supervideo_loops=0
            while ! url "$url_in_file" &&
                    ((supervideo_loops < 2))
            do
                ((supervideo_loops++))
                html2=$(wget -qO- -t1 -T$max_waiting           \
                             "http://supervideo.tv/dl?op=download_orig&id=${id_supervideo}&mode=${mode_stream}&hash=${hash_supervideo}" \
                             -o /dev/null)

                url_in_file=$(grep -P 'class.+btn_direct-download' <<< "$html2" |
                                  head -n1                                      |
                                  sed -r 's|.+href=\"([^"]+)\".+|\1|g')

                ((supervideo_loops < 2)) && sleep 1
            done

            if ! url "$url_in_file" &&
                    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
            then
                url_in_timer=$((${BASH_REMATCH[1]} * 60))
                set_link_timer "$url_in" $url_in_timer
                _log 33 $url_in_timer

                add_supervideo_definition $mode_stream
                break

            elif url "$url_in_file"
            then
                get_language
                svmsg_2="$(gettext "The movie with %s definition is available")"
                print_c 1 "$svmsg_2" "${movie_definition[$mode_stream]}"
                get_language_prog       
                set_supervideo_definition $mode_stream
                break

            else
                get_language
                svmsg_2="$(gettext "The movie with %s definition is not available")"
                print_c 3 "$svmsg_2" "${movie_definition[$mode_stream]}"
                get_language_prog       
                del_supervideo_definition $mode_stream
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

if [[ "$url_in" =~ supervideo ]] &&
       ! url "$url_in_file"
then
    
    html=$(curl -s "${url_in//embed-}")

    if grep -q 'Video is processing now' <<< "$html"
    then
        _log 17

    else
        url_in_file=$(grep sources <<< "$html" |
                          sed -r 's|[^"]+\"([^"]+).+|\1|')
        file_in=$(grep '<h2' <<< "$html" |head -n1)
        file_in="${file_in#*<h2>}"
    fi
    end_extension
fi
