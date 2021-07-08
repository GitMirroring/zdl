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
## zdl-extension name: playtube


if [ "$url_in" != "${url_in//playtube.}" ] && [ 1 == 2 ] ## <-- clausola per disattivare l'estensione: ancora non funziona
then
    html=$(curl -s                         \
		-A "$user_agent"           \
		"$url_in"                  \
                -c "$path_tmp"/cookies1.zdl)

    file_in=$(grep '<h3' <<< "$html")
    file_in="${file_in#*>}"
    file_in="${file_in%<*}"
    
    # url_in_file=$(unpack "$html")
    # url_in_file="${url_in_file#*file\:\"}"
    # url_in_file="${url_in_file%%\"*}"

    url_html2=$(grep '/dl?op' <<< "$html")
    url_html2="${url_html2#*\"}"
    url_html2="${url_html2%%\"*}"

    ## grep -P "('file_id'|'aff'|'ref_url')" <<< "$html"
    file_id=$(grep '$.cookie' <<< "$html" |grep file_id)
    file_id="${file_id%\'*}"
    file_id="${file_id##*\'}"

    aff=$(grep '$.cookie' <<< "$html" |grep aff)
    aff="${aff%\'*}"
    aff="${aff##*\'}"
    ref_url=$(urlencode "https://playtube.ws${url_html2}") 
    ref_url="${ref_url//\:/%3A}"
    ref_url="${ref_url//\&/%26}"
    ref_url="${ref_url//\=/%3D}"
    ref_url="${ref_url//\?/%3F}"

    while :
    do
        html2=$(curl -s \
                     "https://playtube.ws${url_html2}" \
                     -A "$user_agent"           \
                     -c "$path_tmp"/cookies2.zdl \
                     -H "Cookie: file_id=$file_id; aff=$aff;" \
                     -H "Connection: keep-alive" \
                     -H "Upgrade-Insecure-Requests: 1")
        
        url_in_file=$(grep location.href <<<"$html2" |
                          sed -r "s|[^']+'([^']+)'.+|\1|g")

        url "$url_in_file" && break
        sleep 1
    done


    
    curl -v \
         "$url_in_file" \
         -A "$user_agent"           \
         -b "$path_tmp"/cookies2.zdl \
         -c "$path_tmp"/cookies.zdl \
         -H "Connection: keep-alive" \
         -H "Cookie: file_id=$file_id; aff=$aff; ref_url=$ref_url;" \
         -H "Upgrade-Insecure-Requests: 1" 2>&1

    grep '$.cookie' <<< "$html2"
    end_extension
fi
