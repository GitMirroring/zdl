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
## zdl-extension types: streaming download
## zdl-extension name: WStream (HD)

if [[ "$url_in" =~ wstream\. ]] 
then
    if [[ "$url_in" =~ http[s]*://[w.]*wstream ]]
    then
	wstream_link="${url_in//\/\/wstream/\/\/download.wstream}"
	wstream_link="${wstream_link//\/video\//\/}"
	wstream_link="http${wstream_link#https}"
	
    elif [[ "$url_in" =~ download\.wstream ]]
    then
	wstream_link="$url_in"
    fi
	
    if url "$wstream_link"
    then
	[ "$url_in" == "$wstream_link" ] ||
	    print_c 4 "Reindirizzamento: $url_in -> $wstream_link"
	html=$(wget -qO- \
		    -o /dev/null \
		    --keep-session-cookies \
		    --save-cookies="$path_tmp"/cookies.zdl \
		    "$wstream_link")
	
	##### per ora è solo client, quindi è commentato:
	## countdown- 5

	file_in=$(get_title "$html" |head -n1)
	file_in="${file_in#Download Free}"
	
	wstream_req=$(grep -oP 'downloadlink.php?[^"]+' <<< "$html")
	if [ -n "$wstream_req" ]
	then
	    for proto in http https
	    do
		print_c 4 "Reindirizzamento: $wstream_link -> $proto://download.wstream.video/$wstream_req"
		url_in_file=$(curl -s $proto://download.wstream.video/"$wstream_req")

		if [[ "$url_in_file" =~ (Server problem.. please contact our support) ]]
		then
		    _log 3
		    break

		else
		    url_in_file=$(grep "class='buttonDownload" <<< "$url_in_file")
		    url_in_file="${url_in_file#*href=\'}"
		    url_in_file="${url_in_file%%\'*}"
		    url "$url_in_file" && break
		fi
	    done
	fi

	check_wget || {
	    print_c 3 "Superato il limite di banda imposto dal server:"
	    print_c 1 "utilizzo un proxy (per usare più banda, forse, puoi cambiare indirizzo IP riconnettendo il modem/router)"
	    
	    set_temp_proxy
	}
    fi
    end_extension
fi



# function add_wstream_definition {
#     set_line_in_file + "$url_in $1" "$path_tmp"/wstream-definitions
# }

# function del_wstream_definition {
#     set_line_in_file - "$url_in $1" "$path_tmp"/wstream-definitions
# }

# function get_wstream_definition {
#     declare -n ref="$1"

#     if test -f "$path_tmp"/wstream-definitions
#     then
# 	ref=$(grep -P "^$url_in (o|n|l){1}$" "$path_tmp"/wstream-definitions |
# 		     cut -f2 -d' ')
#     fi
# }

# if [[ "$url_in" =~ http[s]*://[w.]*wstream ]] 
# then
#     unset html html2 movie_definition post_data wstream_loops
    
#     html=$(wget -t1 -T$max_waiting                               \
# 		"$url_in"                                        \
# 		--user-agent="$user_agent"                       \
# 		--keep-session-cookies                           \
# 		--save-cookies="$path_tmp/cookies.zdl"           \
# 		-qO- -o /dev/null)

#     # if [ -z "$html" ] && check_cloudflare "$url_in"
#     # then
#     # 	get_by_cloudflare "$url_in" wstream_new_url
#     # 	url "$wstream_new_url" ||
#     # 	    _log 2
#     # fi
    
#     if [[ "$html" =~ (File Not Found|File doesn\'t exits) ]]
#     then
# 	_log 3

#     elif [ -z "$html" ] && check_cloudflare "$url_in"
#     then
# 	_log 32
	
#     elif grep -qP 'class="buttonDownload"' <<< "$html" #[[ "$html" =~ (Video is processing now) ]]
#     then
# 	wstream_new_url=$(grep -P 'class=\"buttonDownload\"' <<< "$html" |
# 			      sed -r 's|.+href=\"([^"]+)\".+|\1|g')
	
# 	html2=$(wget -t1 -T$max_waiting                               \
# 		     "$wstream_new_url"                               \
# 		     --user-agent="$user_agent"                       \
# 		     --load-cookies="$path_tmp/cookies.zdl"           \
# 		     -qO- -o /dev/null)

# 	grep http "$html"
	
#     else
# 	download_video=$(grep -P "download_video.+o" <<< "$html" | head -n1)

# 	if [ -z "$download_video" ]
# 	then
# 	    msg_wstream="File \"Original\" non disponibile: verrà estratto il file di streaming migliore"
# 	    set_link - "$url_in"
# 	    url_in_timer=true
	    
# 	else
# 	    hash_wstream="${download_video%\'*}"
# 	    hash_wstream="${hash_wstream##*\'}"

# 	    id_wstream="${download_video#*\'}"
# 	    id_wstream="${id_wstream%%\'*}"

# 	    mode_stream="o"

# 	    declare -A movie_definition
# 	    movie_definition=(
# 		['o']="Original"
# 		['n']="Normal"
# 		['l']="Low"
# 	    )
	    
# 	    wstream_loops=0
# 	    while ! url "$url_in_file" &&
# 		    [[ ! "$post_data" =~ download_orig ]] &&
# 		    ((wstream_loops < 2))
# 	    do
# 		((wstream_loops++))
# 		print_c 4 "Ricerca file con definizione audio/video originale..."
# 		url_get_data_wstream="https://wstream.video/dl?op=download_orig&id=${id_wstream}&mode=${mode_stream}&hash=${hash_wstream}"
# 		print_c 4 "$url_get_data_wstream"

# 		html2=$(curl -A "$user_agent"            \
# 			     -s                          \
# 			     -e "$url_in"                \
# 			     -b "$path_tmp/cookies.zdl"  \
# 			     "$url_get_data_wstream")

# 		if [[ "$html2" =~ (You can download files up) ]]
# 		then
# 		    break
# 		fi

# 		url_in_file=$(grep 'Direct Download Link' <<< "$html2" |
# 				     head -n1 |
# 				     sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
# 	    done

# 	    if ! url "$url_in_file" &&
# 		    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
# 	    then
# 		url_in_timer=$((${BASH_REMATCH[1]} * 60))
# 		set_link_timer "$url_in" $url_in_timer
# 		_log 33 $url_in_timer

# 		add_wstream_definition $mode_stream

# 	    else
# 		if ! url "$url_in_file"
# 		then
# 		    url_in_file=$(grep 'Direct Download Link' <<< "$html2" |
# 	     				 sed -r 's|.+\"([^"]+)\".+|\1|g')
# 		fi
		
# 		if url "$url_in_file"
# 		then
# 		    print_c 1 "Disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
# 		    set_wstream_definition $mode_stream

# 		else
# 		    print_c 3 "Non è disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
# 		    del_wstream_definition $mode_stream
# 		fi
# 	    fi
# 	fi

# 	if url "$url_in_file"
# 	then
# 	    url_in_file="${url_in_file//https\:/http:}"
# 	    if [ -z "$file_in" ]
# 	    then
# 		file_in="${url_in_file##*\/}"
# 	    fi
	    
# 	else
# 	    if [ -z "$file_in" ]
# 	    then
# 		file_in=$(grep -P "META.+description" <<< "$html")
# 		file_in="${file_in%\"*}"
# 		file_in="${file_in##*\"}"
# 		file_in="${file_in// /_}"
# 	    fi

# 	    if [ ! -f "$path_tmp"/filename_"$file_in".txt ] ||
# 		   [ ! -f "$path_tmp"/url_in_wstreaming.txt ] ||
# 		   ! grep -q "$url_in" "$path_tmp"/url_in_wstreaming.txt
# 	    then
# 		print_c 4 "Ricerca file di streaming con definizione audio/video più alta..."

# 		unpacked=$(unpack "$(grep 'p,a,c,k,e' <<< "$html" |tail -n1)")
# 		url_in_file=$(grep sources <<< "$unpacked" |tail -n1)
# 		url_in_file="${url_in_file#*\"}"
# 		url_in_file="${url_in_file%%\"*}"		
# 	    fi
# 	fi

# 	if [ -n "$file_in" ]
# 	then
# 	    sanitize_file_in
# 	    file_in="${file_in#Watch_video_}"
# 	fi

# 	if [ -z "$url_in_file" ] || [ "$url_in" == "$url_in_file" ]
# 	then
# 	    _log 2

# 	else
# 	    [ -z "$url_in_timer" ] &&
# 		end_extension ||
# 		    unset url_in_timer
# 	fi
#     fi
# fi
