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
## zdl-extension name: Filecrypt.cc

if [ "$url_in" != "${url_in//filecrypt.cc}" ]
then
    # unset redir_filecrypt location_filecrypt
    # get_language_prog

    # html=$(curl -s \
    #             -c "$path_tmp"/cookies.zdl \
    #             "$url_in" 2>&1)
    
    # get_language

    # codes_filecrypt=( $(grep -oP "openLink\(\'[^']+" <<< "$html" |
    #                        sed -r "s|openLink\('||g") )

    # if (( "${#codes_filecrypt[@]}" >0 ))
    # then
    #     for code_filecrypt in "${codes_filecrypt[@]}"
    #     do
    # 	    url_filecrypt="https://filecrypt.cc/Link/${code_filecrypt}.html"

    #         html=$(curl -s \
    #                     -b "$path_tmp"/cookies.zdl \
    #                     -c "$path_tmp"/cookies2.zdl \
    #                     "$url_filecrypt" 2>&1)

    #         url_filecrypt=$(grep -oP "top.location.href=\'[^']+" <<< "$html")
    #         url_filecrypt="${url_filecrypt##*\'}"

    #         if url "$url_filecrypt"
    #         then
    #             _log 34 "$url_filecrypt"            

    #             get_language_prog

    #             location_filecrypt=$(curl -v \
    #                                       -b "$path_tmp"/cookies.zdl \
    #                                       -c "$path_tmp"/cookies2.zdl \
    #                                       "$url_filecrypt" 2>&1 |
    #                                      awk "/location/{print \$3}")
    #             get_language

    #             location_filecrypt=$(trim "$location_filecrypt")

    #             unset filecrypt_flag
                
    #             if url "$location_filecrypt"
    #             then
    #                 if ( [ -n "$no_url_regex" ] && [[ "$location_filecrypt" =~ $no_url_regex ]] ) ||
    #                        ( [ -n "$url_regex" ] && [[ ! "$location_filecrypt" =~ $url_regex ]] )    
    #                 then                    
    #                     continue
    #                 fi
    #     	    set_link + "$location_filecrypt" &&
    #                     filecrypt_flag=true

    #                 get_language
    #     	    print_c 4 "$(gettext "Redirection"): $location_filecrypt"
    #     	    get_language_prog
		    
    #     	    url "$redir_filecrypt" ||
    #                     [[ "$redir_filecrypt" =~ filecrypt\.cc ]] ||
    #                     redir_filecrypt="$location_filecrypt"
    #             fi
    #         fi
    #     done

    #     [ -z "$filecrypt_flag" ] && set_link - "$url_in"
        
    #     if url "$redir_filecrypt"
    #     then
    #         replace_url_in "$redir_filecrypt"

    #         print_links_txt

    #         get_language
    #         print_c 4 "$(gettext "New link to process"): $url_in"
    #         get_language_prog
    #     fi
    # else
    #     _log 36
    # fi
    #end_extension &>/dev/null
    
    container_code=$(curl -s "$url_in" | grep dlcdownload)
    container_code="${container_code##*\(\'}"
    container_code="${container_code%%\'\)*}"

    if [ -n "$container_code" ]
    then
        set_link - "$url_in"
        container_url=https://filecrypt.cc/DLC/"$container_code".dlc
        print_c 4 "Container DLC URL: $container_url"
        container_ncrypt=$(mktemp)
        wget -qO "$container_ncrypt" "$container_url"
        add_container "$container_ncrypt"
 
    else
        print_c 3 "$url_in --> $(gettext "Unsupported download: enter the captcha code using a web browser")"
        _log 25
    fi
    break_loop=true
fi
