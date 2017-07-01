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

    hosters=( "Mega" "UpToBox" "Openload" )

    # wget --keep-session-cookies                  \
    # 	 --save-cookies="$path_tmp/cookies.zdl"  \
    # 	 --user-agent="$user_agent"              \
    # 	 --referer="$MIRRORS"                    \
    # 	 "$REDIRECT" -qO /dev/null

    #    headers_jheberg="Accept-Language: \"it,en-US;q=0.7,en;q=0.3\""
    #headers_jheberg=
    
    cookies_jheberg=$(phantomjs "$path_usr"/extensions/jheberg.js "$url_in" | tail -n1)
    # curl -v                           \
    # 	 -A "$user_agent"             \
    # 	 -H 'Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"' \
    # 	 -H 'Accept-Language: "it,en-US;q=0.7,en;q=0.3"'  \
    # 	 -H 'Accept-Encoding: "gzip, deflate"'  \
    # 	 -H "DNT: \"1\"" \
    # 	 -H "Connection: \"keep-alive\"" \
    # 	 -H "Upgrade-Insecure-Requests: \"1\"" \
    # 	 -c "$path_tmp/cookies.zdl"   \
    # 	 "$url_in"  >out
    
    #################
    # curl -v                           \
    # 	 -H "User-Agent: \"$user_agent\""             \
    # 	 -H "Accept: \"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\"" \
    # 	 -H "Accept-Language: \"it,en-US;q=0.7,en;q=0.3\""   \
    # 	 -H "Accept-Encoding: \"gzip, deflate\""             \
    # 	 -H "Referer: \"$url_in\""                         \
    # 	 -H "Cookie: \"$cookies_jheberg\""                 \
    # 	 -H "DNT: \"1\""                                   \
    # 	 -H "Connection: \"keep-alive\""                   \
    # 	 -H "Upgrade-Insecure-Requests: \"1\""             \
    # 	 "$MIRRORS" 2>&1 1>out

    # curl -v \
    # 	 -H "User-Agent: \"$user_agent\""             \
    # 	 -H "Accept: \"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\"" \
    # 	 -H "Accept-Language: \"it,en-US;q=0.7,en;q=0.3\""   \
    # 	 -H "Accept-Encoding: \"gzip, deflate\""             \
    # 	 -H "Referer: \"$mirrors\""                         \
    # 	 -H "Cookie: \"$cookies_jheberg\""                 \
    # 	 -H "DNT: \"1\""                                   \
    # 	 -H "Connection: \"keep-alive\""                   \
    # 	 -H "Upgrade-Insecure-Requests: \"1\""             \
    # 	 "$url_in" 2>&1 1>out2

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
#echo "reurl: $reurl"
	reurl="${reurl%\"*}"
	reurl="${reurl##*\"}"

	url "$reurl" && break
    done

    replace_url_in "$reurl" ||
	_log 2
fi
