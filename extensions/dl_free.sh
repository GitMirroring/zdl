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
## zdl-extension name: dl.free.fr


if [[ "$url_in" =~ dl\.free\.fr ]]
then
    if [[ ! "$url_in" =~ getfile ]]
    then
	get_location "$url_in" url_dl_free_get_file
	url "$url_dl_free_get_file" && replace_url_in "${url_dl_free_get_file//=\/?/=/}"
    fi
	
    file_in=$(curl -s "$url_in" |
		  grep Fichier | tail -n1 |
		  sed -r 's|.+\">([^<>]+)<\/span.+|\1|g')
    
    
    url_in_file=$(curl -c "$path_tmp"/cookies.zdl \
     		       -d "file=/${url_in##*\/}&send=Valider+et+télécharger+le+fichier" \
     		       http://dl.free.fr/getfile.pl 2>&1 |
		      grep HREF |
		      sed -r 's|.+\"([^"]+)\".+|\1|g')
    
    [[ "$file_in" =~ (Fichier inexistant) ]] && _log 3
    end_extension
fi
