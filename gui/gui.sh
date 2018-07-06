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

function add_links_file_gui {
    if [ -s "$start_file" ]
    then
	cp "$start_file" "$links_file_gui" &&
	    return 0 || return 1
    else
	rm -f "$links_file_gui" 
	return 1
    fi
}

function check_yad_multiprogress {
    local num_link_bars_status
    get_data_progress num_link_bars_status
    if (( num_link_bars_status != num_link_bars ))
    then
	num_link_bars=$num_link_bars_status
	kill_yad_multiprogress
    fi
}

function get_data_progress {
    unset url_out_gui \
	  file_out_gui \
	  percent_out_gui \
	  eta_out_gui \
	  speed_out_gui \
	  pid_out_gui \
	  text_out_gui
    
    add_links_file_gui    
    echo > "$links_file_gui_diff"
    rm -f "$links_file_gui_complete"

    local item i link

    url_out_gui=()
    file_out_gui=()
    percent_out_gui=()
    eta_out_gui=()
    speed_out_gui=()
    pid_out_gui=()
    text_out_gui=()
    
    local n=1
    
    if data_stdout
    then
	for ((i=0; i<${#url_out[*]}; i++))
	do
	    url_out_gui[$n]="${url_out[i]}"
	    file_out_gui[$n]="${file_out[i]}"
	    eta_out_gui[$n]="${eta_out[i]}"
	    speed_out_gui[$n]="${speed_out[i]%.*}${speed_out_type[i]}"
	    pid_out_gui[$n]="${pid_out[i]}"
	    percent_out_gui[$n]="${percent_out[i]}"
	    
	    if [ -n ${file_out[i]} ]
	    then
		item="${file_out[i]}"
	    else
		item="${url_out[i]}"
	    fi
	    
	    if check_pid ${pid_out_gui[$n]}
	    then
		text_out_gui[$n]="$item   ${percent_out[i]}\%   ${eta_out[i]}   ${speed_out_gui[n]}"
	    fi	

	    if [ -z "${text_out_gui[$n]}" ]
	    then
		text_out_gui[$n]="$item   attendi"
	    fi
	    
	    if [ ${percent_out[i]} == 100 ]
	    then
		text_out_gui[$n]="$item   download completato"
		grep "${url_out[i]}" "$links_file_gui_complete" ||
		    set_line_in_file + "${url_out[i]}" "$links_file_gui_complete"
	    fi
	    
	    if url "${url_out_gui[$n]}" &&
		    [ -n "${text_out_gui[$n]}" ] && [ -n "${percent_out_gui[$n]}" ]
	    then
		echo "${url_out[i]}" >> "$links_file_gui_diff"
		((n++))
	    fi
	done

	for link in $(awk 'NR == FNR {file1[$0]++; next} !($0 in file1)' "$links_file_gui_diff" "$links_file_gui")
	do
	    text_out_gui[$n]="${link%%'&'*}   attendi"
	    percent_out_gui[$n]=0
	    ((n++))
	done
	
    else
	for link in $(cat "$links_file_gui")
	do
	    text_out_gui[$n]="${link%%'&'*}   attendi"
	    percent_out_gui[$n]=0
	    ((n++))
	done		 
    fi

    if check_instance_daemon ||
	    check_instance_prog
    then
	text_out_gui[$n]="Attivo"
	percent_out_gui[$n]="50"

    else
	text_out_gui[$n]="Non attivo"
	percent_out_gui[$n]=""
    fi

    if [[ $1 ]]
    then
	declare -n ref=$1
	## togliere la barra di stato (attività ZDL)
	## e assegnare il numero totale di barre dei soli link:
	ref=$((n-1))
	# echo "$ref =~ $((n-1)) "
	# echo "${url_out_gui[*]}"
    fi
    
    if [ -z "$ref" ]
    then
	for i in $(seq 1 $n)
	do
	    echo "$i:#${text_out_gui[i]}"
	    [ -n "${percent_out_gui[i]}" ] &&
		echo "$i:${percent_out_gui[i]}"	
	done
    fi
}

function get_yad_multiprogress_args {
    declare -n bars="$1"
    declare -n ref="$2"
    local i 
    declare -a _bars

    ## global (array non possono essere usati per riferimento):
    unset yad_download_buttons
    
    get_data_progress num_link_bars
    for ((i=1; i<=$num_link_bars; i++))
    do
	_bars+=( "--bar=$i:NORM" )

	## da implementare:
	yad_download_buttons+=( --button="$i:bash -c \"echo admin_download_gui $i >kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk\"" )
    done
    bars="${_bars[*]}"
    ref=$num_link_bars
    ( [ -z "$bars" ] || [ -z "${yad_download_buttons[*]}" ] ) && return 1 || return 0
}

function admin_download_gui {
    echo "$1">OUT
}

function start_daemon_gui {
    local item arg
    if ! check_instance_prog &>/dev/null &&
	    ! check_instance_daemon &>/dev/null
    then
	mkdir -p "$path_tmp"
	date +%s >"$path_tmp"/.date_daemon
	if [ -n "${ARGV[*]}" ]
	then
	    nohup /bin/bash zdl --silent "$PWD" "${ARGV[@]}" &>/dev/null &
	    unset ARGV
	else
	    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &
	fi

    else
	for item in "${ARGV[@]}"
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

function toggle_daemon_gui {
    if check_instance_daemon &>/dev/null ||
	    check_instance_prog &>/dev/null
    then
	stop_daemon_gui
    else
	start_daemon_gui
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

    for item in "$yad_multiprogress_pid_file" "$gui_pid_file" #"$yad_fields_pid_file"
    do
    	if [ -s "$item" ]
    	then
    	    pids+=( $(cat "$item") )
	    rm "$item"
    	fi
    done

    for pid in ${pids[@]}
    do
	kill -9 $pid 2>/dev/null
    done
}

function kill_yad_multiprogress {
    local pid
    
    if [ -s "$yad_multiprogress_pid_file" ]
    then
	pid=$(cat "$yad_multiprogress_pid_file")
	rm "$yad_multiprogress_pid_file"
	kill -9 $pid &&
	    return 0 ||
		return 1
    fi
}

function exe_button_result {
    if [ -s "$yad_button_result_file" ]
    then
	cmd=( $(cat "$yad_button_result_file") )
	rm "$yad_button_result_file"

	"${cmd[@]}"
    fi
}

function display_links_manager_gui {
    :
}
 
function display_downloads_manager_gui {
    :
    #	--button="Termina i downloader:bash -c \"echo kill_downloads >'$yad_button_result_file'\"" \
    #	"${yad_download_buttons[@]}"
}

function start_links_gui {
    :
        # while ! get_yad_multiprogress_args yad_bars num_link_bars
    # do
    # 	get_links_gui
    # 	wait $get_links_gui_pid

    # 	if [ "$?" == 1 ]
    # 	then
    # 	    break

    # 	elif [ ! -s "$start_file" ]
    # 	then
    # 	    err_msg="<b>$name_prog:</b>\n\nNon è stato inserito alcun link valido: vuoi ripetere l'operazione?\nRispondendo di no terminerai tutto."
    # 	    if ! yad --window-icon="$ICON" \
    # 		 --borders=5 \
    # 		 --image "dialog-question" \
    # 		 --title="Attenzione" \
    # 		 --text="$err_msg" \
    # 		 --button="gtk-yes:0" \
    # 		 --button="gtk-no:1" \
    # 		 --centre
    # 	    then
    # 		stop_daemon_gui
    # 		quit_gui
    		
    # 	    fi
    # 	fi
    # done
}

function display_downloads_gui {
    local res i err_msg yad_bars
    get_yad_multiprogress_args yad_bars num_link_bars

    rm -f "$yad_button_result_file"

    while : 
    do		    
	check_yad_multiprogress
	get_data_progress
	sleep 0.5
	    
	exe_button_result
	    
    done 2>/dev/null |
	yad \
	--multi-progress \
	--align=right \
	$yad_bars \
	--bar="ZDL:PULSE" \
	--image="$IMAGE" \
	--image-on-top \
	--text="<b>Directory:</b> $PWD" \
	--buttons-layout=center \
	--button="Links:bash -c \"echo get_links_gui >'$yad_button_result_file'\"" \
	--button="Downloads:bash -c \"echo kill_downloads >'$yad_button_result_file'\"" \
	--button="Console ZDL:bash -c \"echo display_console_gui >'$yad_button_result_file'\"" \
	--button="Dis/Attiva ZDL!gtk-execute:bash -c \"echo toggle_daemon_gui >'$yad_button_result_file'\"" \
	--button="Esci!gtk-close:bash -c \"echo quit_gui >'$yad_button_result_file'\"" \
	--window-icon "$ICON" \
	--title "ZigzagDownLoader" \
	--border=5 & 

    yad_multiprogress_pid=$!
    echo "$yad_multiprogress_pid" >"$yad_multiprogress_pid_file"
    
    wait $yad_multiprogress_pid
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

function check_instance_yad_multiprogress {
    if [ -s "$yad_multiprogress_pid_file" ]
    then
	check_pid $(cat "$yad_multiprogress_pid_file") &&
	    {
		return 0
	    } || {
		return 1
	    }
    else
	return 1
    fi
}

function check_instance_gui {
    local pid
    
    while read pid
    do
	check_pid $pid && return 0
    done < <(cat "$path_tmp"/gui_pid.* 2>/dev/null)
    return 1
}

function run_gui {
    if ! hash yad
    then
	_log 40
	exit 1
    fi
    
    ARGV=( "$@" )

    prog=zdl
    path_tmp=".${prog}_tmp"
    
    path_usr="/usr/local/share/${prog}"
    start_file="$path_tmp"/links_loop.txt

    exec 0<&-
    echo >"$gui_log"

    ICON="$path_usr"/webui/zdl.png
    IMAGE="browser-download"
    
    get_GUI_ID
    gui_pid_file="$path_tmp"/gui_pid.$GUI_ID
    links_file_gui="$path_tmp"/links_file_gui.$GUI_ID
    links_file_gui_diff="$path_tmp"/links_file_gui_diff.$GUI_ID
    links_file_gui_complete="$path_tmp"/links_file_gui_complete.$GUI_ID
    yad_button_result_file="$path_tmp"/yad_button_result.txt
    yad_multiprogress_pid_file="$path_tmp"/yad_multiprogress_pid.$GUI_ID
    yad_fields_pid_file="$path_tmp"/yad-fields-pid.$GUI_ID
    rm -f "$yad_button_result_file"
    
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
	display_downloads_gui
	sleep 1
    done &
    gui_pid=$!
    echo "$gui_pid" >"$gui_pid_file"

    wait "$gui_pid"
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

