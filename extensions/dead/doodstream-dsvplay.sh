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
## zdl-extension name: DoodStream/DSVPlay

if [[ "$url_in" =~ (doodstream|dsvplay). ]]
then
    [[ "$url_in" =~ doodstream ]] &&
        replace_url_in "${url_in//doodstream/dsvplay}"

    html=$(curl -s \
                -A "$user_agent" \
                -c "$path_tmp"/cookies.zdl \
                -H 'Upgrade-Insecure-Requests: 1' \
                "${url_in}")

    dood_url_in=$(grep -oP '\/download\/[^"]+' <<< "$html")
    dood_url_in="https://dsvplay.com${dood_url_in}"
    echo        "$dood_url_in"

    dood_id="${url_in##*\/}"
    dood_hash="${dood_url_in##*\/}"

# headers+=( 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: it,en-US;q=0.7,en;q=0.3
# Accept-Encoding: gzip, deflate, br, zstd
# DNT: 1
# Sec-GPC: 1
# Connection: keep-alive
# Cookie: lang=1
# Upgrade-Insecure-Requests: 1
# Sec-Fetch-Dest: document
# Sec-Fetch-Mode: navigate
# Sec-Fetch-Site: same-origin
# Sec-Fetch-User: ?1' )

#file_in=out.mp4
#url_in_file="$dood_url_in"


 curl -v \
                -A "$user_agent" \
                -b "$path_tmp"/cookies.zdl \
                -d "op=download_orig&id=${dood_id}&mode=o&hash=${dood_hash}" \
                -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: it,en-US;q=0.7,en;q=0.3
DNT: 1
Sec-GPC: 1
Connection: keep-alive
Cookie: lang=1
Upgrade-Insecure-Requests: 1
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: same-origin
Sec-Fetch-User: ?1' "$dood_url_in" 2>&1

#     html=$(wget -o /dev/null -qO- \
#                 --user-agent="$user_agent" \
#                 --keep-session-cookies \
#                 --load-cookies="$path_tmp"/cookies.zdl \
#                 --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: it,en-US;q=0.7,en;q=0.3
# Accept-Encoding: gzip, deflate, br, zstd
# DNT: 1
# Sec-GPC: 1
# Connection: keep-alive
# Cookie: lang=1
# Upgrade-Insecure-Requests: 1
# Sec-Fetch-Dest: document
# Sec-Fetch-Mode: navigate
# Sec-Fetch-Site: same-origin
# Sec-Fetch-User: ?1' \
#                 "$dood_url_in")
#    rm -rf out.html
#    countdown- 5
#     aria2c 		    -U "$user_agent" --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: it,en-US;q=0.7,en;q=0.3
# Accept-Encoding: gzip, deflate, br, zstd
# DNT: 1
# Sec-GPC: 1
# Connection: keep-alive
# Cookie: lang=1
# Upgrade-Insecure-Requests: 1
# Sec-Fetch-Dest: document
# Sec-Fetch-Mode: navigate
# Sec-Fetch-Site: same-origin
# Sec-Fetch-User: ?1' \
#            --load-cookies="$path_tmp/cookies.zdl" \
#            "${dood_url_in}" -o out.html
    
#    aria2c -U "$user_agent" --load-cookies="$path_tmp/cookies.zdl" "${dood_url_in}" -o out.html
    #cat out.html
 
#     # &dl=false" 
# echo "$html"
    # grep 'This link will expire' < out.html


#    url_in_file="$dood_url_in"
    
    #url_in_file=$(grep -oP 'href=\"[^"]+' < out.html | tail -n1)
    #url_in_file="${url_in_file#href=\"}"
#    file_in=out.mp4

    
# <Form name="F1" method="POST" action="" onSubmit="if($('#btn_download').prop('disabled'))return false;$('#btn_download').val('');$('#btn_download').prop('disabled',true);return true;">
# <input type="hidden" name="op" value="download_orig">
# <input type="hidden" name="id" value="mapyo60dzzdk">
# <input type="hidden" name="mode" value="o">
# <input type="hidden" name="hash" value="231847497-151-48-1762110345-7c6bcad217aa425a6dc65d885fa57503">

# <input type="submit" name="dl" id="btn_download" value="" style="width:200px;border:1px solid #303030;padding:5px;">

# </Form>

# headers+=( 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: it,en-US;q=0.7,en;q=0.3
# Accept-Encoding: gzip, deflate, br, zstd
# DNT: 1
# Sec-GPC: 1
# Connection: keep-alive
# Referer: https://dsvplay.com/
# Upgrade-Insecure-Requests: 1
# Sec-Fetch-Dest: document
# Sec-Fetch-Mode: navigate
# Sec-Fetch-Site: cross-site
# Sec-Fetch-User: ?1
# Priority: u=0, i' '' "op=download_orig&id=${dood_id}&mode=o&hash=${dood_hash}&dl=1" )
# <br><a href="https://doodstream.com/mapyo60dzzdk">Back to file</a>
    
#     url_in_file=$(grep -oP 'http[^"]+\.mp4[^"]*' <<< "$html")
#     url_in_file="${url_in_file//amp;}"
    
#     file_in=$(get_title "$html")
#     file_in="${file_in#Watch }"
#     [ -n "$file_in" ] && file_in="${file_in%.mp4}".mp4

#     headers+=( 'DNT: 1
# Connection: keep-alive
# Upgrade-Insecure-Requests: 1
# Sec-Fetch-Dest: video
# Sec-Fetch-Mode: cors
# Sec-Fetch-Site: same-origin
# Sec-GPC: 1' )
     no_check_links+=( "$url_in")
    
    end_extension
fi
