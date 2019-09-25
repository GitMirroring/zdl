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
## zdl-extension name: Streamango

if [[ "$url_in" =~ streamango ]]
then
    if [[ "$url_in" =~ \/embed\/ ]]
    then
	url_in_streamango="${url_in//http\:/https:}"
	url_in_streamango="${url_in_streamango//embed/f}"
	replace_url_in "$url_in_streamango"
    fi
    
    # if command -v phantomjs &>/dev/null
    # then
    # 	url_in_file=$(phantomjs "$path_usr"/extensions/streamango-phantomjs.js "$url_in" |
    # 			     tail -n1)

    # 	file_in="${url_in_file##*\/}"
	
    # else
    # 	_log 35
    # fi

    html=$(curl -s "$url_in")
    file_in=$(get_title "$html")
    file_filter "$file_in"
    url_in_file=$(youtube-dl --get-url "$url_in")
    
    end_extension
fi
