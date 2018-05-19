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
## zdl-extension name: Thevideo

# if [ "$url_in" != "${url_in//'//thevideo.'}" ]
# then
#     id_thevideo="${url_in##*\/}"
#     url_qualities="https://thevideo.me/download/getqualities/${id_thevideo}"

#     code_mode_hash=( $(wget -t 1 -T $max_waiting "$url_qualities" -qO- -o /dev/null |
# 			    grep download_video | tail -n1 |
# 			    sed -r "s|.+\('(.+)','(.+)','(.+)'\).+|\1 \2 \3|g") )

#     html_2_file=$(curl -s "https://thevideo.me/download/${code_mode_hash[0]}/${code_mode_hash[1]}/${code_mode_hash[2]}")

#     vt_url=$(grep dljsv <<< "$html_2_file" | sed -r 's|.+\"([^"]+)\".+|\1|g')
#     vt_code=$(curl -s "$vt_url")
#     vt_code="${vt_code#*each\|}"
#     vt_code="${vt_code%%\|*}"
    
#     url_in_file=$(grep downloadlink <<< "$html_2_file")
#     url_in_file="${url_in_file#*\"}"
#     url_in_file="${url_in_file%%\"*}?download=true&vt=${vt_code}"

#     file_in="${url_in_file##*\/}"
#     file_in="${file_in%\?*}"
#     file_in="${file_in%%.mp4}"

#     end_extension
# fi

# if [ "$url_in" != "${url_in//'//thevideo.'}" ]
# then
#     html=$(curl -s \
# 		"$url_in" \
# 		-A "$user_agent" \
# 		-c "$path_tmp/cookies.zdl" \
# 		-H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"' \
# 		-H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"' \
# 		-H 'Accept-Encoding: "gzip, deflate, br"' \
# 		-H 'DNT: "1"' \
# 		-H 'Connection: "keep-alive"' \
# 		-H 'Upgrade-Insecure-Requests: "1"')
    
#     input_hidden "$html"
#     post_data+="&imhuman="
    
#     data_cookie=( $(tail -n1 "$path_tmp/cookies.zdl" |
# 			   cut -f7) )
    
#     data_cookie+=( $(grep setAffiliateCookie <<< "$html" |
# 			   sed -r "s|.+'(.+)', '(.+)'.+|\1 \2|g") )
#     echo "${data_cookie[@]}"
    
#     html2=$(curl -v \
# 		 "$url_in" \
# 		 -A "$user_agent" \
# 		 -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"' \
# 		 -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"' \
# 		 -H 'Accept-Encoding: "gzip, deflate, br"' \
# 		 -b "$path_tmp/cookies.zdl" \
# 		 -H "Cookie: \"__cfdiud=${data_cookie[0]}; file_id=${data_cookie[1]}; aff=${data_cookie[2]}; ref_url=${url_in#*\/\/}\"" \
# 		 -H 'DNT: "1"' \
# 		 -H 'Connection: "keep-alive"' \
# 		 -H 'Upgrade-Insecure-Requests: "1"' \
# 		 -d "$post_data" 2>&1)

#     echo "$html2"
#     echo "post: $post_data"
#     _log 2
#     #end_extension
# fi

if [[ "$url_in" =~ thevideo\.[^:]+$ ]]
then
    if [[ ! "$url_in" =~ embed ]]
    then
	file_id=${url_in##*\/}
	
	domain=${url_in#*\/\/}
	domain=${domain%%\/*}
	domain=${domain%%\/*}
	[ "${domain}" != "${domain%.me}" ] &&
	    domain="${domain%.me}".website

	if [ -n "$domain" ] &&
	       [ -n "$file_id" ]
	then
	    thevideo_embed="https://${domain}/embed-${file_id}.html"

	else
	    _log 2
	fi

    else
	thevideo_embed="$url_in"
    fi
    
    if url "$thevideo_embed"
    then
	replace_url_in "$thevideo_embed"
	
	html=$(curl -s \
		    -c "$path_tmp"/cookies.zdl \
		    -A "$user_agent" \
		    "$url_in" 2>&1)

	file_in=$(grep "title: '" <<< "$html" |
			 head -n1 |
			 sed -r "s|.+'(.+)'.+|\1|g")

	html_sources=$(grep sources <<< "$html")
	
	url_in_file="${html_sources##*\"file\":\"}"
	url_in_file="${url_in_fil%%\"*}"
    fi

    #end_extension

    unset url_in_file file_in
    _log 32
fi
