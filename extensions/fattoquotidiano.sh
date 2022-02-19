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
## zdl-extension name: IlFattoQuotidiano

if [[ "$url_in" =~ ilfattoquotidiano ]]
then
    ilfatto_data=$(youtube-dl --get-url --get-filename "$url_in" | grep -P '\.mp4$')

    url_in_file=$(grep -P '^http' <<< "$ilfatto_data" |tail -n1)
    file_in=$(grep -vP '^http' <<< "$ilfatto_data" |tail -n1)

    [[ "$url_in_file" =~ dailymotion ]] ||
        {
            get_location "$url_in_file" url_in_file

            url "$url_in_file" ||
                {
                    json_fattoq=$(youtube-dl --dump-json "$url_in")            
                    url_list_fattoq=$(grep -oP '\"url\":\ \"([^"]+mp4[^"]+)\"' <<< "$json_fattoq" |
                                          sed -r 's|\"url\":\ \"([^"]+mp4[^"]+)\"|\1|g')
                    
                    ## better video only
                    #url_in_file=$(tail -n5 <<< "$url_list_fattoq" | head -n1)
                    
                    ## audio only:
                    #url_in_file=$(head -n1 <<< "$url_list_fattoq" | tail -n1)

                    ## audio + video (low quality)
                    # url_in_file=$(grep _nc_vs <<< "$url_list_fattoq" | head -n1)
                    url_in_file=$(tail -n4 <<< "$url_list_fattoq" | head -n1)
                }
        }
    end_extension
fi


if ( test -z "$file_in" ||
         ! url "$url_in_file" ) &&
       [[ "$url_in" =~ ilfattoquotidiano ]]
then   
    get_language_prog
    html=$(curl -s "$url_in")
    get_language

    url_in_file=$(grep 'playlist: \[' <<< "$html" |
			 sed -r 's|.+\":\"([^"]+\.m3u8)\".+|\1|g' |
			 tr -d '\\' | head -n1)

    if url "$url_in_file"
    then
        print_c 4 "$(gettext "Redirection"): $url_in_file"
        get_language_prog
        url_in_file=$(curl -s "$url_in_file" |
			  grep http |
			  head -n1)
        
	get_language
	print_c 4 "$(gettext "Redirection"): $url_in_file"
    	
        file_in=$(get_title "$html" | head -n1)
        file_filter "$file_in"
        
        end_extension
        
    else   
        url_in_file=$(grep -oP '[^"]+youtube\.com\/embed\/[^"]+' <<< "$html")
        if url "$url_in_file"
        then
            replace_url_in "$url_in_file"
            youtubedl_m3u8="$url_in"
        fi
        unset url_in_file        
    fi
fi
									   



