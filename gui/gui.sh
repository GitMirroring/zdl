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

function get_download_path {
    declare -n ref="$1"
    
    if command -v yad &>/dev/null
    then
	ref=$(yad --file-selection \
		  --borders=5 \
		  --directory \
		  --centre \
		  --window-icon "$ICON" \
		  --width=700 \
		  --height=500 \
		  --button="Abbandona!gtk-no:1" \
		  --button="Seleziona!gtk-yes:0" \
		   2>/dev/null)
	if [[ $? == 1 ]]
	then
	    exit 1
	else
	    return 0
	fi
    fi
}

function add_yad_links {
    if [ -s "$start_file" ]
    then
	cp "$start_file" "$yad_links" &&
	    return 0 || return 1
    else
	rm -f "$yad_links" 
	return 1
    fi
}

function check_yad_links {
    local new_gui=1
    if [ -s "$start_file" ]
    then
	(( $(wc -l < "$start_file") == $(wc -l < "$yad_links") )) && new_gui=0
	cp "$start_file" "$yad_links"
    else
	[ -s "$yad_links" ] &&
	    (( $(wc -l < "$yad_links") >0 )) || new_gui=0
	rm -f "$yad_links"
    fi
    return $new_gui
}

function get_data_progress {
    local links_file="$path_tmp"/yad_links.$GUI_ID
    local links_file_diff="$path_tmp"/yad_links_diff.$GUI_ID
    echo > "$links_file_diff"
    local num_links=$(wc -l "$links_file")
    local i link
    local n=1
    local text
    local item
    
    if data_stdout
    then
	for ((i=0; i<${#pid_out[*]}; i++))
	do
	    if [ -n ${file_out[i]} ]
	    then
		item="${file_out[i]}"
	    else
		item="${url_out[i]}"
	    fi
		    
	    if grep -qP "${url_out[i]}" "$links_file" 
	    then
		if [[ ${pid_alive[i]} ]]
		then
		    text="$item   ${percent_out[i]}\%   ${eta_out[i]}   ${speed_out[i]}${speed_out_type[i]}"
	
		    echo "$n:#$text"
		    echo "$n:${percent_out[i]}"

		    status=NORM

		    echo "${url_out[i]}" >> "$links_file_diff"
		    ((n++))
		    
		else
		    if [ ${percent_out[i]} == 100 ]
		    then
			text="$item   download completato"
			
			echo "$n:#$text"
			echo "$n:100"
			
		    else
			text="$item   attendi"
			
			echo "$n:#$text"
			echo "$n:0"
		    fi
		    
		    status=NORM

		    echo "${url_out[i]}" >> "$links_file_diff"
		    ((n++))
		fi
	    fi
	done

	for link in $(awk 'NR == FNR {file1[$0]++; next} !($0 in file1)' "$links_file_diff" "$links_file")
	do
	    text="${link%%'&'*}   attendi"
	    
	    echo "$n:#$text"
	    echo "$n:0"

	    status=NORM

	    ((n++))
	done
	
    else
	for link in $(cat "$links_file")
	do
	    text="${link%%'&'*}   attendi"

	    echo "$n:#$text"
	    echo "$n:0"

	    status=NORM

	    ((n++))
	done		 
    fi

    if check_instance_daemon ||
	    check_instance_prog
    then
	echo "$n:#Attivo"
	echo "$n:100"

    else
	echo "$n:#Non attivo"
    fi

    num_bars=$((n-1))
}

function get_multiprogress_yad_args {
    declare -n bars="$1"
    local i url
    declare -a _bars

    add_yad_links    

    if [ -s "$yad_links" ]
    then
	for ((i=1; i<=$(wc -l < "$yad_links"); i++))
	do
	    _bars+=( "--bar=$i:NORM" )
	done
	bars="${_bars[*]}"
    fi
    
    [ -z "$bars" ] && return 1 || return 0
}

function start_daemon_gui {
    local item arg
    if ! check_instance_prog &>/dev/null &&
	    ! check_instance_daemon &>/dev/null
    then
	mkdir -p "$path_tmp"
	date +%s >"$path_tmp"/.date_daemon
	nohup /bin/bash zdl --silent "$PWD" "$@" &>/dev/null &
    else
	for item in "$@"
	do
	    url "$item" &&
		set_link + "$item"
	done
    fi
    start_daemon_msg="<b>${name_prog}:</b>\n\nProgramma attivo in\n\t$PWD\n\n Puoi controllarlo con:\n\t$prog -i \"$PWD\"\n"
}

function stop_daemon_gui {
    local pid
    
    if [ -d "$path_tmp" ]
    then
	pid=$(cat "$path_tmp/.pid.zdl")

	check_pid $pid &&
	    kill -9 $pid &>/dev/null
	
	rm -f "$path_tmp"/.date_daemon

	check_instance_daemon
	kill -9 $daemon_pid
	
	if check_instance_daemon &>/dev/null ||
		check_instance_prog &>/dev/null
	then
	    start_daemon_msg="<b>${name_prog}:</b>\n\nProgramma ancora in funzione in\n\t$PWD\n\n Puoi controllarlo con:\n\t$prog -i \"$PWD\"\n"
	    return 1

	else
	    start_daemon_msg="<b>${name_prog}:</b>\n\nProgramma terminato in\n\t$PWD\n\n Puoi controllarlo con:\n\t$prog -i \"$PWD\"\n"
	    return 0
	fi
    fi
}

function get_links_gui {
    {
	declare -a links
	local matched

	local start_file_tmp=$(tempfile)
	if [ -s "$start_file" ]
	then
	    cp "$start_file" "$start_file_tmp"
	fi
	
	links=(
	    $(yad --title="Editor links" \
		  --image="gtk-execute" \
		  --borders=5 \
		  --window-icon="$ICON" \
		  --text="<b>ZigzagDownLoader</b>\n\n<b>Directory:</b> $PWD\n
Modifica la lista dei link da cui avviare lo scaricamento:
vai a capo ad ogni link (gli spazi fra le righe e intorno ai link saranno ignorati)\n" \
		  --text-info \
		  --editable \
		  --show-uri \
		  --uri-color=blue \
		  --listen \
		  --tail \
		  --filename="$start_file_tmp" \
		  --centre \
		  --width=800 \
		  --button="Salva!gtk-ok:0" \
		  --button="Annulla!gtk-no:1" \
		  --button="Esci!gtk-close:2")
	)
	
	case $? in
	    0)
		local link msg
		
		if [ -n "${links[*]}" ]
		then
		    if [ -s "$start_file" ]
		    then
			while read line
			do
			    unset matched
			    
			    for link in "${links[@]}"
			    do
				if [ "$line" == "$(sanitize_url "$link")" ]
				then
				    matched=true
				    break
				fi
			    done		    
			    [[ $matched ]] || set_link - "$line"

			done < "$start_file"
		    fi
		    
		    for link in "${links[@]}"
		    do
			link=$(sanitize_url "$link")
			[ -n "$link" ] &&
			    msg+=$(set_link + "$link")
		    done

		else
		    rm -f "$start_file"
		fi

		rm -f  "$start_file_tmp"
		
		if [ -n "$msg" ]
		then
		    msg=$(sanitize_text "$msg")
		    msg="<b>Alcuni link non sono stati accettati</b> perché non hanno la forma corretta, ecco i messaggi di errore (il riepilogo è salvato nel file zdl_log.txt):\n\n$msg"
		    yad --centre \
			--title="Attenzione!" \
			--window-icon="$ICON" \
			--borders=5 \
			--image "dialog-error" \
			--text="$msg" \
			--button="gtk-ok:0"
		fi
		return 0
		;;

	    1)
		return 1
		;;
	    2)
		quit_gui
		return 2
		;;
	esac    
    } &
    get_links_gui_pid=$!
}

function quit_gui {
    local pid item
    declare -a pids

    if [[ $1 && $2 ]]
    then
	pid_gui_file=$1
	pid_yad_loop_file=$2
    fi
    
    for item in "$pid_yad_loop_file" "$pid_gui_file"
    do
	if [ -s "$item" ]
	then
	    pids+=( $(cat "$item") )
	fi
    done

    for pid in ${pids[@]}
    do
	kill -9 $pid
    done
}

function new_gui {
    [ -s "$pid_yad_loop_file" ] &&
	kill -9 $(cat "$pid_yad_loop_file") &&
	return 0 ||
	    return 1
}

function kill_yad_loop {
    [ -s "$pid_yad_loop_file" ] &&
	kill -9 $(cat "$pid_yad_loop_file")
}

function display_downloads {
    local res i err_msg yad_bars

    while ! get_multiprogress_yad_args yad_bars
    do
    	get_links_gui
	wait $get_links_gui_pid
	
    	if [ ! -s "$start_file" ]
    	then
    	    err_msg="<b>$name_prog:</b>\n\nNon è stato inserito alcun link valido: vuoi ripetere l'operazione?\nRispondendo di no terminerai tutto."
    	    if ! yad --window-icon="$ICON" \
		 --borders=5 \
		 --image "dialog-question" \
		 --title="Attenzione" \
		 --text="$err_msg" \
		 --button="gtk-yes:0" \
		 --button="gtk-no:1" \
		 --centre
    	    then
    		stop_daemon_gui
    		quit_gui
    	    fi
    	fi
	
    	sleep 0.5
    done

    rm -f "$path_tmp"/yad-button-click

    yad --multi-progress \
	--align=right \
	$yad_bars \
	--bar="ZDL:PULSE" \
	--borders=5 \
	--image "$IMAGE" \
	--image-on-top \
	--auto-close \
	--button="Editor dei link:bash -c \"echo 3 >'$path_tmp'/yad-button-click\"" \
	--button="Console:bash -c \"echo 4 >'$path_tmp'/yad-button-click\"" \
	--button="Attiva ZDL:bash -c \"echo 0 >'$path_tmp'/yad-button-click\"" \
	--button="Disattiva ZDL:bash -c \"echo 1 >'$path_tmp'/yad-button-click\"" \
	--button="Termina i downloader:bash -c \"echo 2 >'$path_tmp'/yad-button-click\"" \
	--button="Esci!gtk-close:bash -c \"echo quit >'$path_tmp'/yad-button-click\"" \
	--window-icon "$ICON" \
	--title "ZigzagDownLoader" \
	--text "<b>Directory:</b> $PWD" < <(
	while : 
	do		    
	    check_yad_links || new_gui
	    get_data_progress
	    sleep 0.5

	    if [ -s "$path_tmp"/yad-button-click ]
	    then
		res=$(cat "$path_tmp"/yad-button-click)
		rm "$path_tmp"/yad-button-click
		
		case $res in
		    quit)
			quit_gui
			break
			;;
		    0)
			start_daemon
			unset start_daemon_msg
			;;
		    1)
			stop_daemon_gui
			unset stop_daemon_gui_msg
			;;
		    2)
			kill_downloads
			;;
		    3)
			get_links_gui
			;;
		    4)
			display_console_gui
			;;
		esac
	    fi
	    
	done 2>/dev/null 
    ) &

    pid_yad_loop=$!
    echo "$pid_yad_loop" >"$pid_yad_loop_file"
        
    wait $pid_yad_loop
    return 0
}

