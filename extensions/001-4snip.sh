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
    url_action_4snip="${url_in//\/out\//'/outlink/'}"
    id_4snip="${url_in##*\/}"

    url_4snip=$(curl -v -d "url=$id_4snip" "$url_action_4snip" 2>&1 |
		    grep 'location:' |
		    awk '{print $3}')

    url_4snip=$(trim "$url_4snip")

    if url "$url_4snip"
    then
	replace_url_in "$url_4snip"
    else
	_log 32
    fi
fi
