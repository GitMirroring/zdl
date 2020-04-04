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

## zdl-extension types: download
## zdl-extension name: MixDrop

if [[ "$url_in" =~ mixdrop\. ]]
then
    [[ "$url_in" =~ \/f\/ ]] &&
        replace_url_in "${url_in//\/f\///e/}"

    html=$(curl -s \
                -A "$user_agent" \
                -H 'Connection: keep-alive' \
                -H 'Upgrade-Insecure-Requests: 1' \
                -c "$path_tmp"/cookies.zdl \
                "$url_in")

    file_in=$(grep title <<< "$html")
    file_in="${file_in%</a>*}"
    file_in="${file_in##*>}"

    if [ -z "$file_in" ]
    then
        file_in=$(get_title "$html")
    fi

    unpacked=$(unpack "$(grep 'p,a,c,k,e,d' <<< "$html" |head -n1)")

    if [[ "$unpacked" =~ MDCore\.furl\=\" ]]
    then
        url_in_file="http:${unpacked#*furl=\"}"
        url_in_file="${url_in_file%%\"*}"

    elif [[ "${html}" =~ (Video will be converted and ready to play soon) ]]
    then
        _log 17
    fi
    
    if ! url "$url_in_file" &&
            [[ "$unpacked" =~ MDCore\.wurl\=\" ]]
    then
        url_in_file="http:${unpacked#*wurl=\"}"
        url_in_file="${url_in_file%%\"*}"
    fi

    if [ -z "$file_in" ]
    then
        file_in="mixdrop-${url_in##*\/}"
    fi
    
    end_extension
fi

