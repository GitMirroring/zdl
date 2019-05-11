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
## zdl-extension name: Openload(s)


if [[ "$url_in" =~ openload[s]*\. ]]
then
    if [[ "$url_in" =~ ^(.+)/([0-9]{3})$ ]]
    then
	new_link_openload="${BASH_REMATCH[1]}"
	url "$new_link_openload" &&
	    replace_url_in "$new_link_openload"
    fi
    
    if command -v youtube-dl &>/dev/null
    then
	url_in_file=$(youtube-dl --get-url "$url_in")
	file_in=$(youtube-dl --get-title "$url_in")
    fi
    
    if ! url "$url_in_file" ||
	     [ -z "$file_in" ] 
    then
	if [[ "$url_in" =~ \/stream\/ ]]
	then
	    get_location "$url_in" url_in_file
	    file_in="${url_in_file##*\/}"
	    file_in="${file_in%\?*}"
	else
	    extension_openload "$url_in"
	fi
    fi
    
    end_extension
fi
