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
## zdl-extension name: Rockfile

if [ "$url_in" != "${url_in//'rockfile.'}" ]
then
    domain_rockfile="rockfile.eu"
    replace_url_in "${url_in//https/http}"

    if check_cloudflare "$url_in"
    then	
	curl                                                                                  \
    	    -A "$user_agent"                                                                  \
    	    -c "$path_tmp/cookies.zdl"                                                        \
    	    -D "$path_tmp/header.zdl"                                                         \
	    -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'    \
    	    -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                   \
	    -H 'Accept-Encoding: "gzip, deflate"'                                             \
	    -H 'DNT: "1"'                                                                     \
	    -H 'Connection: "keep-alive"'                                                     \
    	    "$url_in" > "$path_tmp"/cloudflare.html

	if ! command -v phantomjs &>/dev/null
	then
	    _log 35

	else
	    get_jschl_answer "$path_tmp"/cloudflare.html "$domain_rockfile"
	    
	    input_hidden "$path_tmp"/cloudflare.html

	    get_data="${post_data%\&*}&jschl_answer=$jschl_answer"

	    cookie_rockfile=$(awk '/cfduid/{print $6 "=" $7}' "$path_tmp/cookies.zdl")
	    
	    countdown- 4

	    curl                                                                                \
		-A "$user_agent"                                                                \
		-c "$path_tmp/cookies.zdl"                                                      \
		-D "$path_tmp/header2.zdl"                                                      \
		-H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    		-H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
		-H 'Accept-Encoding: "gzip, deflate"'                                           \
		-H 'DNT: "1"'                                                                   \
		-H "Referer: \"$url_in\""                                                       \
		-H "Cookie: \"${cookie_rockfile}\""                                             \
		-H 'Connection: "keep-alive"'                                                   \
		-d "$get_data"                                                                  \
		-G                                                                              \
		"http://rockfile.eu/cdn-cgi/l/chk_jschl" >/dev/null
	    
	    
	    cookie_rockfile=$(grep Set-Cookie "$path_tmp/header2.zdl" |
				     cut -d' ' -f2 |
				     tr '\n' ' ')
	    
	    cookie_rockfile="${cookie_rockfile%';'*}"
	    
	    html=$(curl                                                                                \
		       -A "$user_agent"                                                                \
		       -b "$path_tmp/cookies.zdl"                                                      \
		       -c "$path_tmp/cookies2.zdl"                                                     \
		       -D "$path_tmp/header2.zdl"                                                      \
		       -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    		       -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
		       -H 'Accept-Encoding: "gzip, deflate"'                                           \
		       -H 'DNT: "1"'                                                                   \
		       -H "Referer: \"$url_in\""                                                       \
		       -H "Cookie: \"${cookie_rockfile}\""                                             \
		       -H 'Connection: "keep-alive"'                                                   \
		       "$url_in" 2>&1)
	fi
	
	if [[ ! "$html" =~ 'Regular Download' ]] &&
	   [[ "$html" =~ 'The document has moved'.+href=\"(.+)\".+$ ]]
	then
	    url_http="${BASH_REMATCH[1]}"

	    replace_url_in "$url_http"
	    
	    html=$(curl                                                                                \
		       -A "$user_agent"                                                                \
		       -b "$path_tmp/cookies.zdl"                                                      \
		       -c "$path_tmp/cookies2.zdl"                                                     \
		       -D "$path_tmp/header2.zdl"                                                      \
		       -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    		       -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
		       -H 'Accept-Encoding: "gzip, deflate"'                                           \
		       -H 'DNT: "1"'                                                                   \
		       -H "Referer: \"$url_in\""                                                       \
		       -H "Cookie: \"${cookie_rockfile}\""                                             \
		       -H 'Connection: "keep-alive"'                                                   \
		       "$url_in" 2>&1)
	fi
	
    else
	html=$(curl -v \
		   -A "$user_agent" \
		   -c "$path_tmp/cookies2.zdl" \
		   -D "$path_tmp/header2.zdl" \
		   "$url_in")
    fi

    if [[ "$html" =~ (File Deleted|file was deleted|File [nN]{1}ot [fF]{1}ound) ]]
    then
	_log 3

    elif [ -n "$html" ]
    then
	input_hidden "$html"

	method_free=$(grep -P 'method_.*free.+freeDownload' <<< "$html" |
			     sed -r 's|.+(method_.*free)\".+|\1|g' |
			     tr -d '\r')

	post_data="${post_data##*document.write\(\&}&${method_free}=Regular Download"

	html=$(curl                                   \
		   -b "$path_tmp"/cookies2.zdl        \
		   -A "$user_agent"                   \
		   -d "$post_data"                    \
		   "$url_in")

	if [[ "$html" =~ 'have to wait '([0-9]+) ]]
	then
	    url_in_timer=$((${BASH_REMATCH[1]} * 60))
	    set_link_timer "$url_in" $url_in_timer
	    _log 33 $url_in_timer

	elif [[ "$html" =~ (No Available traffic to download this file. Remaining traffic[^.]+\.) ]]
	then
	    errMsg="${BASH_REMATCH[1]//<*>}"
	    _log 2

	else
	    code=$(pseudo_captcha "$html")

	    if [[ "$code" =~ ^[0-9]+$ ]]
	    then
		print_c 1 "Pseudo-captcha: $code"

		unset post_data
		input_hidden "$html"
		post_data="${post_data##*'(&'}&code=$code"
		post_data="${post_data//'&down_script=1'}"

		errMsg=$(grep 'Devi attendere' <<< "$html" |
				sed -r 's|[^>]+>([^<]+)<.+|\1|g')
		
		if [[ "$html" =~ (You can download files up to) ]]
		then
		    _log 4

		elif [ -n "$code" ]
		then
		    timer=$(grep countdown_str <<< "$html" |
				   sed -r 's|.+>([0-9]+)<.+|\1|g')
						       
		    countdown- $timer
		    sleeping 2
		    
		    url_in_file=$(curl "${url_in}"                             \
				       -b "$path_tmp"/cookies2.zdl             \
				       -A "$user_agent"                        \
				       -d "$post_data"                           |
					 grep -P '[^\#]+btn_downloadLink'        |
					 sed -r 's|.+href=\"([^"]+)\".+|\1|g')
		    url_in_file=$(sanitize_url "$url_in_file")
		fi

	    else
		print_c 3 "Pseudo-captcha: codice non trovato"

		if [[ "$html" =~ google.+recaptcha ]]
		then
		    url_in_timer=true
		    _log 36
		fi
	    fi
	fi
    fi

    if [ -z "$file_in" ] &&
	   url "$url_in_file"
    then
	file_in="${url_in_file##*\/}"
    fi
    
    try_end=25
    [ -n "$premium" ] &&
	print_c 2 "Rockfile potrebbe aver attivato il captcha: in tal caso, risolvi prima i passaggi richiesti dal sito web" ||
	    [ -n "$url_in_timer" ] ||
	    end_extension
fi

