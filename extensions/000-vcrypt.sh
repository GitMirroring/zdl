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
       [[ ! "$url_in" =~ fastshield ]] #&&       [[ ! "$url_in" =~ vcrypt.+opencrypt ]]
then
    # if [[ "$url_in" =~ cryptopen ]]
    # then	    
    # 	html=$(curl "$url_in" -s)

    # 	url_vcrypt2=$(grep iframe <<< "$html" |
    # 			     sed -r 's|.+\"([^"]+)\"[^"]+$|\1|g')

    # 	if ! url "$url_vcrypt2"
    # 	then		
    # 	    url_vcrypt2=$(grep Download <<< "$html" |
    # 				 sed -r 's|.+href=\"([^"]+)\".+|\1|g' |head -n1)

    # 	    if ! url "$url_vcrypt2"
    # 	    then
    # 		url_vcrypt2=$(phantomjs "$path_usr"/extensions/vcrypt-phantomjs.js "$url_in")
    # 	    fi
    # 	fi
    # 	replace_url_in "$url_vcrypt2" ||
    # 	    _log 2

    # elif [[ "$url_in" =~ cryptop ]]
    # then
    # 	html=$(curl "$url_in" -s)
    # 	url_vcrypt2=$(grep Download <<< "$html" |
    # 			     head -n1)

    # 	if [[ "$url_vcrypt2" =~ http ]]
    # 	then
    # 	    url_vcrypt2="${url_vcrypt2##*http}"
    # 	    url_vcrypt2="http${url_vcrypt2%%\"*}"
	    
    # 	    replace_url_in "$url_vcrypt2" ||
    # 		_log 2
    # 	fi

    # elif [[ "$url_in" =~ opencryptxx ]]
    # then
    # 	html=$(curl "$url_in" -s)
    # 	url_vcrypt2=$(grep Download <<< "$html" |
    # 			     head -n1)

    # 	if [[ "$url_vcrypt2" =~ http ]]
    # 	then
    # 	    url_vcrypt2="${url_vcrypt2##*http}"
    # 	    url_vcrypt2="http${url_vcrypt2%%\"*}"
	    
    # 	    replace_url_in "$url_vcrypt2" ||
    # 		_log 2
    # 	fi

    # else    
    [[ "$url_in" =~ \.pw\/ ]] &&
	replace_url_in "${url_in//.pw\//.net\/}"

    url_vcrypt=$(get_location "$url_in")
    url_vcrypt="http${url_vcrypt##*http}"

    if [[ "$url_vcrypt" =~ (vcrypt.+banned) ]]
    then
	_log 39

    else
	[[ "$url_vcrypt" =~ http\:\/ ]] &&
	    url_vcrypt="${url_vcrypt//http:/https:}"

	if ! url "$url_vcrypt"
	then
	    url_vcrypt=$(curl -v "$url_in"                 \
			      -c "$path_tmp"/cookies.zdl   \
			      2>&1                               |
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
		get_location_by_cloudflare "$url_in" url_in_location

		if url "$url_in_location"
		then
		    if [[ "$url_in" =~ vcrypt ]]
		    then
			url_vcrypt="$url_in_location"
		    else
			unset url_vcrypt
			replace_url_in "$url_in_location"
		    fi
		else
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
	fi
		
	if url "$url_vcrypt"
	then
	    if [[ "$url_vcrypt" =~ vcrypt ]]
	    then
		if ! get_fastshield "$url_vcrypt" url_vcrypt2
		then
		    url_vcrypt2=$(curl -v "$url_vcrypt" -d 'go=go' \
				       -b "$path_tmp"/cookies.zdl     |
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
		else
		    url_vcrypt2="$url_vcrypt"
		fi
	    else
		url_vcrypt2="$url_vcrypt"
	    fi

	    if [[ "$url_vcrypt2" =~ opencryptz ]]
	    then
		while [[ "$url_vcrypt2" =~ (opencryptz|cloudflare) ]]
		do
		    if check_cloudflare "$url_vcrypt2"
		    then
			get_location_by_cloudflare "$url_vcrypt2" url_vcrypt2_location ||
			    get_by_cloudflare "$url_vcrypt2" html

		    else
			html=$(curl -A "$user_agent" "$url_vcrypt2")
		    fi

		    if url "$url_vcrypt2_location"
		    then
			url_vcrypt2="$url_vcrypt2_location"
			unset url_vcrypt2_location

		    else
			url_vcrypt2=$(grep Download <<< "$html" |
					     head -n1)
		    fi
		    
		    url "$url_vcrypt2" ||
			url_vcrypt2=$(grep -P '.+\"http[s]*\:[^"]+\".+' <<< "$html" |
					     sed -r 's|.+\"(http[s]*:[^"]+)\".+|\1|g')

		    if [[ "$url_vcrypt2" =~ http ]]
		    then
			url_vcrypt2="${url_vcrypt2##*http}"
			url_vcrypt2="http${url_vcrypt2%%\"*}"
		    fi
		done
	    fi

	    
	    url_vcrypt2=$(trim "${url_vcrypt2}")
	    
	    url "$url_vcrypt2" &&
		replace_url_in "$url_vcrypt2" ||
		    _log 2

	elif [[ "$url_in" =~ vcrypt ]]
	then
	    _log 2
	fi
    fi


elif [ "$url_in" != "${url_in//vcrypt.}" ]
then
    wget --keep-session-cookies \
	 --save-cookies="$path_tmp"/cookies.zdl \
	 --user-agent="$user_agent" \
	 -o /dev/null \
	 "$url_in" -SO /dev/null
	 
    wget --post-data="go=go" \
	 --load-cookies="$path_tmp"/cookies.zdl \
	 "$url_in" -SO /dev/null \
	 -o "$path_tmp"/vcrypt_fastshield_redirect.txt

    url_fastshield_location=$(grep ocation "$path_tmp"/vcrypt_fastshield_redirect.txt |
				     tail -n1 |
				     cut -d' ' -f2)
    
    url_fastshield_location=$(trim "$url_fastshield_location")

    replace_url_in "$url_fastshield_location" ||
	_log 2
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
