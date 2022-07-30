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
## zdl-extension name: linkhub

function get_linkhub {
    local link="$1" newlink html 
    declare -a links=()

    for i in 0 1 2 3 4 5
    do
        html=$(curl "$link")
        html=$(grep get_btn <<< "$html")
        html="${html#*href=\"}"
        html="${html%%\"*}"
        linkhub_code="${html#*\/}"
        sleep 1
        [ -n "${linkhub_code//view\/}" ] && break
    done

    if [ -z "$linkhub_code" ]
    then
        return 2

    else
        link_parser "$link"

        get_language
        print_c 4 "$(gettext "Redirection"): $link --> ${parser_proto}${parser_domain}/${linkhub_code}"
        get_language_prog

        html=$(curl "${parser_proto}${parser_domain}/${linkhub_code}")

        if [[ "$html" =~ text-url ]]
        then
	    if [ -z "$newlink_first" ]
	    then
                newlink_first=$(grep text-url -A1 <<<  "$html" |
                                    tail -n1 |
                                    sed -r 's|^[^"]+\"([^"]+)\".+|\1|' )

                newlink_first=$(sanitize_url "$newlink_first")
            fi
            
            links+=( $(grep -P 'href.+target=\"_blank\" title=\"' <<< "$html" |
    		           sed -r 's|.+>([^<]+)<\/a>.+|\1|g') )
            
            for newlink in "${links[@]}"
            do
	        newlink=$(trim "$newlink")
	        if url "$newlink" &&
                        [ "$newlink" != "$url_in" ]
	        then
                    if [[ "$newlink" =~ ninjastream\..+\/watch\/ ]]
                    then
                        newlink="${newlink//\/watch\///download/}"
                        
                    elif [ "$newlink" != "${newlink//linkhub\.}" ]
                    then
                        get_linkhub "$newlink"
                        continue
                    fi

                    if ( [ -n "$no_url_regex" ] && [[ "${newlink}" =~ $no_url_regex ]] ) ||
                           ( [ -n "$url_regex" ] && [[ ! "${newlink}" =~ $url_regex ]] )    
	            then
                        [ "$newlink_first" == "$newlink" ] && unset newlink_first
                        continue
	            fi

	            set_link + "$newlink"
                    
	            if [ -z "$newlink_first" ]
	            then
		        newlink_first="$newlink"
	            fi
                fi                    
            done
        fi
    fi
}
 
if [ "$url_in" != "${url_in//linkhub\.}" ]
then
    for i in 0 1 2
    do
        get_linkhub "$url_in"
        [[ ! "$newlink_first" =~ linkhub\. ]] && break
    done

    [[ ! "$newlink_first" =~ linkhub\. ]] &&
        url "$newlink_first" &&
        replace_url_in "$newlink_first" ||
            _log 2
    
    unset newlink_first
fi
