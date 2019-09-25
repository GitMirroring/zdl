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
## zdl-extension name: IlFattoQuotidiano


if [[ "$url_in" =~ ilfattoquotidiano ]]
then
    get_language_prog
    html=$(curl -s "$url_in")
    url_in_file=$(grep 'playlist: \[' <<< "$html" |
			 sed -r 's|.+\":\"([^"]+\.m3u8)\".+|\1|g' |
			 tr -d '\\' | head -n1)
    get_language
    print_c 4 "$(gettext "Redirection"): $url_in_file"
    get_language_prog
    
    if url "$url_in_file"
    then
	url_in_file=$(curl -s "$url_in_file" |
			     grep http |
			     head -n1)
	get_language
	print_c 4 "$(gettext "Redirection"): $url_in_file"
    	get_language_prog
    fi
    
    file_in=$(get_title "$html" | head -n1)
    file_filter "$file_in"
    
    end_extension
fi
									   

