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
## zdl-extension name: Flashx.tv


if [ "$url_in" != "${url_in//flashx.}" ]
then
    html=$(wget -SO- \
		--user-agent="$user_agent" \
		--keep-session-cookies \
		--save-cookies=$path_tmp/cookies.zdl \
		"$url_in")

    #echo "$html" >TEST
#    sed -r 's|(\$\.cookie.+)\;$|console.log(\1);|g' -i TEST
#    sed -r "s|(^.+cookie\('aff.+$)|\1\nconsole.log(document.cookie);|g" -i TEST
    #url_flashx=$(grep Location <<< "$html" |head -n1 |cut -d' ' -f2)

    input_hidden "$html"
    post_data+="&imhuman=Proceed to video"

    url_action=$(grep -P 'POST.+action' <<< "$html" |
			sed -r 's|.+action=\"([^"]+)\".+|\1|g')

    cookie_code=$(grep -P '\.cookie\(' <<< "$html")

    cookie_file_id=$(grep 'file_id' <<< "$cookie_code" |
			    cut -d"'" -f4)
    cookie_aff=$(grep 'aff' <<< "$cookie_code" |
			cut -d"'" -f4)

    cookie_string="aff=${cookie_aff}; file_id=${cookie_file_id}"
    cookie_vars_js="var aff=${cookie_aff}; 
var file_id=${cookie_file_id};"

    #sed -r "s|^.+cookie\('([^']+)', '([^']+)'.+|\1 = \"\2\";|g" -i TEST

    # echo "$cookie_code"
    # echo "$cookie_string"

    #phantomjs --cookies-file=$path_tmp/cookies.zdl "$path_usr"/extensions/flashx.js TEST
    
    countdown- 5
    html=$(curl -v \
		-D headers-dump \
		-A "$user_agent" \
    		-b "$path_tmp"/cookies.zdl \
		-c "$path_tmp"/cookies2.zdl \
		-H "Cookie: \"$cookie_string\"" \
    		-d "$post_data" \
    		"$url_action")

    html=$(grep 'p,a,c,k,e,d' <<< "$html" |head -n1)    
    js_unpacked=$(unpack "$html")
    
    # html=$(grep 'p,a,c,k,e,d' <<< "$html" |tail -n1)    
    # js_unpacked=$(unpack "$html")

    url_in_file=$(sed -r 's|.+sources\:\[\{file\:\"([^"]+)\".+|\1|' <<< "$js_unpacked")

    if [[ "$url_in_file" =~ trailer\.mp4 ]]
    then
	unset file_in url_in_file
	_log 37	
    else
	end_extension
    fi
fi
