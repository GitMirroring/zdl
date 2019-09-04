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
## zdl-extension name: Backin


if [[ "$url_in" =~ backin ]]
then
    link_parser "$url_in"
    backin_url="$parser_proto$parser_domain/s/generating.php?code=$parser_path"
    get_language
    
    if url "$backin_url"
    then
	print_c 4 "$(gettext "Redirection"): $backin_url"

	if check_cloudflare "$backin_url"
	then
	    get_language_prog
	    get_by_cloudflare "$backin_url" html
	    get_language
	else
	    get_language_prog
	    html=$(wget -o /dev/null -qO- "$backin_url")
	    get_language
	fi

	file_in=$(get_title "$html")
	file_in="${file_in#Streaming }"
	url_in_file=$(unpack "$html")
	url_in_file="${url_in_file#*file\:\"}"
	url_in_file="${url_in_file%%\"*}"
    fi
    end_extension
fi
