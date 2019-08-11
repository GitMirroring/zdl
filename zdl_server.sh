#!/bin/bash
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

TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=zdl
export TEXTDOMAINDIR
export TEXTDOMAIN

source /usr/bin/gettext.sh

path_usr="/usr/local/share/zdl"
path_webui="$path_usr/webui"

path_tmp=".zdl_tmp"

path_conf="$HOME/.zdl"
file_conf="$path_conf/zdl.conf"
file_desktop="$HOME/.local/share/applications/zdl-web-ui.desktop"

path_server="$HOME"/.zdl/zdl.d
server_data="$path_server/data.json"
server_paths="$path_server/paths.txt"

source $path_usr/config.sh
source $path_usr/libs/core.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/DLstdout_parser.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/ip_changer.sh
source $path_usr/libs/log.sh
source $path_usr/libs/extension_utils.sh

pid_prog=$$
socket_port="$1"
add_server_pid "$socket_port"

echo > "$gui_log"

server_index="$path_server/index-${web_ui}.html"
template_index="$path_webui/index-${web_ui}.html"

json_flag=true
touch "$server_data".$socket_port
touch "$path_server"/playlist

#### HTTP:
declare -i DEBUG=0
declare -i VERBOSE=0
declare -a REQUEST_HEADERS
declare    REQUEST_URI=""
declare -a HTTP_RESPONSE=(
    [200]="OK"
    [400]="Bad Request"
    [403]="Forbidden"
    [404]="Not Found"
    [405]="Method Not Allowed"
    [500]="Internal Server Error"
)
declare DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
    "Date: $DATE"
    "Expires: $DATE"
    "Server: ZigzagDownLoader"
)

##########



function recv {
    ((DEBUG)) &&
	echo "< $@" >>zdl_server.log
}

function send {
    ((DEBUG)) &&
	echo "> $@" >>zdl_server.log

    echo -ne "$*\r\n"
}

function add_response_header {
    RESPONSE_HEADERS+=("$1: $2")
}

function send_response_header {
    local header

    send "HTTP/1.1 $1 ${HTTP_RESPONSE[$1]}"

    for header in "${RESPONSE_HEADERS[@]}"
    do
	send "$header"
    done
    send
}

function send_response {
    local code="$1"
    local file="$2"
    local mime=""
    local transfer_stats=""
    local tmp_stat_file="/tmp/_send_response_$$_"

    if [ -f "$file" ]
    then
	get_mime_server mime "$file"
	add_response_header "Content-Type" "$mime"
	add_response_header "Content-Length" "$(size_file "$file")"
	[ -n "$HTTP_SESSION" ] &&
	    add_response_header "Set-Cookie" "$HTTP_SESSION"

	if [ "$file" == "$path_server"/status.$socket_port ] &&
	       grep RELOAD "$file" &>/dev/null
	then
	    get_status
	fi

	send_response_header "$code"
	cat "$file"
    fi

    #echo
    # if ((${VERBOSE}))
    # then
    # 	## Use dd since it handles null bytes
    # 	dd 2>"${tmp_stat_file}" < "${file}"
    # 	transfer_stats=$(<"${tmp_stat_file}")
    # 	echo -en ">> Transferred: ${file}\n>> $(awk '/copied/{print}' <<< "${transfer_stats}")\n" >&2
    # 	rm "${tmp_stat_file}"

    # else
    # 	## Use dd since it handles null bytes
    # 	dd 2>"${DUMP_DEV}" < "${file}"
    # fi
}

function send_response_ok_exit {
    send_response "200" "$1"
    exit 0
}

function fail_with {
    send_response "$1" <<< "$1 ${HTTP_RESPONSE[$1]}"
    exit 1
}

function get_mime_server {
    declare -n refmime="$1"
    refmime=''

    case "$2" in
        *\.css)
	    refmime="text/css"
	    ;;
	*\.js)
	    refmime="text/javascript"
	    ;;
	*\.json)
	    refmime="application/json"
	    #mime="text/html"
	    ;;
	*)
	    refmime=$(get_mime "${file}")
	    ;;
    esac

    if [ -n "$refmime" ]
    then
	return 0

    else
	return 1
    fi
}

function serve_file {
    local file="$1"

    if [ -f "$file" ]
    then
	if [[ "$http_method" =~ ^(GET|POST)$ ]]
	then
	    send_response_ok_exit "$file"

	else
	    cat "$file"
	    exit
	fi

    else
	return 1
    fi
}

function serve_static_string {
    add_response_header "Content-Type" "text/plain"
    send_response_ok_exit <<< "$1"
}

function on_uri_match {
    local regex="$1"
    shift
    [[ "${REQUEST_URI}" =~ $regex ]] &&
        "$@" "${BASH_REMATCH[@]}"
}


function unconditionally {
    "$@" "$REQUEST_URI"
}

function clean_data {
    echo -e "$1" | tr -d "\r"
}

function get_file_output {
    declare -n result="$1"
    local file="$2"

    if [[ "$file" =~ ^\/tmp\/zdl.d\/ ]] ||
	   [[ "$file" =~ login.*\.html\?cmd ]]
    then
	result="$file"

    else
	if [ "$file" == '/' ] ||
	       [ -z "$file" ] ||
	       [[ "$file" =~ index-.+\.html ]] ||
	       [ "$file" != "${file//'?'}" ]
	then
	    template="$template_index"
	    file="$server_index"

	else
	    file="$path_usr/webui/${file#\/}"
	fi

	if [ -f "$template" ] &&
	       grep '__START_PATH__' "$template" &>/dev/null
	then
	    sed -r "s|__START_PATH__|$PWD|g" "$template" >"$file"
	fi

	result="$file"
    fi
}

