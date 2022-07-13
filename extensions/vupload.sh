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
## zdl-extension name: Vupload

if [ "$url_in" == "https://vupload.com/embed-.html" ] ||
       [ "$url_in" == "https://vupload.com/.html" ]
then
    _log 3

elif [ "$url_in" != "${url_in//vupload.}" ]
then
    replace_url_in "${url_in//embed-}"

    html=$(curl -s \
                -A "$user_agent" \
                "$url_in")
    
    file_in=$(grep 'og:title' <<< "$html")
    file_in="${file_in%\"*}"
    file_in="${file_in##*\"}"
    file_in="${file_in#*\-}"

    url_in_file_0=$(grep .m3u8 <<< "$html")
    url_in_file_0="${url_in_file_0#*\"}"
    url_in_file_0="${url_in_file_0%%\"*}"

    url_in_file=$(curl -s \
                -A "$user_agent" \
                -b "$path_tmp"/cookies.zdl \
                "$url_in_file_0")

    url_in_file=$(head -n5 <<< "$url_in_file"|
                      tail -n1)

    if ! url "$url_in_file"
    then
        url_in_file="$url_in_file_0"
    fi
    
    get_language
    force_dler FFMpeg
    get_language_prog
    youtubedl_m3u8="$url_in_file"
    
    end_extension
fi

