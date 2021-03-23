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
## zdl-extension name: Speedvideo (HD)


if [[ "$url_in" =~ (speedvideo.) ]]
then
    url_https="${url_in//http\:/https:}"
    replace_url_in "${url_https}"

    if [[ "$url_in" =~ embed ]]
    then
        url_embed="${url_in//'embed-'}"
        url_embed="${url_embed//http\:/https:}"

        html_not_embed=$(curl "${url_embed%'-'*}")

        # replace_url_in "${url_embed%'-'*}"
    else
        html_not_embed=$(curl "$url_in")
    fi
    input_hidden "$html_not_embed"
    file_filter "$file_in"

    # if [[ ! "$url_in" =~ embed ]]
    # then
    #     htm=$(curl -A "$user_agent" \
    #     	   -c "$path_tmp"/cookies.zdl \
    #     	   "$url_in")

    #     input_hidden "$htm"
    #     file_filter "$file_in"
    #     post_data+="&imhuman=Proceed to video"
    # fi

    # html=$(wget -qO- "${url_in//http\:/https:}"         \
    #     	--user-agent="$user_agent"              \
    #     	--load-cookies="$path_tmp"/cookies.zdl \
    #     	--keep-session-cookies                  \
    #     	--save-cookies="$path_tmp"/cookies2.zdl  \
    #     	--post-data="$post_data"                \
    #     	-o /dev/null)
    # cat "$path_tmp"/cookies2.zdl >> "$path_tmp"/cookies.zdl  
    # unset post_data    

    
    if [[ ! "$url_in" =~ embed ]]
    then
        link_parser "$url_in"
	parser_path="${parser_path%%\/*}"
	url_in_embed="https://$parser_domain/embed-${parser_path%\/*}-607x360.html"

        url "$url_in_embed" &&
            replace_url_in "$url_in_embed"
    fi

    html=$(curl "$url_in" \
                -A "$user_agent" \
                -c "$path_tmp"/cookies.zdl)
    
    if [[ "${htm}${html}" =~ 'File Not Found' ]] 
    then
	_log 3

    elif [[ "${htm}${html}" =~ 'Video is '(processing|transfer on streaming server)' now' ]]
    then
        _log 17
        	
    elif [ -n "$html" ]
    then
	# url_speedvideo=$(grep 'var url_speedvideoBackup' <<< "$html" |
	# 		   head -n10 |
	# 		   tail -n1 |
	#      		   sed -r 's|.+\"([^"]+)\".+|\1|g')

	# if ! url "$url_speedvideo" &&
        #         grep 'label: "HD"' <<< "$html" >/dev/null
	# then
	#     url_speedvideo=$(grep 'label: "HD"' -B 1 <<< "$html" |
	# 		      head -n1)
	#     url_speedvideo="${url_speedvideo#*\'}"
	#     url_speedvideo="${url_speedvideo%\'*}"
	# fi

        # #### lento:
	# ## get_location "$url_speedvideo" url_in_file
        # url_in_file=$(curl -v "$url_speedvideo" 2>&1 | grep location:)
        # url_in_file=$(trim "${url_in_file##* }")

        if ! url "$url_in_file" 
	then
            get_language_prog
            for def in H N Lq ''
            do
                linkfile=$(grep "var linkfileBackup${def} =" <<< "$html")

                [ -z "$linkfile" ] && continue

                linkfile="${linkfile#*\"}"
                linkfile="${linkfile%\"*}"

                ## get_location "$linkfile" url_in_file
                url_in_file=$(curl -v "$linkfile" \
                                   -c "$path_tmp/cookies.zdl" \
                                   -A "$user_agent" 2>&1 |
                                  grep ocation:)
                url_in_file=$(trim "${url_in_file##* }")

                url "$url_in_file" && break
            done
            get_language
        fi
        
	if ! url "$url_in_file" 
	then
	    linkfile=$(grep 'base64_decode' <<< "$html"   |
	        	   tail -n1                          |
	        	   sed -r 's|.+\"([^"]+)\".+|\1|g')

	    var2=$(grep base64_decode <<< "$html" |
			  sed -r 's|.+ ([^ ]+)\)\;$|\1|g' | head -n1)
	    

	    url_in_file=$(base64_decode "$linkfile"     \
					$(grep "$var2" <<< "$html"             |
				    	      head -n1                         |
				    	      sed -r 's|.+ ([^ ]+)\;$|\1|g') )

	    url_in_file="${url_in_file#*'///'}"

	    [[ ! "$url_in_file" =~ ^http ]] &&
		url_in_file="http://${url_in_file}"
	fi
	
	[ -n "$file_in" ] &&
            url "$url_in_file" &&
            [[ ! "$file_in" =~ ${url_in_file##*.}$ ]] &&
	    file_in="${file_in##.}.${url_in_file##*.}"

        file_in="${file_in%%.mp4}".mp4

        test_url_in_file || {
            # echo "Elite" >> "$path_tmp"/proxy
            # echo "Anonymous" >> "$path_tmp"/proxy
            print_c 3 "$(gettext "The bandwidth limit set by the server has been exceeded"):" 
            print_c 1 "$(gettext "a proxy will be used (to use more band, perhaps, you can change IP address by reconnecting the modem/router)")"
            
            set_temp_proxy
        }

        end_extension
    fi
fi

