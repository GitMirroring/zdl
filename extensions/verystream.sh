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

## zdl-extension types: streaming download
## zdl-extension name: Verystream


if [[ "$url_in" =~ verystream\. ]]
then
    html=$(curl -s "$url_in")

    videolink_token=$(grep '"videolink"' <<< "$html")
    videolink_token="${videolink_token#*>}"
    videolink_token="${videolink_token%<*}"

    #### per recuperare la chiave di questo sistema:
    ##
    ## grep 'o^_^o' <<< "$html" >"$path_tmp"/aaencoded.js
    ## sed -r 's|<[^>]+>||g' -i "$path_tmp"/aaencoded.js
    ## php_aadecode "$path_tmp"/aaencoded.js #--> $proto $domain /gettoken/ $videolink_token

    link_parser "$url_in"
    url_in_file="${parser_proto}${parser_domain}/gettoken/${videolink_token}"
    file_in=$(get_title "$html")
    
    end_extension
fi
