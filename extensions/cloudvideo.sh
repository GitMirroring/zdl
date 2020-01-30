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
## zdl-extension types: streaming
## zdl-extension name: Cloudvideo (HD)


if [[ "$url_in" =~ cloudvideo\. ]]
then    
    html=$(curl -s "$url_in" \
		-c "$path_tmp"/cookies.zdl)
    url_in_file=$(grep -oP '[^"]+\.m3u8' <<< "$html")
    file_in=$(get_title "$html")
    file_in="${file_in#Watch\ }"
    file_filter "$file_in"

    if ! url "$url_in_file"
    then
        input_hidden "$html"

        html=$(curl -s "$url_in" \
                    -A "$user_agnet" \
                    -d "$post_data" \
		    -c "$path_tmp"/cookies.zdl)

        url_in_file=$(grep -oP '[^"]+\.m3u8' <<< "$html")
    fi

    #downwait_extra=20
    
    end_extension
fi
