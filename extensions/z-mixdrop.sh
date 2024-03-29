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
## zdl-extension name: MixDrop

if [ "$url_in" != "${url_in//mixdrp}" ]
then
    replace_url_in "${url_in//mixdrp/mixdrop}"
fi

if ! url "$url_in_file" ||
        test -z "$file_in"
then        
    test_mixdrop=$(grep -oP 'https://[^\/]+' <<< "$url_in")
    get_location "$test_mixdrop" test_mixdrop

else
    unset test_mixdrop
fi

if [[ "${url_in}${test_mixdrop}" =~ (mixdr[o]*p) ]]
then
echo "test: ${test_mixdrop}"    
    mixdrop_url_in=$(curl -s "${url_in//\/f\///e/}" | grep -P 'iframe.+src=\"\/\/mixdrop')
    mixdrop_url_in="${mixdrop_url_in#*src=\"}"
    mixdrop_url_in="https:${mixdrop_url_in%%\"*}"    

    html=$(curl -s \
                -A "$user_agent" \
                -H 'Connection: keep-alive' \
                -H 'Upgrade-Insecure-Requests: 1' \
                -c "$path_tmp"/cookies.zdl \
                "$url_in")
    
    if ! grep -q 'p,a,c,k,e,d' <<< "$html"
    then    
        for i in {0..3}
        do
            get_location "$mixdrop_url_in" mixdrop_location
            url "$mixdrop_location" && break
            countdown- 6
        done
    fi
    
    if test -z "$file_in" 
    then    
        file_in=$(get_title "$html")
        file_in="${file_in%%.mp4*}"
    fi
    
    if url "$mixdrop_location"
    then
        mixdrop_url_in="$mixdrop_location"
    else
        mixdrop_url_in="$url_in"
    fi    

    if ! grep -q 'p,a,c,k,e,d' <<< "$html"
    then
        html=$(curl -s \
                    -A "$user_agent" \
                    -H 'Connection: keep-alive' \
                    -H 'Upgrade-Insecure-Requests: 1' \
                    -c "$path_tmp"/cookies.zdl \
                    "$mixdrop_url_in")
    fi
    
    if test -z "$file_in" 
    then    
        file_in=$(get_title "$html")
        file_in="${file_in%%.mp4*}"
    fi
    
    if [[ "$html" =~ (WE ARE SORRY) ]]
    then
        _log 3

    else
        if [[ "$html" =~ window.location\ \=\ \"([^\"]+)\" ]]
        then
            mixdrop_chunk="${BASH_REMATCH[1]}"
            
            if [ -n "${mixdrop_chunk}" ]
            then
                html=$(curl -s "https://mixdrop.co${mixdrop_chunk}" \
                            -c "$path_tmp"/cookies.zdl)
                if test -z "$file_in" 
                then
                    file_in=$(get_title "$html")
                    file_in="${file_in%%.mp4*}"
                fi
            fi
        fi

        if grep -q 'p,a,c,k,e,d' <<< "$html"
        then
            mixdrop_iframe_url="$mixdrop_url_in"

        else
            mixdrop_iframe_url=$(grep iframe <<< "$html")
            mixdrop_iframe_url="${mixdrop_iframe_url#*src=\"}"
            mixdrop_iframe_url="${mixdrop_iframe_url%%\"*}"

            [ -n "$mixdrop_iframe_url" ] &&
                [[ ! "$mixdrop_iframe_url" =~ http ]] &&
                mixdrop_iframe_url="https:${mixdrop_iframe_url#https:}"
        fi

        html=$(curl -s \
                    -A "$user_agent" \
                    -H 'Connection: keep-alive' \
                    -H 'Upgrade-Insecure-Requests: 1' \
                    -c "$path_tmp"/cookies.zdl \
                    "$mixdrop_iframe_url")

        if test -z "$file_in" 
        then
            file_in=$(get_title "$html")
            file_in="${file_in%%.mp4*}"
        fi
        
        if [[ "$html" =~ window.location\ \=\ \"([^\"]+)\" ]]
        then
            mixdrop_chunk="${BASH_REMATCH[1]}"

            if [ -n "${mixdrop_chunk}" ]
            then
                html=$(curl -s "https://mixdrop.co${mixdrop_chunk}" \
                            -c "$path_tmp"/cookies.zdl)
            fi
        fi

        if test -z "$file_in" 
        then
            file_in=$(get_title "$html")
            file_in="${file_in%%.mp4*}"
        fi

        if test -z "$file_in"
        then
            file_in=$(grep 'class="title"' <<< "$html")
            file_in="${file_in%</a>*}"
            file_in="${file_in##*>}"
            file_in="${file_in## }"
        fi
        
        unpacked=$(unpack "$(grep 'p,a,c,k,e,d' <<< "$html" |head -n1)")

        if [[ "$unpacked" =~ MDCore\.[a-z]*url\=\"([^\"]+\.mp4[^\"]+)\" ]]
        then
            url_in_file="https:${BASH_REMATCH[1]}"

        elif [[ "${html}" =~ (Video will be converted and ready to play soon) ]]
        then
            _log 17
        fi
        
        if [[ "$file_in" =~ ^[0-9]+\-(.+$) ]]
        then
            file_in="${BASH_REMATCH[1]}"
        fi
        
        if test -z "$file_in" 
        then
            file_in="mixdrop-${url_in##*\/}"
        fi
        
    fi            

    end_extension
fi

