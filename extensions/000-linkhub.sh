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
    
    html=$(curl "$link")
    html=$(grep get_btn <<< "$html")
    html="${html#*href=\"}"
    html="${html%%\"*}"
    
    link_parser "$link"
    print_c 4 "$(gettext "Redirection"): ${parser_proto}${parser_domain}/${html#*\/}"
    html=$(curl "${parser_proto}${parser_domain}/${html#*\/}")

    if [[ "$html" =~ text-url ]]
    then
        newlink_first=$(grep text-url -A1 <<<  "$html" |
                            tail -n1 |
                            sed -r 's|^[^"]+\"([^"]+)\".+|\1|' )

        newlink_first=$(sanitize_url "$newlink_first")

        links+=( $(grep -P 'href.+target=\"_blank\" title=\"' <<< "$html" |
    		   sed -r 's|.+>([^<]+)<\/a>|\1|g')
	       )

        for newlink in "${links[@]}"
        do
	    newlink=$(trim "$newlink")
	    if url "$newlink"
	    then
                if [[ "$newlink" =~ ninjastream\..+\/watch\/ ]]
                then
                    newlink="${newlink//\/watch\///download/}"
                fi

                if [ -n "$no_url_regex" ] && [[ "${newlink}" =~ $no_url_regex ]]
	        then
		    _log 15 "$newlink"
                    continue
	        fi
                
	        if [ -n "$url_regex" ] && [[ ! "${newlink}" =~ $url_regex ]]
	        then
		    _log 16 "$newlink"
                    continue
	        fi
                
	        print_c 4 "$(gettext "Redirection"): $newlink"
	        set_link + "$newlink"
	        if [ -z "$newlink_first" ]
	        then
		    newlink_first="$newlink"
	        fi
	    fi
        done
    fi

    if url "$newlink_first"
    then
	replace_url_in "$newlink_first"
	return 0
    else
	return 1
    fi
}
 
if [ "$url_in" != "${url_in//linkhub\.}" ]
then
    get_linkhub "$url_in" || _log 36
fi

