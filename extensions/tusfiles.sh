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

## zdl-extension types: download
## zdl-extension name: Tusfiles

if [ "$url_in" != "${url_in//'tusfiles.net'}" ]
then
    html=$(curl -s -c "$path_tmp"/cookies.zdl "$url_in")
    
    if [[ "$html" =~ (The file you are trying to download is no longer available) ]]
    then
	_log 3
    else
	input_hidden "$html"

	url_in_file=$(curl -v -d "$post_data" "$url_in" 2>&1 |
			  grep 'Location:' |
			  cut -d' ' -f3)

	url_in_file=$(trim "$url_in_file")

	file_in=${url_in_file##*\/}
	
	end_extension
    fi
fi
