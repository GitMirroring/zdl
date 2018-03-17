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
## ZDL add-on
## zdl-extension types: streaming
## zdl-extension name: Dplay (HD)


if [[ "$url_in" =~ dplay\. ]]
then
    html=$(wget --user-agent="$user_agent" -qO- "$url_in" -o /dev/null)    

    dplayJSON=$(grep 'JSON.parse' <<< "$html")
    dplayJSON=${dplayJSON#*\"}
    dplayJSON=${dplayJSON%\"*}
    dplayJSON=$(echo -e "$dplayJSON" | tr -d '\')
    
    url_in_file=$(nodejs -e "var json = $dplayJSON; console.log(json.data.attributes.streaming.hls.url)")
    __in_file=$(curl -s "$url_in_file" |tail -n1)

    #echo -e "$url_in_file\n$__in_file"
    
    if grep -q URI <<< "$__in_file"
    then
	# __in_file="${__in_file%\"}"
	# __in_file="${__in_file##*\"}"
	# url_in_file="${url_in_file%\?*}"
	# url_in_file="${url_in_file%\/*}/${__in_file}"
	# curl -A Firefox -v "$url_in_file" -o OUT
	unset url_in_file file_in
	_log 32
	
    else 
	url_in_file=$(sed -r "s|[^/]+m3u8|$__in_file|g" <<< "$url_in_file") 
    fi
    
    file_in="${url_in%\/*}"
    file_in="${file_in##*\/}"

    end_extension
fi
									   

