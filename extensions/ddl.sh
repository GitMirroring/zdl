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

## zdl-extension types: download
## zdl-extension name: ddl.to

function check_instance_ddlto {
    local path \
	  old_path="$PWD" \
	  paths="$HOME"/.zdl/zdl.d/"paths.txt" \
	  res=1 \
	  link

    while read path
    do	
	if [ -s "$path"/"$path_tmp"/ddlto_link.txt ]
	then
	    cd "$path"
	    read link < "$path_tmp"/ddlto_link.txt

	    if data_stdout
	    then
    		for ((i=0; i<${#url_out[@]}; i++))
    		do
    		    if [ "${url_out[i]}" == "$link" ] &&
    			   check_pid "${pid_out[i]}"
    		    then
			res=0
    			break
    		    fi
    		done
	    fi
	fi
	[ "$res" == 0 ] && break
	
    done < <(awk '!($0 in a){a[$0]; print}' "$paths")

    cd "$old_path"
    return $res
}

if [[ "$url_in" =~ (ddl.to) ]]
then
    get_language_prog
    html=$(curl -A "$user_agent" \
		-c "$path_tmp"/cookies0.zdl \
		"$url_in")
    [ -z "$html" ] &&
	html=$(wget -qO- --user-agent="$user_agent"          \
		    --keep-session-cookies                   \
		    --save-cookies="$path_tmp"/cookies0.zdl  \
		    "$url_in"                                \
	    	    -o /dev/null)
    input_hidden "$html"

    html=$(wget -qO- "$url_in"                          \
		--user-agent="$user_agent"              \
		--load-cookies="$path_tmp"/cookies0.zdl \
		--keep-session-cookies                  \
		--save-cookies="$path_tmp"/cookies.zdl  \
		--post-data="$post_data"                \
		-o /dev/null)

    unset post_data    

    ddlto_loops=0
    while [ -n "$html" ] &&
	      (( ddlto_loops < 5 ))
    do
	file_in=$(grep 'dfilename' <<< "$html" |
		      sed -r 's|.+>([^<]+)<.+|\1|g')
	file_filter "$file_in"
	url_in_file=$(grep 'Click here to download' <<< "$html")
	url_in_file="${url_in_file%\"*}"
	url_in_file="${url_in_file##*\"}"
	url_in_file="${url_in_file// /%20}"

	if url "$url_in_file" &&
		[ -n "$file_in" ]
	then
	    break

	else
	    input_hidden "$html"

	    code_ddl=$(pseudo_captcha "$html")
	    print_c 4 "Pseudo-captcha: $code_ddl"
	    
	    post_data="${post_data%\&*}&code=${code_ddl}"

	    html=$(curl "$url_in" \
			-b "$path_tmp"/cookies.zdl  \
			-A "$user_agent" \
			-d "$post_data")

	    [ -z "$html" ] &&
		html=$(wget -qO- --user-agent="$user_agent"          \
			    --load-cookies="$path_tmp"/cookies.zdl   \
			    --post-data="$post_data"                 \
			    "$url_in"                                \
	    		    -o /dev/null)
	fi
	((ddlto_loops++))
    done
    (( ddlto_loops >= 5 )) && _log 36

    if url "$url_in_file" &&
	    [[ "$url_in_file" =~ ^http\: ]]
    then
	if ! check_wget ||
		check_instance_ddlto
	then
	    get_language
	    print_c 3 "$(gettext "The bandwidth limit set by the server has been exceeded"):" 
	    print_c 1 "$(gettext "a proxy will be used (to use more band, perhaps, you can change IP address by reconnecting the modem/router)")"
	    get_language_prog	
    	    set_temp_proxy
	else
	    echo "$url_in" > "$path_tmp"/ddlto_link.txt
	fi

    elif ! check_wget ## https://
    then
	get_language
    	print_c 4 "$(gettext "File URL"): $url_in_file"
	print_c 3 "$(gettext "The bandwidth limit set by the server has been exceeded")" 
	break_loop=true
	get_language_prog	
    	continue
    fi
    
    end_extension
fi
