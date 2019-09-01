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

if [[ "$url_in" =~ xxxxx'jheberg.net'.+captcha ]]
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
	 "$url_in"                               \
    	 -qO /dev/null
    
    wget --load-cookies="$path_tmp/cookies.zdl"  \
	 --keep-session-cookies                  \
    	 --save-cookies="$path_tmp/cookies2.zdl" \
    	 --user-agent="$user_agent"              \
    	 "$MIRRORS"                              \
	 -qO /dev/null

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

    if [[ "$reurl" =~ jheberg\.net\/js\/utils\.js ]]
    then
	_log 2

    else
	replace_url_in "$reurl" ||
	    _log 2    
    fi
fi

if [[ "$url_in" =~ 'jheberg.net' ]]
then
    if [[ "$url_in" =~ captcha ]]
    then
	replace_url_in https://download.jheberg.net"${url_in#*captcha}"
    fi
    url_jheberg="${url_in//\.net/.net\/redirect}"
    url_jheberg="${url_jheberg%%\/}"

    hosters=( "Free" "Mega" "UpToBox" "Openload" )
    hoster_ids=( "109" "100" "88" "96" )

    ## Di seguito: codice necessario per raggiungere la pagina web con l'elenco degli host
    ## MA serve un interprete javascript come phantomjs e tanto codice in più per estrarre i nuovi link.
    ## Gli hoster_ids, ricavati empiricamente, dei relativi hosters, ci permettono di evitare queste operazioni
    ## troppo onerose e complesse, comunque da conservare per ulteriori sviluppi
    ##
    #
    # curl -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
    # 	 -H 'Accept-Encoding: gzip, deflate, br' \
    # 	 -H 'Accept-Language: it,en-US;q=0.7,en;q=0.3' \
    # 	 -H 'Connection: keep-alive' \
    # 	 -H 'Host: download.jheberg.net' \
    # 	 -H 'Upgrade-Insecure-Requests: 1' \
    # 	 -c "$path_tmp/cookies.zdl"  \
    # 	 -A "$user_agent"              \
    # 	 "$url_in" \
    # 	 -so /dev/null 
    #
    # curl -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
    # 	 -H 'Accept-Encoding: gzip, deflate, br' \
    # 	 -H 'Accept-Language: it,en-US;q=0.7,en;q=0.3' \
    # 	 -H 'Connection: keep-alive' \
    # 	 -H 'Cookie: tz=Europe/Rome' \
    # 	 -H 'Host: download.jheberg.net' \
    # 	 -H "Referer: $url_in" \
    # 	 -H 'Upgrade-Insecure-Requests: 1' \
    # 	 -A "$user_agent"              \
    # 	 -c "$path_tmp/cookies2.zdl" \
    # 	 "${url_in//\.net/.net\/go}" \
    # 	 -v /dev/null

    index_hosters=0
    for id in ${hoster_ids[@]}
    do	
	reurl=$(wget -S --user-agent="$user_agent"                   \
		     --header='X-Requested-With: XMLHttpRequest'  \
		     "${url_jheberg}-$id" -qO- 2>&1)

	reurl=$(grep 'X-Jheberg-Location:' <<< "$reurl")
	reurl="${reurl#*X-Jheberg-Location: }"
	get_language
	print_c 4 "$(gettext "Checking") ${hosters[$index_hosters]}: ${url_jheberg}-$id"
	get_language_prog
	if url "$reurl"
	then	   
	    break	    
	fi
	((index_hosters++))
    done

    replace_url_in "$reurl" ||
	_log 2    
fi    
