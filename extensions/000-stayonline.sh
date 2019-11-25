#!/bin/bash
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
## zdl-extension name: stayonline

if [ "$url_in" != "${url_in//stayonline.}" ]
then
    html=$(curl -s \
                -c "$path_tmp"/cookies.zdl \
                "$url_in")

    stayonline_id="${url_in%\/}"
    stayonline_id="${stayonline_id##*\/}"

    stayonline_url=$(curl -s \
                          -b "$path_tmp"/cookies.zdl \
                          -d "id=$stayonline_id" \
                          "https://stayonline.pro/ajax/linkView.php" |
                         awk '/value/{match($2, /\"(.+)\"/, matched); gsub(/\\/,"",matched[1]); print matched[1] }')

    if url "$stayonline_url"
    then
        replace_url_in "$stayonline_url"

    else
        _log 2
    fi
fi