function create_json {
    local path
    rm -f "$server_data".$socket_port

    if [ -s "$server_paths" ]
    then
	echo -ne '[' >"$server_data".$socket_port

	rm -f "$server_paths".new
	while read path
	do
	    if [ -d "$path" ]
	    then
		cd "$path"

		if [ -d "$path_tmp" ]
		then
		    if data_stdout &&
			    ! grep -P '\[$' "$server_data".$socket_port &>/dev/null
		    then
			echo -en "," >>"$server_data".$socket_port
		    fi
		fi
		echo "$path" >>"$server_paths".new
	    fi

	done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")

	mv "$server_paths".new "$server_paths"

	sed -r "s|,$|]\n|g" -i "$server_data".$socket_port
	grep -P '^\[$' "$server_data".$socket_port &>/dev/null &&
	    echo '[]' > "$server_data".$socket_port
    fi

    if [ ! -s "$server_data".$socket_port ]
    then
	echo '[]' > "$server_data".$socket_port
    fi
}

function check_xfer_running {
    local path

    while read path
    do
	if [ -s "$path"/"$path_tmp"/xfer-pids ]
	then
	    for pid in $(cut -d' ' -f1 < "$path"/"$path_tmp"/xfer-pids)
	    do
		check_pid "$pid" &&
		    return 0
	    done
	fi

    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")

    return 1
}

function check_downloader_running {
    ## if grep -P "(aria2c|wget|axel|rtmpdump)" /proc/[0-9]*/cmdline &>/dev/null ||
    ##	    check_xfer_running
    if fuser $path_ffmpeg $path_axel $path_aria2 $path_wget $path_rtmpdump -s ||
	    check_xfer_running
    then
	return 0
    else
	return 1
    fi
}

function send_json {
    local counter=0

    [ "$1" == force ] &&
	rm -f "$server_data".$socket_port.diff

    while :
    do
	if check_downloader_running ||
		((counter<3)) ||
		[ -f "$path_server"/clean-complete.$socket_port ]
	then
	    create_json
	    touch "$server_data".$socket_port "$server_data".$socket_port.diff
	    current_timeout=$(date +%s)
	    if ! cmp_file "$server_data".$socket_port "$server_data".$socket_port.diff ||
		    check_port $socket_port ||
		    (( (current_timeout - start_timeout) > 240 ))
	    then
		counter=0
		break
	    fi

	    ((counter<3)) &&
		((counter++))
	fi
	sleep 2
    done
    ##sleep 0.1

    cp "$server_data".$socket_port "$server_data".$socket_port.diff

    rm -rf "$path_server"/clean-complete.$socket_port

    file_output="$server_data".$socket_port

    if [ -z "$http_method" ]
    then
	cat "$server_data".$socket_port
	exit
    fi
    return 0
}

function get_status {
    local path="$1"
    [ -z "$path" ] && path="$PWD"

    if test -d "$path"
    then
	cd "$path"

	if check_instance_prog ||
		check_instance_daemon
	then
	    status="running"
	else
	    status="not-running"
	fi

	echo "$status" > "$path_server"/status.$socket_port
    fi
}

function get_status_run {
    if [ -n "$1" ]
    then
	declare -n ref="$1"

	if check_instance_prog &>/dev/null ||
		check_instance_daemon &>/dev/null
	then
	    ref="running"
	else
	    ref="not-running"
	fi
    fi
}

function get_status_sockets {
    declare -n ref="$1"
    ref='['
    check_socket_ports "$1"
    ref="${ref%,}]"
}

function check_socket_ports {
    [ -n "$1" ] &&
	declare -n ref="$1"

    if [ -s "$path_server"/socket-ports ]
    then
	while read port
	do
	    if check_port $port
	    then
		set_line_in_file - "$port" "$path_server"/socket-ports

	    elif [ -n "$1" ]
	    then
		ref+="\"$port\","
	    fi

	done < "$path_server"/socket-ports
    fi
}

function get_status_conf {
    local key_json
    declare -n ref="$1"

    ref='{'
    for key in ${key_conf[@]}
    do
	if [ "$key" == downloader ]
	then
	    key_json="conf_downloader"

	else
	    key_json="$key"
	fi

	ref+="\"$key_json\":\"$(get_item_conf $key)\","
    done
    ref="${ref%,}}"
}

function create_status_json {
    local reconn max_dl downloader

    [ -n "$1" ] &&
	declare -n ref_string_output="$1" ||
	    ref_string_output=string_output

    ref_string_output="{"

    ## current path
    ref_string_output+="\"path\":\"$PWD\","

    ## active paths
    local paths
    get_paths_json paths
    ref_string_output+="\"paths\":$paths,"

    ## run status
    get_status_run status
    ref_string_output+="\"status\":\"$status\","

    ## downloader
    if [ ! -f "$path_tmp/downloader" ]
    then
	mkdir -p "$path_tmp"
	get_item_conf 'downloader' >"$path_tmp/downloader"
    fi
    #read downloader < "$path_tmp/downloader"
    downloader=$(< "$path_tmp/downloader")
    ref_string_output+="\"downloader\":\"$downloader\","

    ## max downloads
    if [ ! -f "$path_tmp/max-dl" ]
    then
	mkdir -p "$path_tmp"
	get_item_conf 'max_dl' >"$path_tmp/max-dl"
    fi
    #read max_dl < "$path_tmp/max-dl"
    max_dl=$(< "$path_tmp/max-dl")
    ref_string_output+="\"maxDownloads\":\"$max_dl\","

    ## reconnect
    [ -f "$path_tmp"/reconnect ] && reconn=enabled || reconn=disabled
    ref_string_output+="\"reconnect\":\"$reconn\","

    ## run sockets
    get_status_sockets status
    ref_string_output+="\"sockets\":$status,"

    ## livestream saved
    local paths
    get_livestream_json status
    ref_string_output+="\"livestream\":$status,"

    ## conf
    get_status_conf status
    ref_string_output+="\"conf\":$status"

    ref_string_output+="}"
}

function get_livestream_json {
    declare -n ref="$1"
    local path
    declare -a line
    ref='['

    while read path
    do
	if [ -s "$path"/"$path_tmp"/livestream_time.txt ]
	then
	    while read -a line
	    do
		test -n "${line[0]}" &&
		    ref+="{\"path\":\"$path\",\"link\":\"${line[0]}\",\"start\":\"${line[1]}\",\"duration\":\"${line[2]}\"},"
	    done < "$path"/"$path_tmp"/livestream_time.txt
	fi

    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")
    ref="${ref%\,}]"
}

