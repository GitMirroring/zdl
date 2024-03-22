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
## zdl-extension name: Filemoon


if [ "$url_in" != "${url_in//'filemoon'}" ]
then    
    if [[ "$url_in" =~ \/e\/ ]]
    then
        replace_url_in "${url_in//\/e\///d/}"
    fi
    
    html=$(curl -s "$url_in")

    file_in=$(get_title "$html")

    packed=$(grep 'p,a,c,k,e,d' <<< "$html" | tail -n1)

    if grep 'File was deleted' <<< "$html" &>/dev/null
    then
        _log 3

    else
        unpacked=$(unpack "$packed")
	
        url_in_file="${unpacked#*file\:\"}"
        url_in_file="${url_in_file%%\"*}"

        if [ -n "$file_in" ]
        then
            file_in="${file_in#Watch }.mp4"
        fi
        
        force_dler FFMpeg

        end_extension
    fi
fi
