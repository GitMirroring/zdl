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
## zdl-extension name: link4.me

if [ "$url_in" != "${url_in//link4.me}" ]
then
    _log 38
    
    if [ 1 == 2 ]
    then		  
	html=$(curl -v \
		    -c "$path_tmp/cookies.zdl" \
		    -H 'DNT: "1"' \
		    -H 'Connection: "keep-alive"' \
		    -H 'Upgrade-Insecure-Requests: "1"' \
		    "$url_in" 2>&1)
	
	html=$(sed -r 's|/>|/>\n|g' <<< "$html")

	## equivale a "$path_tmp/cookies.zdl" in un array: 
	#set_cookie=( $(grep Set-Cookie <<< "$html" | cut -d' ' -f3) )
	
	input_hidden "$html"

	countdown- 10
	curl -v \
	     -A "$user_agent" \
	     -b "$path_tmp/cookies.zdl" \
	     -c "$path_tmp/cookies2.zdl" \
	     -H 'DNT: "1"' \
	     -H 'Connection: "keep-alive"' \
	     http://link4.me/custom_theme/build/img/skip-ad.png 1>/dev/null  2>"$path_tmp/link4-header.txt"

	curl -v \
	     -A "$user_agent" \
	     -b "$path_tmp/cookies2.zdl" \
	     -d "$post_data"'&adsnetwork1=0&adsnetwork2=0' \
	     -H 'DNT: "1"' \
	     -H 'Connection: "keep-alive"' \
	     http://link4.me/links/go 2>&1
    fi
fi
