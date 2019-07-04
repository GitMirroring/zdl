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
    rm -f "$path_tmp"/cookies*.zdl "$path_tmp"/headers*.zdl 
    domain_rockfile="rockfile.co"

    if [[ ! "$url_in" =~ \/f\/ ]]
    then
	if check_cloudflare "$url_in"
	then
	    get_location_by_cloudflare "$url_in" rockfile_location
	else
	    get_location "$url_in" rockfile_location
	fi

	if url "$rockfile_location"
	then
	    replace_url_in "$rockfile_location"
	fi
    fi
    
    if check_cloudflare "$url_in"
    then
	get_by_cloudflare "$url_in" html
    else
	html=$(curl -s \
		    -A "$user_agent" \
		    -c "$path_tmp"/cookies.zdl \
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
	
	post_data="${post_data##*document.write\(\&}&${method_free}=Free Download"

	if check_cloudflare "$url_in"
	then
	    get_by_cloudflare "$url_in" html "$post_data"
	else
	    html=$(curl -v                                                                              \
		    -A "$user_agent"                                                                \
		    -b "$path_tmp"/cookies2.zdl                                                     \
		    -c "$path_tmp/cookies3.zdl"                                                     \
		    -D "$path_tmp/header3.zdl"                                                      \
		    -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    		    -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
		    -H 'Accept-Encoding: "gzip, deflate"'                                           \
		    -H "Referer: \"$url_in\""                                                       \
		    -H "Cookie: \"${cookie_cloudflare}\""                                           \
		    -H 'DNT: "1"'                                                                   \
		    -H 'Connection: "keep-alive"'                                                   \
		    -H 'Upgrade-Insecure-Requests: "1"'                                             \
		    -d "$post_data"                                                                 \
		    "$url_in")
	fi

	if grep -P 'You can download files up.+only' <<< "$html" >/dev/null
	then
	    _log 11

	elif [[ "$html" =~ 'have to wait '([0-9]*)[^0-9]*([0-9]*)[^0-9]*([0-9]*)' seconds until' ]]
	then
	    url_in_timer=0
	    time_rematch=( "${BASH_REMATCH[@]}" )

	    if [[ "${time_rematch[1]}" =~ ^[0-9]+$ && "${time_rematch[2]}" =~ ^[0-9]+$ && "${time_rematch[3]}" =~ ^[0-9]+$ ]]
	    then
		url_in_timer=$(( ${time_rematch[1]}*60*60 + ${time_rematch[2]}*60 + $[time_rematch[3]} ))

	    elif [[ "${time_rematch[1]}" =~ ^[0-9]+$ && "${time_rematch[2]}" =~ ^[0-9]+$ ]]
	    then
		url_in_timer=$(( ${time_rematch[1]}*60 + ${time_rematch[2]} ))

	    elif [[ "${time_rematch[1]}" =~ ^[0-9]+$ ]]
	    then
		url_in_timer=$(( ${time_rematch[1]} ))
	    fi
	    
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
		    timer=$(grep -P 'Wait <span.+span> Seconds' <<< "$html" |
				sed -r 's|.+>([0-9]+)<.+|\1|g')

		    countdown- $timer
		    sleeping 2

		    if check_cloudflare "$url_in"
		    then
			get_by_cloudflare "$url_in" html "$post_data"

			url_in_file=$(grep -P '[^\#]+btn_downloadLink' <<< "$html"  |
					  sed -r 's|.+href=\"([^"]+)\".+|\1|g')
			url_in_file=$(sanitize_url "$url_in_file")

		    else
			url_in_file=$(curl "${url_in}"                             \
					   -b "$path_tmp"/cookies2.zdl             \
					   -A "$user_agent"                        \
					   -d "$post_data"                           |
					  grep -P '[^\#]+btn_downloadLink'        |
					  sed -r 's|.+href=\"([^"]+)\".+|\1|g')
			url_in_file=$(sanitize_url "$url_in_file")
		    fi
		fi

	    else
		print_c 3 "Pseudo-captcha: codice non trovato"

		if [[ "$html" =~ google.+recaptcha ]]
		then
		    url_in_timer=true
		    _log 36

		else
		    _log 2
		fi
	    fi
	fi

    else
	_log 2
    fi


    if url "$url_in_file" &&
	    [ -z "$file_in" ] ||
		[[ "$file_in" =~ (input type) ]]	 
    then
	file_in="${url_in_file##*\/}"
    fi
    
    try_end=25
    [ -n "$premium" ] &&
	print_c 2 "Rockfile potrebbe aver attivato il captcha: in tal caso, risolvi prima i passaggi richiesti dal sito web" ||
	    [ -n "$url_in_timer" ] ||
	    end_extension
fi

