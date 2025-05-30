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

if [[ "$url_in" =~ supervideo ]] 
then
    unset html html2 movie_definition
        
    html=$(wget -t1 -T$max_waiting                               \
                "${url_in//embed-}"                              \
                --user-agent="$user_agent"                       \
                --keep-session-cookies                           \
                --save-cookies="$path_tmp/cookies.zdl"           \
                -qO- -o /dev/null)

    if [[ "$html" =~ (The file was deleted|File Not Found|File doesn\'t exits) ]]
    then
        _log 3

    else
        supervideo_data=$(unpack "$html")
        
        url_in_file="${supervideo_data#*\{file\:\"}"
        url_in_file="${url_in_file%%\"*}"

        file_in="${html##*<title>}"
        file_in="${file_in%%<\/title>*}"
        file_in="${file_in##*Watch}"
        file_in="${file_in##\ }"
        file_in=$(head -n1 <<< "$file_in")
        file_in="${file_in%%\ }".mp4

        get_language
        force_dler FFMpeg
        get_language_prog
        
        end_extension
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