function send_ip {
    file_output="$path_server"/myip.$socket_port
    get_ip real_ip proxy_ip

    echo -e "Indirizzo IP attuale:\n$real_ip" > "$file_output"

    if [ -n "$proxy_ip" ]
    then
	echo -e "\n\nIndirizzo IP con proxy:\n$proxy_ip" >> "$file_output"
    fi
}

function create_http_session {
    printf "_ZigzagDownLoader=%s" $(create_hash "${*}$(date +%s)") #$((60*60*24))
}

function search_xdcc {
    file_output="$path_server"/xdcc-search.$socket_port
    url="http://www.xdcc.eu/search.php?searchkey=$1"
    response=""

    local server channel bot slot gets name length

    html=$(curl -s $url |
               sed -r 's|<tr>|\n|g' |
               grep data-c)

    while read row
    do
	unset server channel bot slot gets name length
	server="${row##*data-s=\"}"
	server="${server%%\"*}"

	channel="${row##*data-c=\"\#}"
	channel="${channel%%\"*}"

	bot="${row##*data-p=\"}"
	bot="${bot%%\"*}"
	slot="${bot##*send }"
	bot="${bot%% xdcc*}"

	row="${row##*delete.png}"

	row="${row#*</td><td>}"
	row="${row#*</td><td>}"
	row="${row#*</td><td>}"
	gets="${row%%</td><td>*}"
	row="${row#*</td><td>}"
	length="${row%%</td><td>*}"

	row="${row#*</td><td>}"
	row="${row%*</td>*}"
	name=$(sed -r 's|<[^>]*span[^>]*>||g' <<< "$row")

	if [ -n "$server" ] && [ -n "$channel" ] && [ -n "$bot" ] && [ -n "$slot" ] && [ -n "$gets" ] && [ -n "$length" ] && [ -n "$name" ]
	then
            response+="{\"server\":\"${server}\",\"channel\":\"${channel}\",\"bot\":\"${bot}\",\"slot\":\"${slot}\",\"gets\":\"${gets}\",\"length\":\"${length}\",\"name\":\"${name}\"},"
	fi

    done <<< "$html"

    if [ -n "$response" ];
    then
        response="[${response%,}]"
        echo -n "$response" > "$file_output"
    else
        echo -n "failure" > "$file_output"
    fi
}

function clean_playlist {
    local line playlist="[" \
	  server_playlist
    read server_playlist < "$path_server"/playlist

    while read line
    do
    	if [ -f "$line" ]
    	then
    	    playlist+="\"$line\","
    	fi
    done < <(node -e "${server_playlist}.forEach(function(f){console.log(f)})")

    playlist="${playlist%,}]"

    echo -e "$playlist" > "$path_server"/playlist
}

