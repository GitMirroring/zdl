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
## zdl-extension name: Rapidcrypt

if [ "$url_in" != "${url_in//rapidcrypt.net}" ]
then
    if [[ "$url_in" =~ \/wstm\/ ]]
    then
	html=$(wget -qO- "$url_in")
	rapidcrypt_link=$(grep 'Download file' <<< "$html" |
			      sed -r 's|.+href=\"([^"]+)\".+|\1|g')
	url "$rapidcrypt_link" &&
	    replace_url_in "$rapidcrypt_link" ||
		_log 2
	
    else
	for i in 0 1
	do
	    if check_cloudflare "$url_in"
	    then
		get_by_cloudflare "$url_in" html

	    else
		html=$(curl -s "$url_in")
		if [ -z "$html" ]
		then
		    html=$(wget -o /dev/null -qO- "$url_in")
		fi
	    fi

	    url_rapidcrypt=$(grep -P 'Click [Tt]{1}o [Cc]{1}ontinue' <<< "$html" |
				 sed -r 's|.+href=\"([^"]+)\".+|\1|g')

	    if ! url "$url_rapidcrypt"
	    then
		url_rapidcrypt=$(grep -P 'Click [Tt]{1}o [Cc]{1}ontinue' <<< "$html" |
				     sed -r 's|.+href=([^>]+)>.+|\1|g')
	    fi

	    if ! url "$url_rapidcrypt"
	    then
		url_rapidcrypt=$(grep -P "Click [Tt]{1}o [Cc]{1}ontinue" <<< "$html" |
				     sed -r "s|.+href='([^']+)'.+|\1|g")
	    fi

	    url_rapidcrypt="${url_rapidcrypt%% onClick*}"

	    if url "$url_rapidcrypt" &&
		    [[ "$url_rapidcrypt" != "$url_in" ]]
	    then
		replace_url_in "$url_rapidcrypt"
		break

	    else
		_log 2
	    fi
	done
    fi
fi
