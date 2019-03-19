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
## zdl-extension name: ddl.to


if [[ "$url_in" =~ (ddl.to) ]]
then
    html=$(curl -A "$user_agent" \
		-c "$path_tmp"/cookies0.zdl \
		"$url_in")

    input_hidden "$html"

    html=$(wget -qO- "$url_in"                          \
		--user-agent="$user_agent"              \
		--load-cookies="$path_tmp"/cookies0.zdl \
		--keep-session-cookies                  \
		--save-cookies="$path_tmp"/cookies.zdl  \
		--post-data="$post_data"                \
		-o /dev/null)

    unset post_data    

    while [ -n "$html" ]
    do
	file_in=$(grep 'dfilename' <<< "$html" |
		      sed -r 's|.+>([^<]+)<.+|\1|g')

	url_in_file=$(grep 'Click here to download' <<< "$html")
	url_in_file="${url_in_file%\"*}"
	url_in_file="${url_in_file##*\"}"
	url_in_file="${url_in_file// /%20}"

	if url "$url_in_file" &&
		[ -n "$file_in" ]
	then
	    break

	else
	    input_hidden "$html"

	    code_ddl=$(pseudo_captcha "$html")
	    print_c 4 "Pseudo-captcha: $code_ddl"
	    
	    post_data="${post_data%\&*}&code=${code_ddl}"

	    html=$(curl "$url_in" \
			-b "$path_tmp"/cookies.zdl  \
			-A "$user_agent" \
			-d "$post_data")
	fi
    done
    end_extension
fi