function check_playlist {
    local list="$1"

    if [ -n "$list" ] && [ "$list" != "[]" ]
    then
	list=$(echo "${list}" | sed 's/\("\),\+\([^"]\)/\1\2/g' | sed 's/\([^"]\),\+/\1/g')

	if [[ ! "$list" =~ ^\[\".*\"\]$ ]] ||
	       [[ "$list" =~ [A-Za-z0-9](,|\"\") ]] ||
	       [[ "$list" =~ ,[\/A-Za-z0-9] ]]
	then
	    return 1
	fi
    fi
    return 0
}

function get_paths_json {
    declare -n ref=$1
    local path pid
    local old_path="$PWD"
    ref='['

    while read path
    do
	cd "$path"
	if check_instance_prog || check_instance_daemon
	then
	    ref+="\"$path\","
	fi

    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")

    cd "$old_path"
    ref="${ref%\,}]"
}

function stop_console_webui {
    local flag_file="$1"
    while read path
    do
	rm -f "$path"/"$flag_file"
    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")
}

function run_cmd {
    local line=( "$@" )
    local file link pid path
    unset file_output

    case "${line[0]}" in
	login)
	    file_output="$path_server"/msg-login.$socket_port
	    data=$(clean_data "${line[1]}${line[2]}")

	    if [ -s "$file_socket_account" ]
	    then
		if grep -P "^$(create_hash "$data")$" "$file_socket_account" &>/dev/null
		then
		    HTTP_SESSION=$(create_http_session "$data")

		    ## add_response_header "Set-Cookie" "$HTTP_SESSION"
		    echo "$HTTP_SESSION" >> "$path_server"/http-sessions

		    get_file_output file_output 'index-1.html'
		else
		    echo -e "<html>\n<head><meta http-equiv=\"refresh\" content=\"0; url=login.html?op=retry\" /></head><body></body></html>" > "$file_output"
		fi

	    else
		echo -e "Non hai ancora creato un account per il socket.
Apri un terminale e digita:
zdl --configure

Seleziona l'opzione 2: Crea un account per i socket di ZDL." > "$file_output"
	    fi
	    ;;

	check-account)
            file_output="$path_server"/msg-account.$socket_port
	    if [ -s "$file_socket_account" ]
	    then
		echo "exists" > "$file_output"

	    else
		echo -e "Non esiste ancora un account per l'uso dei socket:
per configurare un account, usa il comando 'zdl --configure'" > "$file_output"
	    fi
	    ;;

	create-account)
            create_socket_account $(clean_data "${line[1]}") $(clean_data "${line[2]}")
	    ;;

	reset-account)
	    rm -f "$file_socket_account"
	    ;;

	init-client)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client "${line[1]}" $socket_port
	    ;;

	reset-requests)
	    sleep 3

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client "${line[1]}" $socket_port
	    ;;

    	get-data)
	    send_json ${line[1]} || {
		return
	    }
	    ;;

	get-console)
	    test -d "${line[1]}" && cd "${line[1]}"
	    file_output="$path_tmp"/console_stdout.$socket_port
	    local loop_console="${line[2]}"

	    [ "$loop_console" == true ] ||
		stop_console_webui "$file_output".diff

	    touch "$file_output".diff

	    local diff_out
	    while [ -f "$file_output".diff ]
	    do
		cp "$gui_log" "$file_output"
		diff_out=$(comm --nocheck-order -23 "$file_output" "$file_output".diff)

		if [ -n "$diff_out" ]
		then
		    echo "$diff_out" >"$file_output"
		    echo "$diff_out" >>"$file_output".diff
		    break
		fi
		sleep 2
	    done
	    [ -f "$file_output".diff ] || echo >"$file_output"
	    ;;

	stop-console)
	    file_output="$path_tmp"/console_stdout.$socket_port
	    stop_console_webui "$file_output".diff
	    echo >"$file_output"
	    ;;

	get-livestream-opts)
	    file_output="$path_server"/livestream-opts.json
	    local live_chan_json='['
	    for ((i=0; i<${#live_streaming_url[@]}; i++))
	    do
		live_chan_json+="{\"chan\":\"${live_streaming_chan[i]}\",\"url\":\"${live_streaming_url[i]}\"},"
	    done
	    live_chan_json="${live_chan_json%,}]"
	    echo "$live_chan_json" >"$file_output"
	    ;;

	set-livestream)
	    file_output="$path_server"/livestream
	    test -d "${line[1]}" && cd "${line[1]}"

	    if url "${line[2]}" &&
		    [ -n "${line[3]}" ] &&
		    [ -n "${line[4]}" ]
	    then
		local live_link
		tag_link "${line[2]}" live_link
		set_link + "$live_link"
		set_livestream_time "$live_link" "${line[3]}" "${line[4]}"
		run_livestream_timer "$live_link" "${line[3]}" &&
		    echo "true" >"$file_output" ||
			echo "false" >"$file_output"
	    else
		echo "false" >"$file_output"
	    fi
	    ;;

	get-playlist)
	    file_output="$path_server"/playlist
	    clean_playlist
            list=$(< "$file_output")

            if check_playlist "$list"
            then
		touch "$file_output"

            else
		echo > "$file_output"
		file_output=playlist-error
		echo -e "Errore durante l'analisi del json della playlist" > "$file_output"
            fi
	    ;;

	add-playlist)
            file_output="$path_server"/playlist
	    clean_playlist

            if [ -f "${line[1]}" ] &&
		   [[ "$(file -b --mime-type "${line[1]}")" =~ (video|audio) ]]
            then
		list=$(< "$file_output")

		if check_playlist "$list"
    		then
                    if [ -z "$list" ] || [ "$list" == "[]" ]
                    then
			list="[\"${line[1]}\"]"

		    else
			list="${list//]/,\"${line[1]}\"]}"
		    fi
		    echo -e "$list" > "$file_output"

		else
    		    echo > "$file_output"
    		    file_output=playlist-error
    		    echo -e "Errore durante l'analisi del json della playlist" > "$file_output"
		fi
	    else
		file_output=playlist-error
		echo -e "Non è un file audio/video" > "$file_output"
	    fi
	    ;;

	del-playlist)
	    file_output="$path_server"/playlist
	    touch "$file_output"
	    list=$(< "$file_output")

	    if check_playlist "$list"
    	    then
    		list="${list//\"${line[1]}\"/}"
    		list="${list//,/}"
    		list="${list//\"\"/\",\"}"
    		echo -e "$list" > "$file_output"

    	    else
    		echo > "$file_output"
    		file_output=playlist-error
    		echo -e "Errore durante l'analisi del json della playlist" > "$file_output"
    	    fi
	    ;;

	play-playlist)
	    get_conf
	    file_output="$path_server"/playlist-file.$socket_port
	    local term

	    #local item
	    declare -a list
	    while read item
	    do
		[ -f "$item" ] &&
		    list+=( "$item" )
	    done < <(sed -r 's|€€€|\n|g' <<< "${line[1]}")

	    #unset item
	    declare -a opts=()
	    local id=0

	    if [ -z "$player" ]
	    then
	    	echo -e "Non è stato configurato alcun player per audio/video" > "$file_output"

	    else
		local player_filename="${player##*/}"

		if [[ "$player_filename" =~ ^(vlc|cvlc|mpv|mplayer|mplayer2)$ ]]
		then
		    local playlist="#EXTM3U"
		    local title

		    for item in "${list[@]}"
		    do
			if [[ -e "$item" ]]
			then
			    id=$[id + 1]
			    title="${item##*/}"
			    title="${title%.*}"
			    playlist+="\n#EXTINF:$id,${title//,}\n$item"
			fi
		    done

		    if (( id > 0 ))
		    then
			echo -e "$playlist" > "$path_tmp/playlist.m3u"

			if [[ "$player_filename" =~ ^[c]*vlc ]]
			then
			    opts=(
				--global-key-play-pause
				Space
				--global-key-next
				Enter
			    )
			fi

			if [[ "$player_filename" =~ ^mpv ]]
			then
			    opts=(
				--geometry=800x50
				--profile=pseudo-gui
				--script-opts="osc-visibility=always,osc-vidscale=no,osc-boxalpha=0"
				--playlist
			    )
			fi

			if [[ "$player_filename" =~ ^mplayer ]]
			then
			    opts=(
				-playlist
			    )
			fi

			if [[ ! "$player_filename" =~ ^(vlc|smplayer|mpv)$ ]]
			then
			    term="xterm -e"
			fi

			if [ -n "${opts[*]}" ]
			then
			    $term $player "${opts[@]}" "$path_tmp/playlist.m3u"
			else
			    $term $player "$path_tmp/playlist.m3u"
			fi
			echo -e "$id" > "$file_output"

		    else
			echo -e "Nessun file audio trovato" > "$file_output"
		    fi

		elif [ -n "$player" ] &&
			 [[ "$player" =~ ^([^\ ]+) ]]
		then
		    if ! command -v "${BASH_REMATCH[1]}" &>/dev/null
		    then
			echo -e "Player non trovato" > "$file_output"

		    else
			items=()
			for item in "${list[@]}"
			do
			    if [[ -f "$item" ]]
			    then
				items+=("$item")
				id=$[id + 1]
			    fi
			done

			if [[ "$player" =~ xterm ]]
			then
			    $player "${items[@]}"
			else
			    xterm -e $player "${items[@]}"
			fi

			items=()
			echo -e "$id" > "$file_output"
		    fi
		fi
	    fi
	    ;;

	play-media)
	    get_conf
	    file_output="$path_server"/msg-file.$socket_port
	    local term

	    if [ -f "${line[1]}" ]
	    then
		if [ -z "$player" ]
		then
		    echo -e "Non è stato configurato alcun player per audio/video" > "$file_output"

		elif [[ ! "$(file -b --mime-type "${line[1]}")" =~ (audio|video) ]]
		then
		    echo -e "Non è un file audio/video" > "$file_output"

		else
		    local player_filename="${player##*/}"
		    declare -a opts=()

		    if [[ ! "$player_filename" =~ ^(vlc|smplayer|mpv|dragon|cvlc)$ ]] ||
			   ( [[ "$player_filename" =~ ^(cvlc)$ ]] &&
				 [[ "$(file -b --mime-type "${line[1]}")" =~ (audio) ]] )
		    then
			term="xterm -e"
		    fi

		    case "$player_filename" in
			mpv)
			    opts+=(
				--profile=pseudo-gui
			    )

			    [[ "$(file -b --mime-type "${line[1]}")" =~ (audio) ]] &&
				opts+=(
				    --geometry=800x50
				    --profile=pseudo-gui
				    --script-opts="osc-visibility=always,osc-vidscale=no,osc-boxalpha=0"
				)
			    ;;
			mplayer)
			    [[ ! "$(file -b --mime-type "${line[1]}")" =~ (audio) ]] &&
				term="${term//-e/-iconic -e}"
			    ;;
		    esac

		    if command -v $player &>/dev/null
		    then
			if [ -n "${opts[*]}" ]
			then
			    $term $player "${opts[@]}" "${line[1]}"
			else
			    $term $player "${line[1]}"
			fi
		     	echo -e "running" > "$file_output"

		     else
		     	echo -e "Player non trovato" > "$file_output"
		    fi
		fi
	    else
		echo -e "File non trovato" > "$file_output"
	    fi
	    ;;

	extract-audio)
	    file_output="$path_server"/audio-file.$socket_port
	    video=${line[1]}
	    format=${line[2]}
	    if command -v ffmpeg &>/dev/null
	    then
		if [ -f "$video" ]
		then
		    audio="${video%.*}.$format"
		    nohup ffmpeg -i $video -vn -acodec $format $audio &>/dev/null
		    echo -e "success" > "$file_output"
		else
		    echo -e "Video da cui estrarre l'audio non trovato" > "$file_output"
		fi
	    else
		echo -e "ffmpeg non trovato" > "$file_output"
	    fi
	    ;;

	get-status)
	    ## status.json
	    file_output="$path_server"/status.$socket_port.json

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ "${line[2]}" == 'loop' ]
	    then
		if [ -s "$path_server"/pid_loop_status.$socket_port ]
		then
		    local pid_loop_status
		    read pid_loop_status < "$path_server"/pid_loop_status.$socket_port
		    kill -9 $pid_loop_status 2>/dev/null
		fi

		echo "$PWD" > "$path_server"/path.$socket_port

		unset line[2]
		while ! check_port $socket_port
		do
		    if [ -s "$path_server"/path.$socket_port ]
		    then
			local path_socket
			read path_socket < "$path_server"/path.$socket_port
			cd "$path_socket"
		    fi

		    create_status_json string_output
		    current_timeout=$(date +%s)

		    [ -s "$file_output" ] &&
			read file_output_val < "$file_output"

		    if [ ! -s "$file_output" ] ||
			   [ "$string_output" != "$file_output_val" ] ||
			   (( (current_timeout - start_timeout) > 240 ))
		    then
			init_client "$PWD" "$socket_port"
			start_timeout=$(date +%s)
		    fi
		    sleep 2
		done &>/dev/null &
		pid_loop_status=$!
		echo "$pid_loop_status" > "$path_server"/pid_loop_status.$socket_port

	    else
		lock_fifo status.$socket_port path
		if test -d "$path"
		then
		    echo "$path" > "$path_server"/path.$socket_port
		    cd "$path"
		fi
	    fi

	    create_status_json string_output
	    echo -n "$string_output" >$file_output
	    ;;

	reconnect)
	    if test -d "${line[1]}"
	    then
		cd "${line[1]}"
	    fi

	    if test "${line[2]}" == 'true'
	    then
		if [ -n "$reconnecter" ]
		then
		    touch "$path_tmp"/reconnect

		else
		    rm -f "$path_tmp"/reconnect
		    file_output="$path_server"/reconn.$socket_port
		    echo "Non hai ancora configurato ZDL per la riconnessione automatica" > "$file_output"
		fi

	    elif test "${line[2]}" == 'false'
	    then
		rm -f "$path_tmp"/reconnect

	    elif test -z "${line[2]}"
	    then
		if [ -n "$reconnecter" ]
		then
		    $reconnecter &>/dev/null
		    send_ip

		else
		    rm -f "$path_tmp"/reconnect
		    file_output="$path_server"/reconn.$socket_port
		    echo "Non hai ancora configurato ZDL per la riconnessione automatica" > "$file_output"
		fi
	    fi
	    ;;

	get-ip)
	    send_ip
	    ;;

	get-free-space)
	    file_output="$path_server"/free-space.$socket_port

	    if test -d "${line[1]}"
	    then
		cd "${line[1]}"
	    fi

	    df -h . |
		awk '{if(match($4, /^[0-9]+/)) print $4}' > "$file_output"
	    ;;

	add-xdcc)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"

		declare -A irc
		case $i in
		    2)
			irc[host]="${link#'irc://'}"
			irc[host]="${irc[host]%%'/'*}"
			err_msg="\nIRC host: ${link}"
			;;

		    3)
			irc[chan]="${link##'#'}"
			err_msg+="\nIRC channel: ${link}"
			;;

		    4)
			irc[msg]="${link#'/msg'}"
			irc[msg]="${irc[msg]#'/ctcp'}"
			irc[msg]="${irc[msg]## }"
			err_msg+="\nIRC msg: ${link}"
			;;
		esac
	    done

	    link="irc://${irc[host]}/${irc[chan]}/msg ${irc[msg]}"

	    if set_link + "$link"
	    then
		date >> links.txt
		echo "$link" >> links.txt
		echo "" >> links.txt

	    else
	    	file_output="$path_server"/msg-file.$socket_port
	    	echo -e "$err_msg" > "$file_output"
	    fi
	    ;;

	search-xdcc)
	    local searchkey="${line[*]//search\-xdcc}"
	    searchkey="${searchkey# }"
	    searchkey="${searchkey//\ /+}"

	    search_xdcc "$searchkey"
    	    ;;

	add-link)
	    ## PATH -> LINK
	    unset list_err

	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		## link
		link=$(urldecode "${line[i]}")

		if url "$link" &&
			! check_instance_prog &&
			! check_instance_daemon
		then
		    mkdir -p "$path_tmp" &>/dev/null
		    date +%s >"$path_tmp"/.date_daemon
		    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &

		    while ! check_instance_daemon
		    do
			sleep 0.1
		    done
		fi

		if set_link + "$link"
		then
    		    date >> links.txt
		    echo "$link" >> links.txt
		    echo "" >> links.txt

		else
		    list_err+="\n$link"
		fi

	    done &>/dev/null

	    if [ -n "$list_err" ]
	    then
	    	file_output="$path_server"/msg-file.$socket_port
	    	echo -e "$list_err" > "$file_output"

	    else
		init_client
	    fi
	    ;;

	del-link)
	    ## PATH -> LINK ~ PID
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"

		if url "$link"
		then
		    set_link - "$link"
		    remove_livestream_link_start "$link"
		    remove_livestream_link_time "$link"
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "$link" ]
			then
			    kill -9 "${pid_out[j]}" &>/dev/null

			    rm -f "${file_out[j]}"         \
			       "${file_out[j]}".st         \
			       "${file_out[j]}".aria2      \
			       "${file_out[j]}".zdl        \
			       "$path_tmp"/"${file_out[j]}_stdout".*  \
			       "$path_tmp"/"${file_out[j]}.MEGAenc_stdout".*
			fi
		    done
		fi
	    done
	    ## force get-data: send_json
	    rm -f "$server_data".$socket_port.diff
	    init_client
	    ;;

	stop-link)
	    ## PATH -> LINK ~ PID
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"

		if url "$link"
		then
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "$link" ]
			then
			    kill -9 "${pid_out[j]}" &>/dev/null
			fi
		    done
		fi
	    done
	    ;;

	play-link)
	    file_output="$path_server"/msg-file.$socket_port

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -z "$player" ] #&>/dev/null
	    then
		echo -e "Non è stato configurato alcun player per audio/video" > "$file_output"

	    elif [[ ! "$(file -b --mime-type "${line[2]}")" =~ (audio|video) ]]
	    then
		echo -e "Non è un file audio/video" > "$file_output"

	    else
		nohup $player "${line[2]}" &>/dev/null &
		echo -e "running" > "$file_output"
	    fi
	    ;;

	get-file)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    file_output="$path_server"/file-text.$socket_port
	    sed -r 's|$|<br>|g' "${line[2]}" > "$file_output"
	    ;;

	del-file)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if test -s "${line[2]}" &&
		    ( [ "${line[2]}" == "links.txt" ] || [ "${line[2]}" == "zdl_log.txt" ] )
	    then
		rm -f "${line[2]}"
	    fi
	    ;;

	get-links)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -f "$path_tmp/links_loop.txt" ]
	    then
		file_output="$path_tmp/links_loop.txt"

	    else
		echo > "$path_server/empty"
		file_output="$path_server/empty"
	    fi
	    ;;

	set-links)
	    ## path:
	    unset list_err

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    ## links:
	    if [ -n "${line[2]}" ]
	    then
		date >> links.txt
		urldecode "${line[2]}" >> links.txt
		echo "" >> links.txt
	    fi

	    echo -n > "$path_tmp"/links_loop.txt
	    while read link
	    do
		url "$link" &&
		    set_link + "$link" ||
			list_err+="\n$link"

	    done <<< "$(urldecode "${line[2]}")"

	    [ ! -s "$path_tmp"/links_loop.txt ] && rm -f "$path_tmp"/links_loop.txt*

	    if [ -n "$list_err" ]
	    then
	    	file_output="$path_server"/msg-file.$socket_port
	    	echo -e "$list_err" > "$file_output"
	    fi
	    ;;

	get-downloader)
	    ## [1]=PATH
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if test -f "$path_tmp/downloader"
	    then
		if [ "${line[2]}" != 'force' ]
		then
		    lock_fifo downloader path
		    [ -d "$path" ] &&
			cd "$path"

		else
		    unset line[2]
		fi

	    else
		mkdir -p "$path_tmp"
		get_item_conf 'downloader' >"$path_tmp/downloader"
	    fi

	    file_output="$path_tmp/downloader"
	    ;;

	set-downloader)
	    ## [1]=PATH; [2]=DOWNLOADER
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    echo "${line[2]}" >"$path_tmp/downloader"
	    #unlock_fifo downloader "$PWD" &
	    #unlock_fifo status.$socket_port &
	    init_client
	    ;;

	get-max-downloads)
	    ## [1]=PATH;
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if test -f "$path_tmp/max-dl"
	    then
		if [ "${line[2]}" != 'force' ]
		then
		    lock_fifo max-downloads path
		    [ -d "$path" ] &&
			cd "$path"

		else
		    unset line[2]
		fi
	    else
		mkdir -p "$path_tmp"
		get_item_conf 'max_dl' >"$path_tmp/max-dl"
	    fi

	    file_output="$path_tmp/max-dl"
	    ;;

	set-max-downloads)
	    ## [1]=PATH, [2]=NUMBER:(0->...)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -z "${line[2]}" ] || [[ "${line[2]}" =~ ^[0-9]+$ ]]
	    then
		echo "${line[2]}" >"$path_tmp/max-dl"
		#unlock_fifo max-downloads "$PWD" &
		#unlock_fifo status.$socket_port &
		init_client
	    fi
	    ;;

	get-status-run)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    get_status_run status ${line[2]}

	    echo "$status" > "$path_server"/status.$socket_port
	    file_output="$path_server"/status.$socket_port
	    ;;

	check-dir)
	    file_output="$path_server"/check-dir.$socket_port
	    if test -d "${line[1]}"
	    then
		echo true > "$file_output"

	    else
		echo > "$file_output"
	    fi
	    ;;

	get-desktop-path)
	    if test -s "$file_desktop"
	    then
		eval exec_line=( $(grep Exec "$file_desktop") )

		for path in "${exec_line[@]}"
		do
		    if test -d "$path"
		    then
			file_output="$path_server"/get-desktop-path.$socket_port
			echo "$path" > "$file_output"
			break
		    fi
		done
	    fi
	    ;;

	set-desktop-path)
	    if test -d "${line[1]}" &&
		    test -s "$file_desktop"
	    then
		sed -r "s|^Exec=.+$|Exec=zdl --web-ui \"${line[1]}\"|g" -i "$file_desktop"
	    fi
	    ;;

	browse-fs)
	    file_output="$path_server"/browsing.$socket_port
	    type="${line[2]}"

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    while read file
	    do
		real_path=$(realpath "$file")

		if [ -d "$real_path" ]
		then
		    string_output+="[$file];"

		elif [ "$type" == torrent ] &&
			 [[ "$(file -b --mime-type "$real_path")" =~ bittorrent ]]
		then
		    string_output+="$file;"

		elif [ "$type" == media ] &&
			 [[ "$(file -b --mime-type "$real_path")" =~ (audio|video) ]]
		then
		    string_output+="$file;"

		elif [ "$type" == executable ] &&
			 [ -x "$real_path" ]
		then
		    string_output+="$file;"
		fi

	    done < <(ls -1 --group-directories-first)

	    echo "$string_output" > "$file_output"
	    ;;

	browse-dirs)
	    file_output="$path_server"/browsing.$socket_port

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    string_output="<a href=\"javascript:browseDir({path:'$PWD/..',idSel:'${line[2]}',idBrowser:'${line[3]}',callback:'${line[4]}'});\"><img src=\"images/folder-blue.png\"> ..</a><br>"
	    while read dir
	    do
		real_dir=$(realpath "$dir")
		string_output+="<a href=\"javascript:browseDir({path:'${real_dir}',idSel:'${line[2]}',idBrowser:'${line[3]}',callback:'${line[4]}'});\"><img src=\"images/folder-blue.png\"> $dir</a><br>"
	    done < <(ls -d1 */)

	    echo "$string_output" > "$file_output"
	    ;;

	browse)
	    file_output="$path_server"/browsing.$socket_port
	    path="${line[1]}"
	    id="${line[2]}"
	    type="${line[3]}"
	    key="${line[4]}"

	    test -d "$path" &&
		cd "$path"

	    JS="browseFile({id:'$id',path:'$PWD/..',type:'$type',key:'$key'});"
	    string_output="<a href=\"javascript:${JS}\"><img src=\"images/folder-blue.png\"> ../</a><br>"

	    while read file
	    do
		real_path=$(realpath "$file")

		if [ -d "$real_path" ]
		then
		    img="images/folder-blue.png"
		    JS="browseFile({id:'$id',path:'$real_path',type:'$type',key:'$key'});"
		    string_output+="<a href=\"javascript:${JS}\"><img src=\"images/folder-blue.png\"> $file</a><br>"

		elif [ "$type" == torrent ] &&
			 [[ "$(file -b --mime-type "$real_path")" =~ ^application\/(octet-stream|x-bittorrent)$ ]]
		then
		    img='images/application-x-bittorrent.png'

		    JS="if (confirm('Vuoi usare il file $file ?')) singlePath(ZDL.path).addLink('$id','$real_path');"
		    string_output+="<a href=\"javascript:${JS}\"><img src=\"$img\"> $file</a><br>"

		elif [ "$type" == media ] &&
			 [[ "$(file -b --mime-type "$real_path")" =~ (audio|video) ]]
		then
		    img="images/${BASH_REMATCH[1]}"-x-generic.png

		    JS="addPlaylist('$path/$file');"
		    string_output+="<a href=\"javascript:${JS}\"><img src=\"$img\"> $file</a><br>"

		elif [ "$type" == executable ] &&
			 [ -x "$real_path" ]
		then
		    img='images/application-x-desktop.png'
		    JS="if (confirm('Vuoi usare il file $file ?')) setConf({key:'$key'},'$real_path');"
		    string_output+="<a href=\"javascript:${JS}\"><img src=\"$img\"> $file</a><br>"
		fi

	    done < <(ls -1 --group-directories-first)

	    echo "$string_output" > "$file_output"
	    ;;

	clean-complete)
	    while read path
	    do
		test -d "$path" &&
		    cd "$path"

		no_complete=true
		data_stdout
		unset no_complete

	    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client

	    while read port
	    do
		touch "$path_server"/clean-complete.$port
	    done < "$path_server"/socket-ports
	    ;;

	run-server)
	    if [[ "${line[1]}" =~ ^[0-9]+$ ]] &&
		   check_port "${line[1]}"
	    then
		run_zdl_server "${line[1]}" &>/dev/null

	    else
		echo "already-in-use" >"$path_server"/run-server.$socket_port
		file_output="$path_server"/run-server.$socket_port
	    fi
	    ;;

	get-sockets)
	    file_output="$path_server"/get-sockets.$socket_port
	    get_status_sockets sockets
	    echo "$sockets" > "$file_output"
	    ;;

	run-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"

			if ! check_instance_prog &>/dev/null &&
				! check_instance_daemon &>/dev/null
			then
			    set_line_in_file + "$(realpath "$PWD")" "$server_paths"
			    mkdir -p "$path_tmp"
			    date +%s >"$path_tmp"/.date_daemon
			    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &
			fi
		    }
	    done
	    ;;

	quit-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"

			if [ -s "$path_tmp/.pid.zdl" ]
			then
			    read pid < "$path_tmp/.pid.zdl"

			    check_pid $pid &&
				kill -9 $pid &>/dev/null

			    rm -f "$path_tmp"/.date_daemon
			    unset pid
			fi
		    }
	    done &>/dev/null
	    ;;

	kill-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"

			if [ -s "$path_tmp/.pid.zdl" ]
			then
			    read pid < "$path_tmp/.pid.zdl"

			    check_pid $pid &&
				kill -9 $pid &>/dev/null
			    kill_downloads

			    rm -f "$path_tmp"/.date_daemon
			    unset pid
			fi
		    }
	    done

	    init_client
	    ;;

	kill-server)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		kill_server "${line[i]}"
	    done
	    ;;

	kill-all)
	    ## tutte le istanze di ZDL (in tutti i path) e i downloader
	    while read path
	    do
		test -d "$path" &&
		    cd "$path"

	    	kill_downloads
		[ -s "$path_tmp"/.pid.zdl ] &&
		    read instance_pid < "$path_tmp"/.pid.zdl
		[ -n "$instance_pid" ] &&
		    {
			kill -9 "$instance_pid" &>/dev/null
			rm -f "$path_tmp"/.date_daemon
			unset instance_pid
		    }
	    done < <(awk '!($0 in a){a[$0]; print}' "$server_paths")

	    init_client
	    ;;

    get-language)
        file_output="$path_server"/language.i18n
        local lang=$(get_item_conf 'language')
        echo "$lang" > "$file_output"
        ;;

	get-conf)
	    get_conf
	    file_output="$path_server"/conf.$socket_port.json

	    if [ "${line[1]}" != 'force' ]
	    then
		lock_fifo conf

	    else
		unset line[1]
	    fi

	    string_output='{'

	    for item in ${key_conf[@]}
	    do
		string_output+="\"$item\":\"$(get_item_conf "$item")\","
	    done
	    string_output="${string_output%,}}"

	    echo -n "$string_output" > "$file_output"
	    ;;

	set-conf)
	    set_item_conf "${line[1]}" "${line[2]}"
	    init_client
	    ;;
    esac

    if [ -z "$http_method" ]
    then
	test -f "$file_output" &&
	    cat "$file_output" ||
		send
	exit

    elif [ -z "$file_output" ]
    then
	echo > "$path_server/empty"
	file_output="$path_server/empty"
    fi
}

