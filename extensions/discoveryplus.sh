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
## zdl-extension name: DiscoveryPlus (HD)


if [[ "$url_in" =~ discoveryplus\. ]]
then
    dplus_json=$($youtube_dl --dump-json \
			     "$url_in" \
			     2>/dev/null)
    
    file_in=$(node -e "var json = $dplus_json; var filename = json.title; if (json.season_number) { filename = json.season_number + 'x' + ('00' + json.episode_number).slice(-2) + '_-_' + filename; } console.log(filename + '.mp4')")
    sanitize_file_in "$file_in"

    url_in_file=$(node -e "var json = $dplus_json; console.log(json.requested_formats[0].url + '\n' + json.requested_formats[1].url)")

    url_in_file_video=$(grep video <<< "$url_in_file")
    url_in_file_audio=$(grep audio <<< "$url_in_file")

    url_in_file=$(head -n1 <<< "$url_in_file")

    force_dler FFMpeg
    
    end_extension
fi


									   