function display_console_gui {
    tail -f "$gui_log" </dev/null |
	sanitize_text |
	yad --title="Console" \
	    --image="gtk-execute" \
	    --text="<b>$name_prog</b>:\n\nConsole dei processi di estrazione e donwload\n\n" \
	    --text-info \
	    --show-uri \
	    --uri-color=blue \
	    --listen \
	    --tail \
	    --filename="$gui_log" \
	    --window-icon="$ICON" \
	    --center \
	    --borders=5 \
	    --width=800 --height=600 &
}

function get_GUI_ID {
    GUI_ID=$(date +%s)
}

function check_instance_gui {
    local pid
    
    while read pid
    do
	check_pid $pid && return 0
    done < <(cat "$path_tmp"/gui-pid.*)
    return 1
}

function run_gui {
    if ! hash yad
    then
	_log 40
	exit 1
    fi

    ARGV=( "$@" )
    for ((i=0; i<"s{#ARGV[@]}"; i++)) 
    do
	if [ -d "s{ARGV[i]}" ]
	then
	    cd "s{ARGV[i]}" 
	    echo "s{ARGV[i]}" >/tmp/zigzagdownloader-dirbase
	    unset ARGV[i]
	    break
	fi
    done
    
    local directory
    if [[ "${ARGV[@]}" =~ (--path-gui) ]]
    then
	for ((i=0; i<${#ARGV[@]}; i++))
	do
	    if [[ "${ARGV[i]}" =~ ^(--path-gui)$ ]]
	    then
		test -s /tmp/zigzagdownloader-dirbase &&
		    cd $(cat /tmp/zigzagdownloader-dirbase) ||
			cd "$HOME"
		
		if [ ! -d "$directory" ]
		then
		    get_download_path directory
		fi

		echo "$directory" >/tmp/zigzagdownloader-dirbase
		cd "$directory"

		unset ARGV[i]
	    fi
	done
    fi
    prog=zdl
    path_tmp=".${prog}_tmp"
    
    path_usr="/usr/local/share/${prog}"
    start_file="$path_tmp"/links_loop.txt

    gui_log="$path_tmp"/gui-log.txt
    touch "$gui_log"
    exec 0<&-
    echo >"$gui_log"

    ICON="$path_usr"/webui/zdl.png
    IMAGE="browser-download"
    
    get_GUI_ID
    pid_gui_file="$path_tmp"/gui-pid.$GUI_ID
    yad_links="$path_tmp"/yad_links.$GUI_ID
    pid_yad_loop_file="$path_tmp"/yad-pid.$GUI_ID
    rm -f "$path_tmp"/yad-button-click
    
    start_daemon_gui

    check_instance_gui &&
	exit
    
    while ! check_instance_prog &&
	    ! check_instance_daemon
    do
	sleep 0.1
    done
    
    while :
    do
	display_downloads
	sleep 1
    done &
    pid_gui_loop=$!
    echo "$pid_gui_loop" >"$pid_gui_file"

    wait "$pid_gui_loop"
}

####################################################
## per usare questo file come script:
function main {
    prog=zdl
    path_tmp=".${prog}_tmp"
    path_usr="/usr/local/share/${prog}"
    start_file="$path_tmp"/links_loop.txt

    source $path_usr/libs/core.sh
    source $path_usr/libs/DLstdout_parser.sh

    run_gui "$@"
}

[ "$1" == start ] && main "$@"

