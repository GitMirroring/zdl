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
## zdl-extension name: isecure

if [[ "$url_in" =~ isecure\.link ]]
then
    html=$(curl -s "$url_in")    
    isecure_url=$(grep -oP 'Download.+iframe.+src.+' <<< "$html" |
                      grep -oP 'http[^"]+')

    if ! url "$isecure_url"
    then        
        isecure_url=$(grep -oP 'iframe src.+' <<< "$html" |
                      grep -oP 'http[^"]+')
    fi

    if url "$isecure_url"
    then
        replace_url_in "$isecure_url"
        
    else
	_log 2
    fi
fi
