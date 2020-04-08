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
## zdl-extension name: Backin

function check_backin {
    if data_stdout
    then    
        for ((i=0; i<${#url_out[@]}; i++))
        do
            if check_pid "${pid_out[i]}" &&
                    [[ "${url_out[i]}" =~ backin ]]
            then
                return 1
            fi
        done
    fi    
    return 0    
}

if [[ "$url_in" =~ backin ]] &&
       [[ ! "$url_in" =~ \/d\/ ]]
then
    link_parser "$url_in"
    # backin_url="$parser_proto$parser_domain/s/generating.php?code=${parser_path##*\/}"
    backin_url="$url_in"
    get_language

    if url "$backin_url"
    then
        #print_c 4 "$(gettext "Redirection"): $backin_url"

        if check_cloudflare "$backin_url"
        then
            get_language_prog
            get_by_cloudflare "$backin_url" html

            backin_location=$(tail -n1 <<< "$html")
            url "$backin_location" &&
                [[ ! "$backin_location" =~ backin\.net$ ]] &&
                replace_url_in "$backin_location"

            input_hidden "$html"
            [[ "$post_data" =~ \=1$ ]] && post_data="${post_data%1}"0
            get_by_cloudflare "$url_in" html "$post_data"

            backin_cookies=$(head -n20 <<< "$html" |
                                 grep -P '(__cfduid|cf_clearance)' |
                                 sed -r 's|.+=> (.+)$|\1|g')
            echo -e "$backin_cookies" > "$path_tmp"/cookies.zdl
            get_language
        else
            get_language_prog
            html=$(wget -o /dev/null -qO- "$backin_url")
            get_language
        fi
        
        file_in=$(get_title "$html")
        file_in="${file_in#Streaming }"
        file_in="${file_in#Download }"
        file_in="${file_in%mp4}"
        file_in="${file_in%\.}"
        file_filter "$file_in"

        if grep -q 'p,a,c,k,e,d' <<< "$html"
        then
            url_in_file=$(unpack "$(grep 'p,a,c,k,e,d' <<< "$html" |head -n2 |tail -n1)")
            url_in_file="${url_in_file#*file\:\"}"
            url_in_file="${url_in_file%%\"*}"

        else
            backin_url=http://backin.net$(grep 'top.location.href' <<< "$html" |
                             tail -n1 |
                             sed -r 's|.+\"([^"]+)\".+|\1|g')

            input_hidden "$html"
            [[ "$post_data" =~ \=1$ ]] && post_data="${post_data%1}"0
            get_by_cloudflare "$backin_url" html "$post_data"

            backin_cookies=$(head -n20 <<< "$html" |
                                 grep -P '(__cfduid|cf_clearance)' |
                                 sed -r 's|.+=> (.+)$|\1|g')
            echo -e "$backin_cookies" > "$path_tmp"/cookies.zdl
            get_language

            if grep -q 'p,a,c,k,e,d' <<< "$html"
            then
                url_in_file=$(unpack "$(grep 'p,a,c,k,e,d' <<< "$html" |head -n2 |tail -n1)")

                if grep -q 'file:' <<< "$url_in_file"
                then
                    url_in_file="${url_in_file#*file\:\"}"
                else
                    url_in_file="${url_in_file#*\"src\"value=\"}"
                fi
                url_in_file="${url_in_file%%\"*}"

            fi                    
        fi
    fi
    end_extension
fi
