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
## zdl-extension name: La7 (HD)


if [[ "$url_in" =~ la7\.it ]]
then
    html=$(curl -s "$url_in")
    file_in=$(grep 'title :' <<< "$html")
    file_in="${file_in#*\"}"
    file_in="${file_in%\"*}"
    file_in="${file_in//\//-}"
    if [[ "$file_in" =~ Diretta ]]
    then
	file_in+=__$(date +%Y-%m-%d)_$(date +%H-%M-%S)
    fi
    
    url_in_file=$(grep -oP "[^']+\.m3u8[^']+" <<< "$html")

    if ! url "$url_in_file"
    then
	url_in_file=$(grep -oP '[^"]+\.m3u8[^"]+' <<< "$html")
	url_in_file=$(curl -s "$url_in_file" | tail -n1)
    fi
    
    end_extension
fi
									   

