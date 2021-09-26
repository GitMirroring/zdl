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
## zdl-extension name: Portalevideo.unimi.it

if [[ "$url_in" =~ portalevideo\.unimi\.it ]]
then
    html=$(curl -s "$url_in")
    file_in=$(grep fontAsap <<< "$html" |
                  head -n1 |
                  sed -r 's|<[^>]+>|_|g')
    file_in=$(tr -d '\t' <<< "$file_in")
    file_in="${file_in//__/_}"
    file_in="${file_in##_}"
    file_in="${file_in%Alta risoluzione attiva*}"
    file_in="${file_in%%_}"
    file_in="${file_in//\//-}"
    
    [ -n "$file_in" ] &&
        file_in="${file_in}_portalevideo-unimi-it"

    sanitize_file_in
    
    url_in_file=$(grep '<video' <<< "$html" |
                      sed -r 's|.+source\ src=\"([^"]+)\".+|\1|')    

    end_extension
fi

if [[ "$url_in" =~ videolectures\.unimi\.it ]]
then
    file_in="${url_in#*mp4\:}"
    file_in="${file_in%%\/*}"

    [[ "$url_in" =~ m3u8 ]] && {
        get_language
        force_dler FFMpeg
        get_language_prog
    }
    url_in_file="$url_in"

    end_extension
fi
