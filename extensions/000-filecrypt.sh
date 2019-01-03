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

## zdl-extension types: shortlinks
## zdl-extension name: Filecrypt.cc

if [ "$url_in" != "${url_in//filecrypt.cc}" ]
then
    html=$(wget -qO- \
		"$url_in" \
		--keep-session-cookies \
		--save-cookies="$path_tmp"/cookies.zdl \
		--user-agent="$user_agent" \
		-o /dev/null)

    url_filecrypt=$(grep openLink <<< "$html" |
			tail -n1)
    url_filecrypt="${url_filecrypt%\'*}"
    url_filecrypt="${url_filecrypt##*\'}"

    if [ -n "$url_filecrypt" ]
    then
	url_filecrypt="https://filecrypt.cc/Link/${url_filecrypt}.html"

	html=$(wget -qO- \
		    "$url_filecrypt" \
		    --load-cookies="$path_tmp"/cookies.zdl \
		    --keep-session-cookies \
		    --save-cookies="$path_tmp"/cookies2.zdl \
		    --user-agent="$user_agent" \
		    -o /dev/null)	

	url_filecrypt=$(grep iframe <<< "$html")
	url_filecrypt="${url_filecrypt%\"*}"
	url_filecrypt="${url_filecrypt##*\"}"

	get_location "$url_filecrypt" location_filecrypt
    fi

    if url "$location_filecrypt"
    then
	replace_url_in "$location_filecrypt"

    else
	_log 36
    fi    
fi
