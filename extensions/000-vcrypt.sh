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

if [ "$url_in" != "${url_in//vcrypt.}" ]
then
    url_vcrypt=$(get_location "$url_in")
    url_vcrypt="http${url_vcrypt##*http}"
    
    if [[ ! "$url_vcrypt" =~ vcrypt ]] &&
	   url "$url_vcrypt"
    then
	replace_url_in "$url_vcrypt" ||
	    _log 2
    else
	url_vcrypt=$(curl -v "$url_in"  2>&1                 |
			 grep 'ocation:'                     |
			 awk '{print $3}'                    |
			 sed -r 's|vcrypt\.pw|vcrypt.net|g'  |
			 sed -r 's|http\:|https:|g'          |
			 tail -n1                            |
			 tr -d '\r')
				    
	url_vcrypt2=$(curl -v "$url_vcrypt" -d 'go=go'   |
			    grep refresh                 |
			    sed -r "s|.+url=([^']+)'.*|\1|g")

	if ! url "$url_vcrypt2"
	then
	    url_vcrypt2=$(curl -v "$url_vcrypt" -d 'go=go' 2>&1 |
			      grep 'ocation:'                   |
			      awk '{print $3}')
	fi

	url_vcrypt2=$(trim "${url_vcrypt2}")7
	
	if [[ "$url_vcrypt2" =~ fastshield ]]
	then
	    data_vcrypt=$(curl -v "$url_vcrypt2" \
			       -d 'go=go' \
			       -A "$user_agent" 2>&1)
			  
	    url_vcrypt2=$(grep 'ocation:' <<< "$data_vcrypt" |
				 head -n1|
				 awk '{print $3}')
	fi
	
	if [[ "$url_vcrypt2" =~ http.*http ]]
	then
	    url_vcrypt2="http${url_vcrypt2##*http}"
	fi
	
	replace_url_in "$url_vcrypt2" ||
	    _log 2

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
	fi
    fi
fi

