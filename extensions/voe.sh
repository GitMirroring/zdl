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
## zdl-extension name: Voe

if [[ "$url_in" =~ voe\. ]]
then
    html=$(curl -s \
                -A "$user_agent" \
                -b "$path_tmp"/cookies.zdl \
                -c "$path_tmp"/cookies2.zdl \
                -H 'Upgrade-Insecure-Requests: 1' \
                "${url_in%\/download}/download")

    voe_location=$(grep "window.location.href = '" <<< "$html" |
                       head -n1 |
                       grep -oP "http[^']+")

    html=$(curl -s \
                -A "$user_agent" \
                -b "$path_tmp"/cookies.zdl \
                -c "$path_tmp"/cookies2.zdl \
                -H 'Upgrade-Insecure-Requests: 1' \
                "$voe_location")
    
    url_in_file=$(grep -oP 'http[^"]+\.mp4[^"]*' <<< "$html")
    
    file_in=$(get_title "$html")
    file_in="${file_in#Watch }"
    [ -n "$file_in" ] && file_in="${file_in%.mp4}".mp4

        headers+=( 'Sec-Fetch-Dest: video
Sec-Fetch-Mode: cors
Sec-Fetch-Site: cross-site' )
    no_check_links+=( "$url_in")
    
    end_extension
fi
