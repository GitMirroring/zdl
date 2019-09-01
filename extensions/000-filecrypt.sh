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
## zdl-extension name: Filecrypt.cc

if [ "$url_in" != "${url_in//filecrypt.cc}" ]
then
    unset redir_filecrypt location_filecrypt
    get_language_prog
    html=$(wget -qO- \
		"$url_in" \
		--keep-session-cookies \
		--save-cookies="$path_tmp"/cookies.zdl \
		--user-agent="$user_agent" \
		-o /dev/null)
    get_language
    chunks_filecrypt=$(grep openLink <<< "$html" |
			   tail -n1 |
			   sed -r "s|openLink\('|\n|g")

    codes_filecrypt=()
    
    for ((i=2; i<=$(wc -l <<< "${chunks_filecrypt[@]}"); i++))
    do
	codes_filecrypt+=( $(head -n ${i} <<< "$chunks_filecrypt" |
				 tail -n1 |
				 sed -r "s|^([^']+)'.+|\1|") )
    done

    if (( "${#codes_filecrypt[@]}" >0 ))
    then
	for code_filecrypt in "${codes_filecrypt[@]}"
	do
    	    url_filecrypt="https://filecrypt.cc/Link/${code_filecrypt}.html"

	    html=$(wget -qO- \
			"$url_filecrypt" \
			--load-cookies="$path_tmp"/cookies.zdl \
			--keep-session-cookies \
			--save-cookies="$path_tmp"/cookies2.zdl \
			--user-agent="$user_agent" \
			-o /dev/null)	
	    
	    url_filecrypt=$(grep iframe <<< "$html")
	    url_filecrypt="${url_filecrypt%\"*}"
	    url_filecrypt="${url_filecrypt##*\"}"
	    
	    get_location "$url_filecrypt" location_filecrypt
	
	    if url "$location_filecrypt"
	    then
		set_link + "$location_filecrypt"
		get_language
		print_c 4 "$(gettext "Redirection"): $location_filecrypt"
		get_language_prog
		
		url "$redir_filecrypt" || redir_filecrypt="$location_filecrypt"
	    fi
	done

	if url "$redir_filecrypt"
	then
	    set_link - "$url_in"
	    url_in="$redir_filecrypt"
	    print_links_txt
	    get_language
	    print_c 4 "$(gettext "New link to process"): $url_in"
	    get_language_prog
	fi
    else
	_log 36
    fi    
fi
