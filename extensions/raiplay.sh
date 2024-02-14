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
## zdl-extension name: RaiPlay (HD), RaiCultura (HD), RaiScuola (HD), Rai... (HD)


if [[ "$url_in" =~ (raiplay|rai[a-z]*\.it) ]]
then
    unset raiplay_url raiplay_json

    # if [[ "$url_in" =~ \/collezioni\/ ]]
    # then

    if check_livestream "$url_in" ## in libs/extension_utils.sh
    then
        raiplay_json=$(curl -s \
                            -c "$path_tmp"/cookies.zdl \
                            -A "$user_agent" \
                            "${url_in%\#*}.json")

        if [[ ! "$raiplay_json" =~ content_url ]] &&
               [[ "$raiplay_json" =~ first_item_path ]]
        then
            raiplay_url="${raiplay_json#*first_item_path \": \"}"
            raiplay_url="https://www.raiplay.it${raiplay_url%%\"*}"

            raiplay_json=$(curl -s \
                                -b "$path_tmp"/cookies.zdl \
                                -A "$user_agent" \
                                "$raiplay_url")
        fi

        raiplay_url="${raiplay_json#*content_url\":}"
        raiplay_url="${raiplay_url#*\"}"
        raiplay_url="${raiplay_url%%\"*}&output=64"

        raiplay_url=$(curl -s \
                           -b "$path_tmp"/cookies.zdl \
                           -c "$path_tmp"/cookies2.zdl \
                           -A "$user_agent" \
                           "$raiplay_url" |
                          grep -P '\[')

        raiplay_url=$(grep -oP 'https[^\[\]]+' <<< "$raiplay_url")

        if ! url "$url_in_file" &&
                [[ "$raiplay_url" =~ \.m3u8 ]]
        then
            # url_in_file="${raiplay_url//output=64/output=45}"
            url_in_file="${raiplay_url}"
        fi

        if ! url "$url_in_file"
        then
            get_language_prog
	    url_in_file=$(get_location "$raiplay_url")
            get_language
        fi
        
        if ! url "$url_in_file"
        then
            get_language_prog
            url_in_file=$(wget -SO- "$raiplay_url" -o /dev/null 2>&1 |
                              grep ocation)
            get_language
        fi

        if ! url "$url_in_file"
        then
            url_in_file=$($youtube_dl --get-url "${url_in%\#*}" | head -n1)
            
        fi
	get_livestream_start_time "$url_in" rai_start_time

	get_livestream_duration_time "$url_in" rai_duration_time
	rai_start_time="${rai_start_time//\:tomorrow}"
	
        file_in="${raiplay_json#*\"name\":\"}"
        file_in="${file_in%%\"*}"

        sanitize_file_in
        file_in="${file_in%.mp4}"_$(date +%Y-%m-%d)_dalle_$(date +%H-%M-%S)__prog_inizio_${rai_start_time//\:/-}_durata_${rai_duration_time//\:/-}.mp4

	if [ -n "$rai_duration_time" ]
	then
	    print_c 4 "Diretta Rai dalle $rai_start_time per la durata di $rai_duration_time"
	    livestream_m3u8="$url_in"
            
            
	else
	    [ -n "$gui_alive" ] &&
		check_linksloop_livestream ||
		    _log 43
	fi
	
    else
        if [[ "$url_in" =~ (^.+\/(collezioni|programmi)\/[^\/]+) ]]
        then
            raiplay_json_url="${BASH_REMATCH[1]}".json

            raiplay_seasons_path=(
                $(curl -s "$raiplay_json_url" \
                       -A "$user_agent" |
                      grep -oP '[^"]+ContentSet[^"]+\.json')
            )

            for ((i=0; i<${#raiplay_seasons_path[@]}; i++))
            do
                raiplay_episodes_path=(
                    $(curl -s "https://www.raiplay.it${raiplay_seasons_path[$i]}" |
                          grep -oP '\/video\/[^"]+\.json' |
                          grep -v '/info/')
                )

                for ((j=0; j<${#raiplay_episodes_path[@]}; j++))
                do                   
                    if [ -z "$first" ] &&
                           url "https://www.raiplay.it${raiplay_episodes_path[$j]}"
                    then
                        replace_url_in "https://www.raiplay.it${raiplay_episodes_path[$j]}"
                        first=true
                    else
                        set_link + "https://www.raiplay.it${raiplay_episodes_path[$j]}"
                    fi
                    print_c 4 "https://www.raiplay.it${raiplay_episodes_path[$j]}"
                done
            done
            unset first

        elif [[ ! "$url_in" =~ (^.+\/video\/[^\/]+) ]]
        then
            # raicultura
            html=$(curl -s \
                        -A "$user_agent" \
                        -c "$path_tmp"/cookies.zdl \
                        "$url_in")
            raiplay_json="$html"

            file_in=$(htmldecode "$(get_title "$html")").mp4
            sanitize_file_in
            
            raiplay_url=$(grep -oP 'http[^"]+relinker[^"]+\&\#x3D\;[^&]+' <<< "$html")
            raiplay_url="${raiplay_url//&#x3D;/=}"

            url "$raiplay_url" ||
                raiplay_url=$(grep -oP 'http[^"]+relinker[^"]+' <<< "$html")


            if ! url "$raiplay_url"
            then

                raiplay_url=$(grep -oP '[^"]+iframe.html[^"]+' <<< "$html")
                link_parser "$url_in"
                raiplay_url="${parser_proto}${parser_domain}${raiplay_url}"

                html=$(curl -s \
                            -A "$user_agent" \
                            -c "$path_tmp"/cookies.zdl \
                            "$raiplay_url")
                raiplay_json="$html"
                raiplay_url=$(grep -oP 'http[^"]+relinker[^"]+' <<< "$html")                
            fi           
        fi

        if [[ "$url_in" =~ (^.+\/video\/[^\/]+) ]]
        then
            if ! url "$raiplay_url" || [ -z "$raiplay_json" ]
            then
                raiplay_json=$(curl -s "${url_in%html}json" \
                                    -A "$user_agent" \
                                    -c "$path_tmp"/cookies.zdl)
                
                raiplay_url="${raiplay_json#*content_url\": \"}"
                raiplay_url="${raiplay_url%%\"*}"
            fi

            url_in_file=$(curl -v  "$raiplay_url" -A "$user_agent" 2>&1 | grep location)
            url_in_file="${url_in_file##* }"
            
            url_in_file=$(sanitize_url "$url_in_file")

            if ! url "$url_in_file" &&
                    url "$raiplay_url"
            then
                url_in_file="$raiplay_url"
            fi
            
            if [[ "$raiplay_url" =~ (^http.+relinker.+) ]]
            then

                file_in="${raiplay_json#*name\": \"}"
                file_in="${file_in%%\"*}"
                
                if [ -n "$file_in" ]
                then
                    file_in="${file_in}".mp4
                fi
            fi
        fi

        if ! url "$url_in_file"
        then
            if url "$raiplay_url"
            then
                get_language_prog
                url_in_file=$(get_location "$raiplay_url")
                get_language
            fi
            raiplay_data_json=$($youtube_dl --dump-json \
                                           "$url_in")
            #echo "json: $raiplay_data_json"

            episode_number=$(grep -oP 'episode_number\": [0-9]+' <<< "$raiplay_data_json")
            episode_number="${episode_number##* }"
            season_number=$(grep -oP 'season_number\": [0-9]+' <<< "$raiplay_data_json")
            season_number="${season_number##* }"
            if [ "${season_number}x${episode_number}" != x ]
            then
                file_in_prefix="${season_number}x$(printf "%.2d" ${episode_number})"
            fi
            url_in_file="${raiplay_data_json##*\"manifest_url\": \"}"
            url_in_file="${url_in_file%%\"*}"
            
            file_in="${raiplay_data_json##*\"title\": \"}"
            file_in="${file_in_prefix}_-_${file_in%%\"*}".mp4
        fi
        # if ! url "$url_in_file"
        # then
        #     raiplay_data=$($youtube_dl --get-url \
        #                              --all-formats \
        #                              --get-filename \
        #                              "$url_in")
                              
        #     url_in_file=$(tail -n2 <<< "$raiplay_data" | head -n1) 
        #     file_in=$(tail -n1 <<< "$raiplay_data")
        # fi
    
        if ! url "$url_in_file"
        then
            _log 45
        fi       

        if [ -z "$file_in" ]
        then
            file_in="${raiplay_json#*name\": \"}"
            file_in="${file_in%%\"*}"

            if [ -n "$file_in" ]
            then
                file_in="${file_in%.mp4}".mp4
            fi
        fi

        if [ -z "$file_in" ]
        then
            file_in=$(get_title "$html"|head -n1)

            if [ -n "$file_in" ]
            then
                file_in="${file_in%.mp4}".mp4
            fi
        fi
    fi

    unset youtubedl_m3u8

    force_dler FFMpeg
    #downwait_extra=20
    
    end_extension
fi
									   

