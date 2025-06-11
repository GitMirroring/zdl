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
## zdl-extension name: Dropload

if [ "$url_in" != "${url_in//dropload}" ] &&
       [[ ! "$url_in" =~ \.mp4 ]]
then
    if [[ "$url_in" =~ \/(e|d)\/ ]]
    then
        replace_url_in "${url_in//${BASH_REMATCH[1]}\//embed-}"
    fi
    
    html=$(curl -s "${url_in//embed-/e/}")

    url_in_file=$(grep -oP 'sources\:\[\{file\:\"[^"]+' <<< "$(unpack "$html")")
    url_in_file="${url_in_file#*\"}"

    file_in=$(grep -B1 videoplayer-controlbar <<< "$html" |
                  head -n1)
    
    file_in="${file_in#*<h1>}"
    file_in="${file_in%</h1>*}"

    if [ -z "$file_in" ]
    then
        file_in_html=$(curl -s "${url_in//embed-/d/}")
        file_in=$(grep 'card-header' -A1 <<< "$file_in_html" | tail -n1)
        file_in="${file_in##*Download}"
        file_in="${file_in##\ }"

        if [ -z "$file_in" ]
        then
            file_in=$(grep 'text-white' -A1 <<< "$file_in_html" | tail -n1)
            file_in="${file_in##*Download}"
            file_in=$(sed -r 's|\s*(.+)|\1|g' <<< "$file_in")
        fi
    fi
    
    sanitize_file_in
    force_dler FFMpeg 
    end_extension
fi
