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
## zdl-extension name: ok.ru

if [[ "$url_in" =~ ok\.ru\/video ]]
then
    [[ "$url_in" =~ ok\.ru\/video\/ ]] &&
        replace_url_in "${url_in//video/videoembed}"
    
    html=$(curl -s \
                -A "$user_agent" \
                -b "$path_tmp"/cookies.zdl \
                -c "$path_tmp"/cookies2.zdl \
                -H 'Upgrade-Insecure-Requests: 1' \
                "$url_in")

    # url_in_file=$(sed -r 's|&quot;|\n|g' <<< "$html" |
    #                   sed -r 's|u0026|\&|g' |
    #                   grep m3u8 |
    #                   tr -d \\)

    # force_dler FFMpeg

    url_in_file=$(sed -r 's|&quot;|\n|g' <<< "$html" |
                      sed -r 's|u0026|\&|g'          |
                      grep -P '^http'                |
                      grep 'type=1'                  |
                      grep -v 'ch='                  |
                      tr -d \\)
    
    file_in=$(get_title "$html")

    [ -n "$file_in" ] && file_in="${file_in%.mp4}".mp4

    file_in="${file_in#*&quot}"
    no_check_links+=( "$url_in")

    end_extension
fi
