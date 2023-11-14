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
## zdl-extension name: Dropload

if [ "$url_in" != "${url_in//dropload}" ]
then
    html=$(curl -s "$url_in")

    url_in_file=$(grep -oP 'sources\:\[\{file\:\"[^"]+' <<< "$(unpack "$html")")
    url_in_file="${url_in_file#*\"}"

    html_url=$(grep '/d/' <<< "$html")
    html_url="${html_url#*\"}"
    html_url="${html_url%%\"*}"

    file_in=$(curl -s "$html_url" | grep "Download File" -A1 | tail -n1)
    file_in="${file_in%\(*}"
    file_in="${file_in%.mp4}".mp4

    force_dler FFMpeg
    
    end_extension
fi
