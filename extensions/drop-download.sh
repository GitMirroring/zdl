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
## zdl-extension types: download
## zdl-extension name: Drop.download

if [[ "$url_in" =~ drop\.download ]]
then
    get_language_prog
    location_drop=$(curl -v \
                         -c "$path_tmp"/cookies.zdl \
                         "$url_in" 2>&1 |
                        awk "/location/{print \$3}")
    get_language
    location_drop=$(trim "$location_drop")

    if url "$location_drop"
    then
        _log 34 "$location_drop"

        # html=$(curl -v \
        #             -A "$user_agent" \
        #             -b "$path_tmp"/cookies.zdl \
        #             -c "$path_tmp"/cookies2.zdl \
        #             -H "Connection: keep-alive" \
        #             -H "Upgrade-Insecure-Requests: 1" \
        #             -H "Sec-Fetch-Dest: document" \
        #             -H "Sec-Fetch-Mode: navigate" \
        #             -H "Sec-Fetch-Site: cross-site" \
        #             -H "Cache-Control: max-age=0" \
        #             -H "TE: trailers" \
        #             "$location_drop" 2>&1)
        html=$(curl -v \
                    -A "$user_agent" \
                    -b "$path_tmp"/cookies.zdl \
                    -c "$path_tmp"/cookies2.zdl \
                    -H "Connection: keep-alive" \
                    -H "Upgrade-Insecure-Requests: 1" \
                    -H "Sec-Fetch-Dest: document" \
                    -H "Sec-Fetch-Mode: navigate" \
                    -H "Sec-Fetch-Site: none" \
                    -H "Sec-Fetch-User: ?1" \
                    -H "TE: trailers" \
                    "$location_drop" 2>&1)

        input_hidden "$html"
        post_data="${post_data}&method_free=Free+Download+%3E%3E"

        html=$(curl -v \
                    -A "$user_agent" \
                    -b "$path_tmp"/cookies2.zdl \
                    -c "$path_tmp"/cookies.zdl \
                    -H "Origin: https://drop.download" \
                    -H "Connection: keep-alive" \
                    -H "Referer: $location_drop" \
                    -H "Upgrade-Insecure-Requests: 1" \
                    -H "Sec-Fetch-Dest: document" \
                    -H "Sec-Fetch-Mode: navigate" \
                    -H "Sec-Fetch-Site: same-origin" \
                    -H "Sec-Fetch-User: ?1" \
                    -d "$post_data" \
                    "$location_drop" 2>&1)

        # html=$(wget -SO -  \
        #             --user-agent="$user_agent" \
        #             --load-cookies="$path_tmp"/cookies2.zdl \
        #             --save-cookies="$path_tmp"/cookies.zdl \
        #             --header="Origin: https://drop.download" \
        #             --header="Connection: keep-alive" \
        #             --header="Referer: $location_drop" \
        #             --header="Upgrade-Insecure-Requests: 1" \
        #             --header="Sec-Fetch-Dest: document" \
        #             --header="Sec-Fetch-Mode: navigate" \
        #             --header="Sec-Fetch-Site: same-origin" \
        #             --header="Sec-Fetch-User: ?1" \
        #             --post-data="$post_data" \
        #             "$location_drop" 2>&1)

        drop_unpacked=$(unpack "$(grep 'p,a,c,k,e' <<<  "$html" | tail -n1)")

        url_in_file="${drop_unpacked##*\<param name\=\"src\"value\=\"}"
        url_in_file="${url_in_file%%\"*}"

        if ! url "$url_in_file"
        then
            captcha_code=$(pseudo_captcha "$html")
            
            input_hidden "$html"
            
            post_data="${post_data%%Free Download*}Free+Download+%3E%3E&method_premium=&adblock_detected=0&code=$captcha_code"
            html=$(curl -v \
                        -A "$user_agent" \
                        -b "$path_tmp"/cookies.zdl \
                        -c "$path_tmp"/cookies2.zdl \
                        -H "Connection: keep-alive" \
                        -H "Upgrade-Insecure-Requests: 1" \
                        -H "Sec-Fetch-Dest: document" \
                        -H "Sec-Fetch-Mode: navigate" \
                        -H "Sec-Fetch-Site: same-origin" \
                        -H "Sec-Fetch-User: ?1" \
                        -H "TE: trailers" \
                        -d "$post_data" \
                        "$location_drop" 2>&1)

            url_in_file=$(grep 'Click here to download' <<< "$html" -B1 | head -n1)
            url_in_file="${url_in_file#*\"}"
            url_in_file="${url_in_file%%\"*}"
            
        fi        
    fi
    end_extension
fi
