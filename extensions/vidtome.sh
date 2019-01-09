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
## zdl-extension name: Vidtome

if [[ "$url_in" =~ (vidtome\.) ]]
then
    html=$(curl -s "$url_in")

    countdown- 5
    
    input_hidden "$html"
    post_data="op=${post_data#*'&op='}"

    link_parser "$url_in"
    action_url="${parser_proto}${parser_domain}/plays/${parser_path}"

    html=$(curl -d "$post_data" \
		       -c "$path_tmp"/cookies.zdl \
		       "$action_url")

    url_in_file=$(unpack "$html")
    url_in_file="${url_in_file#*\'}"
    url_in_file="${url_in_file%%\'*}"
    
    file_in=$(grep 'video-page-head' <<< "$html" |
	   sed -r 's|.+>(.+)<.+|\1|g')."${url_in_file##*.}"
    
    end_extension
fi
