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
## zdl-extension name: StreamTape


if [[ "$url_in" =~ streamtape\. ]]
then
    html=$(curl -s "$url_in")
    url_in_file=$(grep -P 'videolink.+innerHTML' <<< "$html")
    url_in_file="${url_in_file#*= \"}"
    url_in_file="${url_in_file%%\"*}"

    # url_in_file=$(grep 'id="videolink"' <<< "$html")
    # url_in_file="${url_in_file%<*}"
    # url_in_file="${url_in_file##*>}"
    [[ "$url_in_file" =~ ^http ]] ||
            url_in_file="https:${url_in_file}"

    get_location "$url_in_file" url_in_file
    file_in=$(get_title "$html")

    end_extension
fi
