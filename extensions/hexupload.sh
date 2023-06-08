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
    if [[ "$url_in" =~ ^(https\:\/\/hexupload) ]]
    then
        replace_url_in "${url_in//\/\//'//www.'}"
    fi
    
    html=$(curl -sk \
                -A "$user_agent" \
                -c "$path_tmp"/cookies.zdl \
                "$url_in")

    if [[ "$html" =~ (No such file with this filename|File Not Found) ]]
    then
        _log 3
        
    else
        input_hidden "$html"
        post_data="${post_data}&method_free=Free Download"
        post_data="${post_data//+/%2B}"

        url_in_file="$url_in"

        if [[ "$test_mime_hexupload" =~ \.(mkv|avi|mp4|MKV|AVI|MP4) ]]
        then
            get_language
            force_dler Wget
            get_language_prog

        else
            countdown- 5
            html2=$(curl -sk     \
	                 -A "$user_agent"    \
		         -d "$post_data"    \
                         -b "$path_tmp"/cookies.zdl \
                         -c "$path_tmp"/cookies2.zdl \
		         "$url_in")

            input_hidden "$html2"
            post_data="${post_data%adblock_detected*}"
            post_data="${post_data%'&'}&adblock_detected=0"

            html3=$(curl -sk    \
	                 -A "$user_agent"    \
		         -d "$post_data"    \
                         -b "$path_tmp"/cookies2.zdl \
                         -c "$path_tmp"/cookies.zdl \
		         "$url_in")

            if grep -q 'ldl.ld(' <<< "$html3"
            then
                url_in_file_coded64=$(grep 'ldl.ld(' <<< "$html3")
                url_in_file_coded64="${url_in_file_coded64#*\'}"
                url_in_file_coded64="${url_in_file_coded64%%\'*}"

                ## javascript function atob()
                ## -> pipe of stdout to "base64 -d" = "decode 64":
                url_in_file=$(echo "${url_in_file_coded64}" | base64 -d)

                ## javascript function btoa()
                ## -> pipe of stdout to "base64 -e" = "encode 64"

            else                
                if [[ "$html3" =~ "404 Not Found" ]]
                then
                    _log 8
                    
                elif [[ "$html3" =~ "You have reached the download-limit" ]]
                then
                    _log 25
                fi

                url_in_file=$(grep -P '(Download Now|Click Here To Download)' <<< "$html3")
                url_in_file="${url_in_file#*href=\"}"
                url_in_file="${url_in_file%%\"*}"
            fi
        fi

        sanitize_url "$url_in_file" url_in_file

        if ! url "$url_in_file"
        then
            hex_id="${url_in#*\/\/}"
            hex_id="${hex_id#*\/}"
            hex_id="${hex_id%%\/*}"

            hex_link=$(curl -ks \
                            -d "op=download1&id=${hex_id}&rand=&usr_login=&fname=${file_in}&ajax=1&method_free=1&dataType=json" \
                            "https://hexupload.net/download")

            url_in_file="${hex_link#*link\":\"}"
            url_in_file=$(echo "${url_in_file%%\"*}" | base64 -d)
        fi

        test_url_in_file || {
            _log 28
        }

        end_extension
    fi
fi

