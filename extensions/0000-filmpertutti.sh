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
        local linker_fpt=$(curl -s "$1" |
                               grep -oP '[^"]+protectlinker[^"]+')
        
        if url "$linker_fpt"
        then
            get_language
            while read url_fpt 
            do
	        if url "$url_fpt"
	        then
                    [ -z "$url_in_start" ] &&
                        url_in_start="$url_fpt"
                    
	            set_link + "$url_fpt"
	            print_c 4 "$(gettext "Redirection"): $url_fpt"
	        fi
                
            done < <(curl -s "$linker_fpt" | grep -oP 'meta-link=\"http[^ ]+' | grep -oP 'http[^"]+')
        fi
    fi
}

if [[ "$url_in" =~ (filmpertutti|fpt)\. ]]
then
    get_language_prog

    if [[ "$url_in" =~ show_video ]]
    then
        extract_filmpertutti "$url_in"

    else
        while read url_fpt 
        do
	    if url "$url_fpt"
	    then
	        extract_filmpertutti "$url_fpt"
	    fi
        done < <(curl -s "$url_in" | grep -oP '[^"]+show_video=true[^"]+' | sed -r 's|\#038\;||g')
    
    fi
    
    get_language    
    if url "$url_in_start"
    then
	replace_url_in "$url_in_start"
        unset url_in_start
	print_c 4 "$(gettext "New link to process"): $url_in"
    fi
fi

