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
## zdl-extension name: 4snip.pw

if [[ "$url_in" =~ 4snip\.pw ]]
then
    if [[ "$url_in" =~ out_encoded ]]
    then
	html=$(curl -s \
		    -A "$user_agent" \
		    "$url_in" \
		    -c "$path_tmp"/cookies.zdl)

	url_action_4snip=$(grep action <<< "$html")
	url_action_4snip="${url_action_4snip#*action=\'\.\.\/}"
	url_action_4snip="${url_in%out_encoded*}${url_action_4snip%%\'*}"
	
	id_4snip=$(grep "name='url' value='" <<< "$html")
	id_4snip="${id_4snip##*value=\'}"
	id_4snip="${id_4snip%%\'*}"
	
	html=$(curl -v \
		    -b "$path_tmp"/cookies.zdl \
		    -e "$url_in" \
		    -H "TE: Trailers" \
		    -H "Upgrade-Insecure-Requests: 1" \
		    -A "$user_agent" \
		    -d "url=$id_4snip" \
		    "$url_action_4snip" 2>&1)

	url_action_4snip=$(grep action <<< "$html")
	url_action_4snip="${url_action_4snip#*action=\'\.\.\/}"
	url_action_4snip="${url_in%out_encoded*}${url_action_4snip%%\'*}"   

	id_4snip=$(grep "name='url' value='" <<< "$html")
	id_4snip="${id_4snip##*value=\'}"
	id_4snip="${id_4snip%%\'*}"
    else
	url_action_4snip="${url_in//\/out\//'/outlink/'}"
    fi

    url_4snip=$(curl -v \
		     -b "$path_tmp"/cookies.zdl \
		     -H "TE: Trailers" \
		     -H "Upgrade-Insecure-Requests: 1" \
		     -A "$user_agent" \
		     -d "url=$id_4snip" \
		     "$url_action_4snip" 2>&1)    
    url_4snip=$(grep 'ocation:' <<< "$url_4snip" |
		    awk '{print $3}')
    url_4snip=$(trim "$url_4snip")

    if url "$url_4snip"
    then
	replace_url_in "$url_4snip"
    else
	_log 32
    fi
fi
