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
## zdl-extension name: Vimeo (HD)

if [[ "$url_in" =~ vimeo\.com\/([0-9]+) ]]
then
    if command -v youtube-dl &>/dev/null
    then
	json_vimeo=$(youtube-dl --dump-json "$url_in")
	url_in_file=$(nodejs -e "var json = $json_vimeo; console.log(json.formats[2].url);")
	file_in=$(nodejs -e "var json = $json_vimeo; console.log(json.description);")"_${BASH_REMATCH[1]}.mp4"
    fi
    
    #end_extension
fi
