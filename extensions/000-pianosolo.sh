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

## zdl-extension types: streaming shortlinks
## zdl-extension name: pianosolo.it

if [[ "$url_in" =~ pianosolo\.it ]]
then
    pianosolo_urls=$(curl -s "$url_in" |
                         grep -oP '[^"]+youtube.com\\/watch[^"]+' |
                         tr -d '\\')

    while read pianosolo_url
    do
        if url "$pianosolo_url"
        then
            set_link + "$pianosolo_url"
            get_language
            print_c 4 "$(gettext "Redirection"): $url_in -> $pianosolo_url"
            get_language_prog
                
        else
            _log 2
        fi
        
    done <<< "$pianosolo_urls"

    if url "$pianosolo_url"
    then
        set_link - "$url_in"
        url_in="$pianosolo_url"
        unset pianosolo_url
    fi
fi

