#!/bin/bash
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

## zdl-extension types: shortlinks
## zdl-extension name: filmpertutti

function extract_filmpertutti {
    local url_fpt

    if url "$1"
    then
        get_language_prog
        local html=$(curl -s "$1")
        get_language
        
        grep -oP 'data-link=\"[^"]+' <<< "$html" |
            grep -v '<!--' |
            grep http |
            sed -r 's|data-link\=\"(.+)|\1|g'
    fi
}

if [[ "$url_in" =~ (filmpertutti|fpt)\. ]]
then
    if [[ "$url_in" =~ \/stream\/ ]]
    then
        for fpt_link in $(extract_filmpertutti "$url_in")
        do
            if url "$fpt_link"
            then
                [ -z "$start_fpt_link" ] && start_fpt_link="$fpt_link"

                _log 34 "$fpt_link"
                set_link + "$fpt_link"
            fi            
        done

        [ -n "$start_fpt_link" ] && replace_url_in "$start_fpt_link"
    fi
fi

