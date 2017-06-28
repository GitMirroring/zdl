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
## zdl-extension name: MultiUp (multi-link)

if [[ "$url_in" =~ multiup\. ]]
then
    url_1="${url_in//en\/}"
    url_1="${url_1//download\/}"
    html=$(curl "${url_1}")

    if [[ "$url_in" =~ download\/ ]] &&
	   [[ ! "$url_in" =~ en\/ ]]
    then
	html=$(curl "$url_in")
    fi	

    if [[ "$html" =~ (File not found) ]]       
    then
	_log 3
	
    else
	link_parser "$url_in"
	url_2="${parser_proto}${parser_domain}"/en/mirror/$(grep mirror <<< "$html" |tail -n1 |
						       sed -r 's|.+mirror\/([^"]+)\"[^"]+|\1|g')

	html=$(curl "${url_2}")

	for service in '\/\/clicknupload.' 'mega\.nz\/\#' 'uptobox.com\/' 'openload\.co\/'
	do
	    url_in_tmp=$(grep -P "http.+$service" <<< "$html"|
				sed -r 's|[^"]+\"([^"]+)\".*|\1|g')

	    if url "$url_in_tmp"
	    then
		case "$service" in
		    'uptobox.com\/')
			extension_uptobox "$url_in_tmp"
			;;
		    '\/\/clicknupload.')
			extension_clicknupload "$url_in_tmp"
			;;
		    'mega.nz\/\#') 
			extension_mega "$url_in_tmp"
			;;
		    'openload\.co\/')
			extension_openload "$url_in_tmp"
			;;
		esac
		
 		url "$url_in_file" &&
		    break
	    fi
	done

	replace_url_in "$url_in_tmp"

	[[ "$url_in" =~ multiup\. ]] &&
	    _log 2
    fi	
fi
	    
