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
## zdl-extension name: vcrypt

function get_by_cloudflare {
    local url_in="$1"
    declare -n ref="$2"
    
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
	domain="${url_in#*\/\/}"
	domain="${domain%%\/*}"
	get_jschl_answer "$path_tmp"/cloudflare.html "$domain"
	
	input_hidden "$path_tmp"/cloudflare.html

	get_data="${post_data%\&*}&jschl_answer=$jschl_answer"
	cookie_cloudflare=$(awk '/cfduid/{print $6 "=" $7}' "$path_tmp/cookies.zdl")

	countdown- 6

	curl                                                                                \
	    -A "$user_agent"                                                                \
	    -c "$path_tmp/cookies.zdl"                                                      \
	    -D "$path_tmp/header2.zdl"                                                      \
	    -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    	    -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
	    -H 'Accept-Encoding: "gzip, deflate"'                                           \
	    -H 'DNT: "1"'                                                                   \
	    -H "Referer: \"$url_in\""                                                       \
	    -H "Cookie: \"${cookie_cloudflare}\""                                           \
	    -H 'Connection: "keep-alive"'                                                   \
	    -d "$get_data"                                                                  \
	    -G                                                                              \
	    "http://vcrypt.net/cdn-cgi/l/chk_jschl" >/dev/null
	
	
	cookie_cloudflare=$(grep Set-Cookie "$path_tmp/header2.zdl" |
				   cut -d' ' -f2 |
				   tr '\n' ' ')
	cookie_cloudflare="${cookie_cloudflare%';'*}"

	ref=$(curl -v                                                                              \
		   -A "$user_agent"                                                                \
		   -b "$path_tmp/cookies.zdl"                                                      \
		   -c "$path_tmp/cookies2.zdl"                                                     \
		   -D "$path_tmp/header2.zdl"                                                      \
		   -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'  \
    		   -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'                                 \
		   -H 'Accept-Encoding: "gzip, deflate"'                                           \
		   -H 'DNT: "1"'                                                                   \
		   -H "Referer: \"$url_in\""                                                       \
		   -H "Cookie: \"${cookie_cloudflare}\""                                           \
		   -H 'Connection: "keep-alive"'                                                   \
		   "${url_in}" 2>&1)
	
	cookie_cloudflare=$(grep Set-Cookie "$path_tmp/header2.zdl" |
				   cut -d' ' -f2 |
				   tr '\n' ' ')
	cookie_cloudflare="${cookie_cloudflare%';'*}"
    fi
    
}

function get_fastshield {
    declare -n ref="$2"
    local url_fastshield="$1"
    
    if [[ "$url_fastshield" =~ fastshield ]]
    then
	url "$url_fastshield" &&
	    print_c 4 "$url_fastshield" ||
		_log 2
	
	if check_cloudflare "$url_fastshield"
	then
	    get_by_cloudflare "$url_fastshield" html
	fi		
	
	data_vcrypt=$(curl -v "${url_fastshield}" \
	    		   -d 'go=go' \
			   -b "$path_tmp/cookies2.zdl" \
			   -H "Cookie: \"${cookie_cloudflare}\""                                           \
			   -H 'Connection: "keep-alive"'                                                   \
	    		   -A "$user_agent" 2>&1)

	ref=$(grep 'ocation:' <<< "$data_vcrypt" |
	    	     head -n1|
	    	     awk '{print $3}')
	
	ref=$(trim "${ref}")

	url "$ref" &&
	    (
		print_c 4 "$ref" 
		return 0
	    ) ||
		(
		    _log 2
		    return 1
		)
    fi
}

if [ "$url_in" != "${url_in//vcrypt.}" ] &&
       [[ ! "$url_in" =~ vcrypt.+opencrypt ]]
