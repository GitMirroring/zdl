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
## zdl-extension name: Jheberg (multi-link)

if [[ "$url_in" =~ 'jheberg.net' ]]
then
    MIRRORS="${url_in//captcha/mirrors}"
    REDIRECT="${MIRRORS//mirrors/redirect}"
    GETLINK="http://www.jheberg.net/get/link/"

    slug="${url_in%%\/}"
    slug="${slug##*\/}"

    hosters=( "Free" "Mega" "UpToBox" "Openload" )

    wget --keep-session-cookies                  \
    	 --save-cookies="$path_tmp/cookies.zdl"  \
    	 --user-agent="$user_agent"              \
	 "$url_in" \
    	 -qO /dev/null

    wget --load-cookies="$path_tmp/cookies.zdl"  \
	 --keep-session-cookies                  \
    	 --save-cookies="$path_tmp/cookies2.zdl"  \
    	 --user-agent="$user_agent"              \
    	 "$MIRRORS"  

    countdown- 5 

    for hoster in ${hosters[@]}
    do
	reurl=$(wget --keep-session-cookies                       \
		     --load-cookies="$path_tmp/cookies.zdl"       \
		     --user-agent="$user_agent"                   \
		     --referer="$REDIRECT"                        \
		     --header="$cookies_jheberg"  \
		     --header='X-Requested-With: XMLHttpRequest'  \
		     --post-data="slug=${slug}&hoster=${hoster}"  \
		     "$GETLINK" -qO-)

	reurl="${reurl%\"*}"
	reurl="${reurl##*\"}"

	url "$reurl" &&
	    [[ ! "$reurl" =~ utils.js ]] &&
	    break
    done

    replace_url_in "$reurl" ||
	_log 2
fi
