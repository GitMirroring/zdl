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

## zdl-extension types: shortlinks
## zdl-extension name: isecure, protectlinker

if [[ "$url_in" =~ (isecure|protectlinker)\. ]]
then
    html=$(curl -s "$url_in")

    data_link=$(grep -P 'iframe[. ]+src' <<< "$html" |
                      grep -oP 'http[^"]+' |
                      tail -n1)
    
    sanitize_url "$data_link" data_link
    
    if url "$data_link" &&
            [ "$data_link" != "$url_in" ]
    then
        replace_url_in "$data_link"
        
    else
        if [[ "$url_in" =~ protectlinker\. ]]
        then
            data_links=( $(grep -oP 'meta-link="[^"]+' <<< "$html" |
                             sed -r 's|meta-link=\"||g') )
            
            if url "${data_links[0]}" 
            then
                for data_link in "${data_links[@]}"
                do
                    if url "$data_link"
                    then
                        set_link + "$data_link"
                        print_c 4 "$data_link"
                    fi
                done

                replace_url_in "${data_links[0]}"
            else
                _log 3
            fi

        else
	    _log 3
        fi
    fi
fi
