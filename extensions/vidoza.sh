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
## zdl-extension types: streaming download
## zdl-extension name: Vidoza

if [[ "$url_in" =~ vidoza ]] &&
       [[ ! "$url_in" =~ \/v.mp4$ ]]
then
    html=$(curl -v \
		-A "$user_agent" \
		"$url_in" \
		2>&1)

    if ! grep -qP '(source src=|sources: )' <<< "$html" &&
	    [[ ! "$url_in" =~ embed ]]
    then
    	link_parser "$url_in"
	replace_url_in "$parser_proto$parser_domain"/embed-"${parser_path%.html}".html
	html=$(curl -v \
		    -A "$user_agent" \
		    "$url_in" \
		    2>&1)	
    fi

    if [[ "$html" =~ (Video is processing now) ]]
    then
	_log 17

    elif [[ "$html" =~ (The file was deleted) ]]
    then
	_log 3
	
    else
	url_in_file=$(grep 'source src=' <<< "$html")
	url_in_file="${url_in_file#*\"}"
	url_in_file="${url_in_file%%\"*}"

	if ! url "$url_in_file"
	then
	    url_in_file=$(grep 'sources: ' <<< "$html")
	    url_in_file="${url_in_file#*\"}"
	    url_in_file="${url_in_file%%\"*}"
	fi
	
	file_in=$(grep 'var curFileName' <<< "$html")
	file_in="${file_in#*\"}"
	file_in="${file_in%%\"*}"

	ext="${url_in_file##*.}"

	if [ -n "$file_in" ] &&
	       [[ ! "$file_in" =~ $ext$ ]]
	then
	    file_in="$file_in"."$ext"
	fi

	end_extension
    fi
fi
