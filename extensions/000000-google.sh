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
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@disroot.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://z0n1n0z.helioho.st
# zoninoz@disroot.org
#

## zdl-extension types: shortlinks
## zdl-extension name: Google

if [[ "$url_in" =~ google ]]
then    
    google_location=$(grep -P "url=[^&]+" <<< "$url_in")
    google_location="${google_location#*url=}"
    google_location="${google_location%%&*}"
    google_location=$(urldecode "$google_location")

    if ! url "$google_location"
    then
        google_json=$($youtube_dl --dump-json "$url_in")
        google_location=$(node -e "var json = $google_json; console.log(json.webpage_url)")
    fi
    
    if ! url "$google_location"
    then
        google_location=$($youtube_dl --dump-json "$url_in" 2>&1 |
            grep -oP 'http.+')
    fi

    if url "$google_location"
    then
        replace_url_in "$google_location"
    else
        end_extension
    fi
fi