then
    if [[ "$url_in" =~ cryptopen ]]
    then	    
	html=$(curl "$url_in" -s)

	url_vcrypt2=$(grep iframe <<< "$html" |
			     sed -r 's|.+\"([^"]+)\"[^"]+$|\1|g')

	if ! url "$url_vcrypt2"
	then		
	    url_vcrypt2=$(grep Download <<< "$html" |
				 sed -r 's|.+href=\"([^"]+)\".+|\1|g' |head -n1)

	    if ! url "$url_vcrypt2"
	    then
		url_vcrypt2=$(phantomjs "$path_usr"/extensions/vcrypt-phantomjs.js "$url_in")
	    fi
	fi
	replace_url_in "$url_vcrypt2" ||
	    _log 2

    elif [[ "$url_in" =~ cryptop ]]
    then
	html=$(curl "$url_in" -s)
	url_vcrypt2=$(grep Download <<< "$html" |
			     head -n1)

	if [[ "$url_vcrypt2" =~ http ]]
	then
	    url_vcrypt2="${url_vcrypt2##*http}"
	    url_vcrypt2="http${url_vcrypt2%%\"*}"
	    
	    replace_url_in "$url_vcrypt2" ||
		_log 2
	fi

    elif [[ "$url_in" =~ opencryptxx ]]
    then
	html=$(curl "$url_in" -s)
	url_vcrypt2=$(grep Download <<< "$html" |
			     head -n1)

	if [[ "$url_vcrypt2" =~ http ]]
	then
	    url_vcrypt2="${url_vcrypt2##*http}"
	    url_vcrypt2="http${url_vcrypt2%%\"*}"
	    
	    replace_url_in "$url_vcrypt2" ||
		_log 2
	fi

    else    
	[[ "$url_in" =~ \.pw\/ ]] &&
	    replace_url_in "${url_in//.pw\//.net\/}"
	
	url_vcrypt=$(get_location "$url_in")
	url_vcrypt="http${url_vcrypt##*http}"
	
	[[ "$url_vcrypt" =~ http\:\/ ]] &&
	    url_vcrypt="${url_vcrypt//http:/https:}"
	
	if ! url "$url_vcrypt"
	then
	    url_vcrypt=$(curl -v "$url_in"  2>&1                 |
			     grep 'ocation:'                     |
			     awk '{print $3}'                    |
			     sed -r 's|vcrypt\.pw|vcrypt.net|g'  |
			     sed -r 's|http\:|https:|g'          |
			     tail -n1                            |
			     tr -d '\r')
	fi

	if ! url "$url_vcrypt"
	then
	    if check_cloudflare "$url_in"
	    then
		get_by_cloudflare "$url_in" html

		if [[ "$html" =~ [lL]{1}ocation.*\/http ]]
		then
		    url_vcrypt=$(grep -P '[lL]{1}ocation.+\/http' <<< "$html")
		    url_vcrypt="http${url_vcrypt#*\/http}"

		elif [[ "$html" =~ [lL]{1}ocation ]]
		then
		    url_vcrypt=$(grep -P '[lL]{1}ocation.+http' <<< "$html")
		    url_vcrypt="http${url_vcrypt#*http}"
		fi
	    fi
	fi
	
	if url "$url_vcrypt"
	then
	    if [[ "$url_vcrypt" =~ vcrypt ]]
	    then
		if ! get_fastshield "$url_vcrypt" url_vcrypt2
		then
		    
		    url_vcrypt2=$(curl -v "$url_vcrypt" -d 'go=go'    |
					 grep refresh                 |
					 sed -r "s|.+url=([^']+)'.*|\1|g")
		    
		    url_vcrypt2=$(trim "${url_vcrypt2}")

		    if ! url "$url_vcrypt2"
		    then
			url_vcrypt2=$(curl -v "$url_vcrypt" -d 'go=go' 2>&1 |
					  grep 'ocation:'                   |
					  awk '{print $3}')
		    fi
		    
		    url_vcrypt2=$(trim "${url_vcrypt2}")

		    if [[ "$url_vcrypt2" =~ vcrypt ]]
		    then	    
			get_fastshield "$url_vcrypt2" url_vcrypt2
			
			if [[ "$url_vcrypt2" =~ http.*http ]]
			then
			    url_vcrypt2="http${url_vcrypt2##*http}"
			fi
		    fi
		fi
		
	    else
		url_vcrypt2="$url_vcrypt"
	    fi

	    if [[ "$url_vcrypt2" =~ opencryptz ]]
	    then
		if check_cloudflare "$url_vcrypt2"
		then
		    get_by_cloudflare "$url_vcrypt2" html

		else
		    html=$(curl -A "$user_agent" "$url_vcrypt2")
		fi
		
		url_vcrypt2=$(grep Download <<< "$html" |
				     head -n1)
		
		url "$url_vcrypt2" ||
		    url_vcrypt2=$(grep -P '.+\"http[s]*\:[^"]+\".+' <<< "$html" |
					 sed -r 's|.+\"(http[s]*:[^"]+)\".+|\1|g')

		if [[ "$url_vcrypt2" =~ http ]]
		then
		    url_vcrypt2="${url_vcrypt2##*http}"
		    url_vcrypt2="http${url_vcrypt2%%\"*}"
		fi
	    fi

	    
	    url_vcrypt2=$(trim "${url_vcrypt2}")
	    
	    url "$url_vcrypt2" &&
		replace_url_in "$url_vcrypt2" ||
		    _log 2
	else
	    _log 2
	fi
    fi
fi

if [[ "$url_in" =~ vcrypt.+opencrypt ]]
then    
    check_cloudflare "$url_in" &&
	get_by_cloudflare "$url_in" html ||
	    html=$(curl "$url_in")

    url_vcrypt=$(grep Download <<< "$html" |head -n1)
    url_vcrypt="${url_vcrypt#*\"}"
    url_vcrypt="${url_vcrypt%%\"*}"
    replace_url_in "$url_vcrypt" ||
	_log 2
fi
