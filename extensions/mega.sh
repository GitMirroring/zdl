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
# adapted from: https://gist.github.com/KenMacD/6431823
#

## zdl-extension types: download
## zdl-extension name: Mega

#####################################
# url "$url_in_file" &&
#     test -n "$file_in" ||
# 	extension_mega "$url_in" ||
#         run_megadl "$url_in"
#####################################

if [[ "$url_in" =~ (^https\:\/\/mega\.co\.nz\/|^https\:\/\/mega\.nz\/) ]]
then
    if hash megadl 2>/dev/null
    then
        url_in_file="$url_in"

        while [ -z "$ok" ]
        do
            test_tmp=$(mktemp)
            megadl --debug api \
                   "$url_in" &> "$test_tmp" &
            pid_mega=$!
            
            while :
            do
                if [[ "$(cat "$test_tmp")" =~ 'Local file already exists: '(.+)$ ]]
                then
                    rm -rf "${BASH_REMATCH[1]}"
                    break
                fi

                if [[ "$(cat "$test_tmp")" =~ '%' ]]
                then
                    ok=true
                    break
                fi
                sleep 0.1
            done
            kill $pid_mega 
        done
        
        file_in_encoded=.megatmp.$(awk '{match($0, /"p":\s"(.+)"/, matched); if (matched[1]) print matched[1]}' $test_tmp)
        rm -f "$file_in_encoded"
        
        file_in="$(awk '{match($0, /^([^"]+):\s[0-9]+/, matched); if (matched[1]) print matched[1]}' $test_tmp)"
        length_in=$(awk '{match($0, /"s":\s(.+),/, matched); if (matched[1]) print matched[1]}' $test_tmp)

        get_language
        force_dler MegaDL
        get_language_prog
        
    else
        get_language
        print_c 3 "$(gettext 'To download from Mega, install the "megatools" package')"
        get_language_prog
    fi
    
    end_extension
fi
