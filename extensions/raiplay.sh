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
## zdl-extension name: RaiPlay (HD)


if [[ "$url_in" =~ raiplay ]]
then
    ## html=$(curl -s "$url_in")
    html=$(wget -qO- "$url_in" -o /dev/null)
    
    file_in=$(get_title "$html" | tr -d '\n' | tr -d '\r')
    file_in="${file_in#Film\: }"
    
    url_raiplay=$(grep data-video-url <<< "$html" |
		 sed -r 's|.+data-video-url=\"([^"]+)\".+|\1|g')
    
    url_raiplay=$(get_location "$url_raiplay")

    url_in_file=$(curl -s "$url_raiplay" | tail -n1)
fi
									   

