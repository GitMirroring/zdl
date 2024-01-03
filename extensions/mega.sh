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

        unset ok
        ok_loop=0
        while [ -z "$ok" ] || (( ok_loop >1 ))
        do
            test_tmp=$(mktemp)
            megadl --debug api \
                   "$url_in" &> "$test_tmp" &
            pid_mega=$!
            echo "$pid_mega" >> "$path_tmp/external-dl_pids.txt" 
            
            for iiii in {0..30}
            do
                if [[ "$(cat "$test_tmp")" =~ 'Local file already exists: '(.+)$ ]]
                then
                    file_in="${BASH_REMATCH[1]}"
#                    echo "Local file already exists: ${BASH_REMATCH[1]}"
                    ok=true
                    break
                fi

                if [[ "$(cat "$test_tmp")" =~ '%' ]]
                then
                    ok=true
                    break
                fi
                sleep 1
            done
            kill -9 $pid_mega
            ((ok_loop++))
        done
        
#        echo "cat $test_tmp:"         
#        cat "$test_tmp" 

        #sleep 1
        #[ -d "$file_in" ] ||
        #    mkdir -p "$file_in"

        if [ -z "$file_in" ]
        then
            file_in="$(awk '{match($0, /^([^"]+):\s[0-9]+/, matched); if (matched[1]) print matched[1]}' $test_tmp | tail -n1)"
            mkdir -p "$file_in"
            file_in_encoded=.megatmp.$(awk '{match($0, /"p":\s"(.+)"/, matched); if (matched[1]) print matched[1]}' $test_tmp)
            rm -rf "$file_in_encoded"
            
        else
            [ -d "$file_in" ] ||
                mkdir -p "$file_in"

            unset ok
            ok_loop=0
            while [ -z "$ok" ] && (( ok_loop <2 ))
            do            
                test_tmp=$(mktemp)
                megadl --debug api          \
                       --path "${file_in}"  \
                       "$url_in" 2>&1  &>> "$test_tmp" &
                pid_mega=$!
                echo "$pid_mega" >> "$path_tmp/external-dl_pids.txt" 
                # echo "            megadl --debug api \
                #    --path       \"$file_in\" \
                #    \"$url_in\" &> \"$test_tmp\" &"
                
                for iiii in {0..120}
                do
                    #echo "test: $test_tmp"
                    (( iiii % 2 )) &&
                    sprint_c 2 "\r. . ." ||
                        sprint_c 2 "\r...  "
                    
                    if [[ "$(cat "$test_tmp")" =~ 'Local file already exists: '(.+)$ ]]
                    then
                        rm -rf "${BASH_REMATCH[1]}"
#                        echo "Local file already exists: ${BASH_REMATCH[1]}"
                        break
                    fi

                    if (( $(wc -l < "$test_tmp") >18 ))
                    then
                        mega_line_19=$(tail -n1 "$test_tmp")
                        
                        if grep -q "Server returned 509" <<< "$mega_line_19"
                        then
                            ok_loop=10
                            _log 25
                            break
                            
                        elif [[ "$mega_line_19" =~ (\%) ]]
                        then
                            ok=true
                            break
                        fi
                        # if grep -q "Server returned 509" "$test_tmp"
                        # then
                        #     ok_loop=10
                        #     _log 25
                        #     break
                        # fi
                        
                        # if [[ "$(cat "$test_tmp")" =~ (\%) ]]
                        # then
                        #     ok=true
                        #     break
                        # fi
                    fi
                    # if (( $(grep -A5 '"ip":' "$test_tmp" | wc -l) == 5 )) && (( iiii > 20 ))
                    # then
                    #     #ok=true
                    #     ok_loop=2
                    #     break
                    # fi
                    
                    sleep 1
                done
                kill -9 $pid_mega
                ((ok_loop++))
            done
            #           echo "cat $test_tmp:"         
            #           cat "$test_tmp"
            file_in="$(awk '{match($0, /^([^"]+):\s[0-9]+/, matched); if (matched[1]) print matched[1]}' $test_tmp | tail -n1)"
            file_in_encoded=.megatmp.$(awk '{match($0, /"p":\s"(.+)"/, matched); if (matched[1]) print matched[1]}' $test_tmp)
        fi
        
        #       echo "FILE_IN: $file_in"
        
        #rm -f "$file_in_encoded"
        
        length_in=$(awk '{match($0, /"s":\s(.+),/, matched); if (matched[1]) print matched[1]}' $test_tmp)

        get_language
        force_dler MegaDL
        get_language_prog
        
    else
        get_language
        print_c 3 "$(gettext 'To download from Mega, install the "megatools" package')"
        get_language_prog
    fi

    no_check_links+=( mega )
    
    end_extension
fi