function run_data {
    local data=( ${1//'&'/ } )
    local name value last
    local line_cmd=()

    for ((i=0; i<${#data[*]}; i++))
    do
	## name=$(urldecode "${data[i]%'='*}")
	value="$(urldecode "${data[i]#*'='}")"
	line_cmd+=( "$value" )
    done

    [ -n "${line_cmd[*]}" ] && run_cmd "${line_cmd[@]}"
}


function send_login {
    if [[ ! "$file_output" =~ login.html ]]
    then
	file_output="$path_usr/webui"/login.html

	[ -z "$GET_DATA" ] && add_response_header "Location" "login.html" &&
            add_response_header "Set-Cookie" "_zdlstartuplanguage="$(get_item_conf 'language')

	send_response 302 "$file_output"

	exit 0
    fi
}


function check_session_cookie {
    if [[ "$1" =~ .*(_ZigzagDownLoader=[a-z0-9]{128}).* ]]
    then
	grep "${BASH_REMATCH[1]}" "$path_server"/http-sessions &>/dev/null && return 0
    fi
    return 1
}


function http_server {
    local cookie

    case $http_method in
	GET)
            if [[ "${line[*]}" =~ 'Cookie' ]]
	    then
		cookie="$(clean_data "${line[*]}")"
		check_session_cookie "$cookie" && logged_on=true

	    elif [[ "$(clean_data "${line[*]}")" =~ 'Accept-Language' ]]
	    then
		user_accept_language=true

	    elif [[ "$(clean_data "${line[*]}")" =~ 'Connection' ]]
	    then
		connection_test=true

	    elif [[ "$(clean_data "${line[*]}")" =~ 'Firefox/'([1-5]{1}[0-9]{1}|60|61|62|ESR) ]]
	    then
		user_agent=firefox-old
	    fi

	    if [ -n "$connection_test" ] &&
		   [ -n "$user_accept_language" ]
	    then
		if [ "$user_agent" != firefox-old ]
		then
		    read new_line
		    cookie="$(clean_data "$new_line")"
		    check_session_cookie "$cookie" && logged_on=true
		fi

		if [ -z "$logged_on" ] &&
		       [[ ! "$file_output" =~ \.(css|js|gif|jpg|jpeg|ico|png|$socket_port)$ ]] &&
		       [[ ! "$file_output" =~ login.*\.html\? ]]
		then
		    send_login
		fi

		if [ -n "$GET_DATA" ]
		then
		    run_data "$GET_DATA"
		fi

		if [ -f "$file_output" ]
		then
		    [[ "$file_output" =~ "$server_data" ]] &&
			create_json

		    serve_file "$file_output"

		else
		    exit
		fi
	    fi
	    ;;

	POST)
	    [ "${line[0]}" == 'Content-Length:' ] &&
		length=$(clean_data "${line[1]}")

	    if [[ "$length" =~ ^[0-9]+$ ]] && ((length>0))
	    then
		## read -n 0
		while read test_line
		do
		    [ -z "$(clean_data "$test_line")" ] &&
			break
		done
		read -n $length POST_DATA

		run_data "$POST_DATA"
		serve_file "$file_output"
	    fi
	    ;;

	*)
	    return 1
	    ;;
    esac
    return 0
}


## MAIN:
while read -a line
do
    recv "${line[*]}"

    case "${line[0]}" in
	GET)
	    unset GET_DATA file_output
	    http_method=GET
	    start_timeout=$(date +%s)

	    get_file_output file_output "${line[1]}"

	    if [[ "${line[1]}" =~ '?' ]]
	    then
	    	GET_DATA="$(clean_data "${line[1]#*\?}")"
	    fi
	    ;;

	POST)
	    unset POST_DATA file_output
	    http_method=POST

	    get_file_output file_output "${line[1]}"
	    ;;

	*)
	    http_server || exit 1 ## client non-web sono disabilitati, per ora. In seguito:
	    ## run_cmd "${line[@]}"
	    ;;
    esac
done
