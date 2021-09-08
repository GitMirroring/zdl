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
## zdl-extension name: Hexupload


if [ "$url_in" != "${url_in//hexupload.}" ]
then
    html=$(wget -qO- -t 1 -T $max_waiting                \
		--user-agent="$user_agent"               \
		"$url_in"                                \
		-o /dev/null)
    
    if [[ "$html" =~ "File Not Found" ]]
    then
        _log 3
        
    else
        input_hidden "$html"
        post_data="${post_data}&method_free=Free Download"

        url_in_file="$url_in"
        test_mime_hexupload=$(set_ext "$path_tmp/out")
        rm -f "$path_tmp/out"
        
        if [[ "$test_mime_hexupload" =~ \.(mkv|avi|mp4) ]]
        then
            get_language
            force_dler Wget
            get_language_prog

        else
            html2=$(wget -SO-                                                    \
		         --user-agent="$user_agent"                              \
		         --post-data="${post_data}&method_free=Free Download"    \
		         "$url_in"                                               \
		         -o /dev/null)

            input_hidden "$html2"

            post_data="${post_data%adblock_detected*}adblock_detected=0"

            html3=$(wget -qO-                          \
		         --user-agent="$user_agent"    \
		         --post-data="${post_data}"    \
		         "$url_in"                     \
		         -o /dev/null)

            if [[ "$html3" =~ "404 Not Found" ]]
            then
                _log 8
            fi

            url_in_file=$(grep 'Click Here To Download' <<< "$html3")
            url_in_file="${url_in_file#*href=\"}"
            url_in_file="${url_in_file%%\"*}"
        fi
        test_url_in_file || {
            _log 28
        }

        end_extension
    fi
fi
