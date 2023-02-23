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
## zdl-extension name: StreamHide


if [ "$url_in" != "${url_in//streamhide}" ]
then
    #### streaming: youtube-dl
    ytdl_old="$youtube_dl"
    ytdl_new=$(zwhich youtube-dl)
    if [ -f "$ytdl_new" ]
    then
        youtube_dl="$ytdl_new"
    fi
    streamhide_data=$($youtube_dl --get-url --get-filename "$url_in")

    file_in=$(tail -n1 <<< "$streamhide_data")
    file_in="${file_in#Watch_}"

    url_in_file=$(head -n1 <<< "$streamhide_data")

    youtube_dl="$ytdl_old"
    
    force_dler FFMpeg

    #### download: google re-captcha
    # replace_url_in "${url_in//\/w\///d/}_x"
    
    # html=$(curl -s \
    #             -c "$path_tmp"/cookies.zdl \
    #             "$url_in")

    # input_hidden "$html"
    # html=$(curl -s \
    #             -c "$path_tmp"/cookies.zdl \
    #             -d "$post_data" \
    #             "$url_in")

    if ! url "$url_in_file"
    then
        html=$(curl -s "$url_in")
        url_in_file=$(unpack "$html")
        url_in_file="${url_in_file#*file:\"}"
        url_in_file="${url_in_file%%\"*}"
        file_in=$(grep "h4 mb-3 text-white" <<< "$html")
        file_in="${file_in%<*}"
        file_in="${file_in##*>}".mp4
       
        sanitize_file_in
    fi
    
    end_extension
fi
