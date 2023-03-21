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
## zdl-extension types: streaming
## zdl-extension name: MuseoGalileo.it


if [[ "$url_in" =~ (catalogo\.museogalileo\.it\/multimedia) ]]
then
    html=$(curl -s "$url_in")
               
    url_in_file="$(grep -oP 'source.+video\.museogalileo[^"]+' <<< "$html")"
    url_in_file="${url_in_file#*\"}"
    file_in="$(get_title "$html")"
    if [ -n "$file_in" ]
    then
        file_in="$file_in".mp4
        sanitize_file_in
    fi
    
    end_extension

elif [[ "$url_in" =~ (museogalileo\.it) ]]
then
    html=$(curl -s "$url_in")
    html=$(grep pathVideoBase <<< "$html" | head -n1)

    if [[ "$html" =~ \"(.+)\" ]]
    then
        museogalileo_url="https:${BASH_REMATCH[1]}"

        if url "$museogalileo_url"
        then
            replace_url_in "${museogalileo_url}"
        fi
    else
        _log 3
    fi    
fi
