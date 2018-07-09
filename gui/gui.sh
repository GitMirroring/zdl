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
		  --center \
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
    
    add_links_file_gui &>/dev/null
    echo > "$links_file_gui_diff"
    rm -f "$links_file_gui_complete"

    local item i link
    local url checked
    
    url_out_gui=()
    file_out_gui=()
    percent_out_gui=()
    eta_out_gui=()
    speed_out_gui=()
    pid_out_gui=()
    text_out_gui=()
    length_out_gui=()
    
    local n=1
    
    if data_stdout &>/dev/null
    then
	for ((i=0; i<${#url_out[*]}; i++))
	do
	    url_out_gui[$n]="${url_out[i]}"
	    file_out_gui[$n]="${file_out[i]}"
	    eta_out_gui[$n]="${eta_out[i]}"
	    speed_out_gui[$n]="${speed_out[i]%.*}${speed_out_type[i]}"
	    pid_out_gui[$n]="${pid_out[i]}"
	    percent_out_gui[$n]="${percent_out[i]}"
	    length_out_gui[$n]="${length_out[i]}"
	    downloader_out_gui[$n]="${downloader_out[i]}"    

	    if [ -n "${file_out[i]}" ]
	    then
		item="${file_out[i]}"
	    else
		item="${url_out[i]}"
	    fi
	    
	    if check_pid "${pid_out_gui[$n]}" &>/dev/null
	    then
		text_out_gui[$n]="$item   ${percent_out[i]}\%   ${eta_out[i]}   ${speed_out_gui[n]}"
	    fi	

	    if [ -z "${text_out_gui[$n]}" ]
	    then
		text_out_gui[$n]="$item   attendi"
	    fi
	    
	    if [ "${percent_out[i]}" == 100 ]
	    then
		text_out_gui[$n]="$item   download completato"
		grep -q "${url_out[i]}" "$links_file_gui_complete" 2>/dev/null ||
		    set_line_in_file + "${url_out[i]}" "$links_file_gui_complete" &>/dev/null
	    fi
	    
	    if url "${url_out_gui[$n]}" &>/dev/null &&
		    [ -n "${text_out_gui[$n]}" ] &&
		    [ -n "${percent_out_gui[$n]}" ]
	    then
		echo "${url_out[i]}" >> "$links_file_gui_diff"
		((n++))
	    fi
	done

	if [ -s "$links_file_gui" ]
	then
	    for link in $(awk 'NR == FNR {file1[$0]++; next} !($0 in file1)' "$links_file_gui_diff" "$links_file_gui")
	    do
		for url in "${url_out_gui[@]}"
		do
		    if [ "$url" == "${url_out_gui[$n]}" ]
		    then
			checked=true
		    fi
		done
		if [ "$checked" != true ]		
		then
		    url_out_gui[$n]="$link"
		    text_out_gui[$n]="${link%%'&'*}   attendi"
		    percent_out_gui[$n]=0
		    ((n++))
		    unset checked
		fi
	    done
	fi
	
    else
	if [ -s "$links_file_gui" ]
	then
	    for link in $(cat "$links_file_gui")
	    do
		for url in "${url_out_gui[@]}"
		do
		    if [ "$url" == "$link" ]
		    then
			checked=true
		    fi
		done
		if [ "$checked" != true ]
		then
		    url_out_gui[$n]="$link"
		    text_out_gui[$n]="${link%%'&'*}   attendi"
		    percent_out_gui[$n]=0
		    ((n++))
		fi
	    done		 
	fi
    fi

    if check_instance_daemon &>/dev/null ||
	    check_instance_prog &>/dev/null
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

function display_link_error_gui {
    local msg="$1"
    msg=$(sanitize_text "$msg")
    msg="<b>Alcuni link non sono stati accettati</b> perché non hanno la forma corretta, ecco i messaggi di errore (il riepilogo è salvato nel file zdl_log.txt):\n\n$msg"
    yad --center \
	--title="Attenzione!" \
	--window-icon="$ICON" \
	--borders=5 \
	--image "dialog-error" \
	--text="$msg" \
	--button="gtk-ok:0" \
	"${YAD_ARGS}"
}

function edit_links_gui {
    {
	declare -a links
	local matched text

	local start_file_tmp=$(tempfile)
	if [ -s "$start_file" ]
	then
	    cp "$start_file" "$start_file_tmp"
	fi
	text="$TEXT\n\nModifica la lista dei link da cui avviare lo scaricamento:
vai a capo ad ogni link (gli spazi fra le righe e intorno ai link saranno ignorati)\n"
	
	links=(
	    $(yad --title="Editor links" \
		  --image="gtk-execute" \
		  --borders=5 \
		  --window-icon="$ICON" \
		  --text="$text" \
		  --text-info \
		  --editable \
		  --show-uri \
		  --uri-color=blue \
		  --listen \
		  --tail \
		  --filename="$start_file_tmp" \
		  --width=800 \
		  --button="Salva!gtk-ok:0" \
		  --button="Annulla!gtk-no:1")
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
		    display_link_error_gui "$msg"
		    return 1
		fi
		print_links_txt
		return 0
		;;

	    1)
		return 1
		;;
	esac    
    } &
    edit_links_gui_pid=$!
}

function print_links_txt {
    if [ -s "$start_file" ]
    then 
	clean_file "$start_file"
	echo >> links.txt 2>/dev/null
	date >> links.txt 2>/dev/null
	cat "$start_file" >> links.txt 2>/dev/null
    fi
}

function quit_gui {
    local pid item
    declare -a pids

    for item in "$yad_multiprogress_pid_file" "$gui_pid_file"
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
    local yad_button_result_file="$1"
    if [ -s "$yad_button_result_file" ]
    then
	cmd=( $(cat "$yad_button_result_file") )
	rm "$yad_button_result_file"

	"${cmd[@]}"
    fi
}

function get_yad_multiprogress_args {
    local i 
    declare -a bars
    
    get_data_progress num_link_bars
    for ((i=1; i<=$num_link_bars; i++))
    do
	bars+=( "--bar=$i:NORM" )
    done
    
    if [ -n "$1" ]
    then
	declare -n ref1="$1"
	ref1="${bars[*]}"
    fi
    
    if [ -n "$2" ]
    then
	declare -n ref2="$2"
	ref2=$num_link_bars
    fi
    
    [ -z "$ref1" ] && return 1 || return 0
}

function load_download_manager_gui {
    local item length
    declare -a items

    get_data_progress

    echo -e '\f'
    for ((i=1; i<="${#url_out_gui[@]}"; i++))
    do
	length=$(length_to_human "${length_out_gui[i]}")
	items=(
	    "${url_out_gui[i]}"
	    "${percent_out_gui[i]}"
	    "${file_out_gui[i]}"
	    "$length"
	    "${downloader_out_gui[i]}"
	    "${pid_out_gui[i]}"
	)

    	for item in "${items[@]}"
    	do
    	    echo "$item"
    	done
    done
}

function display_download_manager_gui {
    exec 33<&-
    exec 44<&-
    exec 0<&-
    export PIPE_03=/tmp/yadpipe03.$GUI_ID
    test -e $PIPE_03 && rm -f $PIPE_03
    mkfifo $PIPE_03
    exec 33<> $PIPE_03

    export PIPE_04=/tmp/yadpipe04.$GUI_ID
    test -e $PIPE_04 && rm -f $PIPE_04
    mkfifo $PIPE_04
    exec 44<> $PIPE_04

    local text="${TEXT}\n\nSeleziona uno o più download (Ctrl+Click) e premi il bottone per scegliere la funzione:" 

    {
	declare -a res
	while :
	do
	    load_download_manager_gui >$PIPE_03
	    res=($(yad --list --grid-lines=hor \
		       --multiple \
		       --title="Downloads" \
		       --width=1200 --height=300 \
		       --text="$text" \
		       --expand-column=3 \
		       --hide-column=6 \
		       --column "Link" --column "%:BAR" --column "File" --column "Grandezza" --column "DLer" --column "PID:NUM" \
		       --separator=' ' \
		       --button="Aggiorna:bash -c \"echo 'load_download_manager_gui' > '$yad_download_manager_result_file'\"" \
		       --button="Arresta":2  \
		       --button="Arresta tutti:bash -c \"echo 'kill_downloads &>/dev/null' > '$yad_download_manager_result_file'\"" \
		       --button="Elimina":0  \
		       --button="Pulisci completati:bash -c \"echo 'eval no_complete=true; data_stdout' > '$yad_download_manager_result_file'\"" \
		       --button="Log downloads:bash -c \"echo 'display_download_manager_log' > '$yad_download_manager_result_file'\"" \
		       --button="Altre opzioni:bash -c \"echo 'display_download_manager_opts' > '$yad_download_manager_result_file'\"" \
		       --button="Chiudi!gtk-close":1  \
		       --listen \
		       --dclick-action="bash -c \"echo 'yad_download_manager_dclick %s' >'$yad_download_manager_result_file'\"" \
		       "${YAD_ZDL[@]}" < $PIPE_03))
	    
	    
	    case $? in
		1)
		    break
		    ;;
		2)
		    if (( ${#res[@]}>0 ))
		    then
			for ((i=5; i<${#res[@]}; i=i+6))
			do
		    	    kill -9 "${res[i]}" &>/dev/null
			done
		    fi
		    ;;
		0)
		    if (( ${#res[@]}>0 ))
		    then
			set_link - "${res[0]}"
			kill -9 "${res[5]}" &>/dev/null
			rm -f "${res[2]}" "${res[2]}.st" "${res[2]}.zdl" "${res[2]}.aria2" "$path_tmp"/"${res[2]}_stdout.tmp"
		    fi
		    ;;
	    esac
	done 
    } &
    local pid=$!
    
    while ! check_pid $pid
    do
	sleep 0.1
    done
    
    while :
    do
	exe_button_result "$yad_download_manager_result_file" >$PIPE_03
    	check_pid $pid || {
	    break
	}
	sleep 0.2
    done &
    
    while :
    do
	load_download_manager_gui >$PIPE_03
	sleep 10
    	check_pid $pid || {
	    break
	}
    done &
}

function yad_download_manager_dclick {
    declare -a res
    res=( "$@" )

    local text="$TEXT\n\n<b>Link:</b>\n${res[0]}\n\nScegli cosa fare"
    {
	while read line
	do
	    case $line in
    		0)
		    kill -9 "${res[5]}" &>/dev/null
		    ;;
		1)
		    set_link - "${res[0]}"
		    kill -9 "${res[5]}" &>/dev/null
		    rm -f "${res[2]}" "${res[2]}.st" "${res[2]}.zdl" "${res[2]}.aria2" \
		       "$path_tmp"/"${res[2]}_stdout.tmp"
		    ;;
	    esac
	    kill -9 $(cat "$path_tmp"/dclick_yad-pid)
	    
	done < <(
	    yad --text "$text" \
    		     --title="Azione su un download" \
    		     --image="gtk-execute" \
    		     --button="Arresta":"bash -c 'echo 0'"  \
    		     --button="Elimina":"bash -c 'echo 1'"  \
    		     --button="Chiudi!gtk-close":0  \
    		     "$YAD_ZDL" &
	    local pid=$!
	    echo $pid >"$path_tmp"/dclick_yad-pid
	)
    } &
}

function display_download_manager_opts {
    declare -a dlers=( Aria2 Wget Axel )
    local dler=$(cat "$path_tmp"/downloader)
    dlers=( ${dlers[@]//$dler} )
    local downloaders="${dler}!"
    downloaders+=$(tr ' ' '!' <<< "${dlers[*]}")

    local max_dl="$(cat "$path_tmp"/max-dl)!0..20"
  
    local text="$TEXT\n\n$downloaders - $max_dl"
    
    {
	declare -a res=($(yad --title="Opzioni di download" \
			  --text="$text" \
			  --form \
			  --separator=' ' \
			  --center \
			  --field="Downloader predefinito":CB "${downloaders#\!}"\
			  --field="Downloads simultanei":NUM "${max_dl#\!}"\
			  --button="Esegui!gtk-execute":0  \
			  --button="Chiudi!gtk-close":1  \
			  ${YAD_ZDL[@]}))
	case $? in
	    0)
		echo ${res[0]} >"$path_tmp"/downloader
		echo ${res[1]%[.,]*} >"$path_tmp"/max-dl
		return 0
		;;
	    1)
		return 1
		;;
	esac
    } &
	
}

function display_download_manager_log {
    declare -a uri_opts=(
	--show-uri
	--uri-color=blue 
    )

    exec 0<&-
    if [ -s "$links_log" ]
    then
	(( $(wc -l <"$links_log") >1000 )) && unset uri_opts
	   
	tail -f "$downloads_log" </dev/null |
	yad --title="Elenco dei link" \
	    --image="gtk-execute" \
	    --text="${TEXT}\n\nLog delle operazioni di download: in particolare, sono registrati i tentativi senza successo e i reindirizzamenti\n" \
	    --text-info \
	    --tail \
	    "${uri_opts[@]}" \
	    --listen \
	    --filename="$downloads_log" \
	    --button="Chiudi!gtk-ok":0 \
	    "${YAD_ZDL[@]}" \
	    --width=800 --height=600 &
	    
    else
	yad --title="Attenzione!" \
	    --text="Il file $downloads_log non è disponibile in $PWD" \
	    --image="dialog-error" \
	    --button="Chiudi!gtk-ok:0" \
	    "${YAD_ZDL[@]}" &
    fi
}

function browse_xdcc_search {
    x-www-browser "http://www.xdcc.eu/search.php?searchkey=$1" &
}

function display_old_links_gui {
    declare -a uri_opts=(
	--show-uri
	--uri-color=blue 
    )

    exec 0<&-
    if [ -s "$links_log" ]
    then
	(( $(wc -l <"$links_log") >1000 )) && unset uri_opts
	   
	tail -f "$links_log" </dev/null |
	yad --title="Elenco dei link" \
	    --image="gtk-execute" \
	    --text="${TEXT}\n\nElenco dei link già immessi\n" \
	    --text-info \
	    --tail \
	    "${uri_opts[@]}" \
	    --listen \
	    --filename="$links_log" \
	    --button="Chiudi!gtk-ok":0 \
	    "${YAD_ZDL[@]}" \
	    --width=800 --height=600 &
	    
    else
	yad --title="Attenzione!" \
	    --text="Il file links.txt non è disponibile in $PWD" \
	    --image="dialog-error" \
	    --button="Chiudi!gtk-ok:0" \
	    "${YAD_ZDL[@]}" &
    fi
}

function display_link_manager_gui {
    local IFS_old="$IFS"
    IFS="€"
    local msg
    # - file torrent

    {
	declare -a res
	while :
	do

	    res=($(yad --form \
		       --columns=1 \
		       --title="Links" \
		       --separator="€" \
		       --field="Link:":CE \
		       --field="File .torrent:":FL \
		       --field="Cerca in www.XDCC.eu":CE \
		       --field="XDCC server:":CE \
		       --field="XDCC canale:":CE \
		       --field="XDCC comando:":CE \
		       --button="Edita links":"bash -c \"echo edit_links_gui >'$yad_link_manager_result_file'\"" \
		       --button="Leggi links.txt":"bash -c \"echo display_old_links_gui >'$yad_link_manager_result_file'\"" \
		       --button="Esegui!gtk-execute":0  \
		       --button="Chiudi!gtk-close":1  \
		       "${YAD_ZDL[@]}"))

	    case $? in
		0)
		    ## URL http
		    if [ -n "${res[0]}" ]
		    then
			msg=$(set_link + "${res[0]}")
			if [ -n "$msg" ]
			then
			    display_link_error_gui "$msg"
			fi
		    fi

		    ## torrent
		    if [ -f "${res[1]}" ] &&
			 [[ "$(file -b --mime-type "${res[1]}")" =~ ^application\/(octet-stream|x-bittorrent)$ ]]
		    then
			local ftorrent="${res[1]}"
			[ "${ftorrent}" == "${ftorrent%.torrent}" ] &&
			    mv "${ftorrent}" "${ftorrent}.torrent"
			set_link + "${ftorrent%.torrent}.torrent"
		    fi

		    ## cerca XDCC
		    if [ -n "${res[2]}" ]
		    then
			browse_xdcc_search "${res[2]}"
		    fi

		    ## campi XDCC
		    if [[ -n "${res[3]}" && -n "${res[4]}" && -n "${res[5]}" ]]
		    then
			declare -A irc
			## server XDCC
			irc[host]="${res[3]}"
			irc[host]="${irc[host]## }"
			irc[host]="${irc[host]#'irc://'}"
			irc[host]="${irc[host]%%'/'*}"
			irc[host]="${irc[host]%% }"
		
			## cerca XDCC
			irc[chan]="${res[4]}"
			irc[chan]="${irc[chan]## '#'}"
			irc[chan]="${irc[chan]%% }"

			## cerca XDCC
			irc[msg]="${res[5]}"
			irc[msg]="${irc[msg]## }"
			irc[msg]="${irc[msg]#'/msg'}"
			irc[msg]="${irc[msg]#'/ctcp'}"
			irc[msg]="${irc[msg]%% }"
			
			set_link + "$(sanitize_url "irc://${irc[host]}/${irc[chan]}/msg ${irc[msg]}" >>"$start_file")"
			unset irc
		    elif [[ -n "${res[3]}${res[4]}${res[5]}" ]]
		    then
			yad --title="Attenzione" \
			    --image="dialog-error" \
			    --text="<b>ZigzagDownLoader</b>\n
Non hai inserito un campo del form necessario ad effettuare il download tramite XDCC: ripeti l'operazione" \
			    "${YAD_ZDL[@]}" &
		    fi
		    print_links_txt
		    ;;
		1)
		    break
		    ;;
	    esac
	done
    } &
    local pid=$!
    while ! check_pid $pid
    do
	sleep 0.1
    done
    
    while :
    do
	exe_button_result "$yad_link_manager_result_file"
    	check_pid $pid || {
	    break
	}
	sleep 0.2
    done &
    
    IFS=$IFS_old
}

function get_status_sockets_gui {
    :
}

function display_sockets_gui {
    declare -a socket_ports=( $(get_status_sockets_gui) )
    local text="${TEXT}\n\nAvvia e arresta connessioni web (socket TCP): indicare una porta TCP libera\n\n"    
    local msg_img msg_server
    
    local default_port=8080
    if [ -n "${socket_ports[*]}" ]
    then
	local port
	for port in "${socket_ports[@]}"
	do
	    ((default_port==port)) &&
		((default_port++))
	done
    fi
    
    local completion_ports="^${default_port}"
    if [ -n "${socket_ports[*]}" ]
    then
	text+="<b>Socket già attivi:</b>\n"
	for port in "${socket_ports[@]}"
	do
	    completion_ports+="!$port"
	    text+="$port\n"
	done
	text+="\n"
    else
	text+="Socket non ancora avviati\n"
    fi
   
    {
	res=($(yad --form \
		  --text "$text" \
		  --field="Porta socket:CE" "$completion_ports" \
		  --field="Comando:CB" "Avvia!Arresta" \
		  --separator=' ' \
		  "${YAD_ZDL[@]}"))
	case $? in
	    0)
		# if [ "${res[1]}" == Avvia ]
		# then
		#     local socket_port="${res[0]}"
		#     #/usr/local/bin/zdl -s "$socket_port" --no-input &
		# fi

		local socket_port="${res[0]}"

		if [[ "$socket_port" =~ ^([0-9]+)$ ]] &&
		       ((socket_port > 1024)) && ((socket_port < 65535))
		then
		    {
			if [ "${res[1]}" == Avvia ]
			then
			    if ! check_instance_server $socket_port &>/dev/null
			    then
				if run_zdl_server $socket_port
				then
				    msg_server="Avviato nuovo socket alla porta $socket_port"
				    msg_img="gtk-ok"
				fi
				
			    elif ! check_port "$socket_port"
			    then
				msg_server="Socket già in uso alla porta $socket_port"
				msg_img="gtk-dialog-error"

			    else
				msg_server="Socket non avviato alla porta $socket_port"
				msg_img="gtk-dialog-error"
			    fi
			else
			    msg_server="Da implementare"
			fi
			yad --image="$msg_img" \
			    --text="$msg_server"
		    } &			
	        else
		    yad --image="dialog-error" \
			--text="<b>Porta $socket_port non valida!</b>\nInserire una porta TCP valida (assicurati che sia libera):\nnumero naturale compreso fra 1024 e 65535"
		    return 1
		fi
		;;
	    1)
		return 1
		;;
	esac
    } &
}

function display_multiprogress_gui {
    local res i err_msg yad_bars
    get_yad_multiprogress_args yad_bars num_link_bars

    rm -f "$yad_button_result_file"

    while : 
    do
	exec 0<&-
	check_yad_multiprogress
	get_data_progress
	sleep 0.3
	    
	exe_button_result "$yad_multiprogress_result_file"
	    
    done 2>/dev/null |
	yad --multi-progress \
	    --align=right \
	    $yad_bars \
	    --bar="ZDL:PULSE" \
	    --image="$IMAGE" \
	    --image-on-top \
	    --text="$TEXT" \
	    --buttons-layout=center \
	    --button="Links:bash -c \"echo display_link_manager_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Downloads!browser-download:bash -c \"echo display_download_manager_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Console ZDL:bash -c \"echo display_console_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Dis/Attiva ZDL core!gtk-execute:bash -c \"echo toggle_daemon_gui >'$yad_multiprogress_result_file'\"" \
	    --button="ZDL sockets!gtk-execute:bash -c \"echo display_sockets_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Esci!gtk-close:bash -c \"echo quit_gui >'$yad_multiprogress_result_file'\"" \
	    --title "Principale" \
    	    "${YAD_ZDL[@]}" &

    yad_multiprogress_pid=$!
    echo "$yad_multiprogress_pid" >"$yad_multiprogress_pid_file"
    
    wait $yad_multiprogress_pid
    return 0
}

function display_console_gui {
    exec 0<&-
    tail -f "$gui_log" </dev/null |
	yad --title="Console" \
	    --image="gtk-execute" \
	    --text="${TEXT}\n\nConsole dei processi di estrazione e donwload\n\n" \
	    --text-info \
	    --show-uri \
	    --uri-color=blue \
	    --listen \
	    --tail \
	    --filename="$gui_log" \
	    "${YAD_ZDL[@]}" \
	    --button="Chiudi!gtk-ok:0" \
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
    local pid_id 

    if [ -n "$(ls "$path_tmp"/yad_multiprogress_pid.* 2>/dev/null)" ]
    then
	
	while read line
	do
	    if [[ "$line" =~ \.([0-9]+)$ ]]
	    then
		pid_id=${BASH_REMATCH[1]}
		if check_pid $(cat "$line")
		then
		    return 0
		else
		    kill -9 $(cat "$path_tmp"/gui_pid.$pid_id 2>/dev/null) &>/dev/null
		    return 1
		fi
	    fi
	done < <(ls -1t "$path_tmp"/yad_multiprogress_pid.*)
    else
	while read line
	do	    
	    kill -9 $line &>/dev/null
	done < <(cat "$path_tmp"/gui_pid.* 2>/dev/null)
    fi
    rm -f "$path_tmp"/gui_pid.*
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

    IMAGE="$path_usr"/webui/zdl-64x64.png
    IMAGE2="$path_usr"/webui/zdl-32x32.png
    #IMAGE="browser-download"
    #ICON="$path_usr"/webui/favicon.png
    ICON="$path_usr"/webui/icon-32x32.png
    TEXT="  <b>ZigzagDownLoader</b>\n\n  <b>Directory:</b> $PWD"
    
    get_GUI_ID
    links_log="links.txt"
    downloads_log="zdl_log.txt"
    gui_pid_file="$path_tmp"/gui_pid.$GUI_ID
    links_file_gui="$path_tmp"/links_file_gui.$GUI_ID
    links_file_gui_diff="$path_tmp"/links_file_gui_diff.$GUI_ID
    links_file_gui_complete="$path_tmp"/links_file_gui_complete.$GUI_ID
    yad_multiprogress_result_file="$path_tmp"/yad_multiprogress_result.$GUI_ID
    yad_multiprogress_pid_file="$path_tmp"/yad_multiprogress_pid.$GUI_ID
    yad_download_manager_pid_file="$path_tmp"/yad_download_manager_pid.$GUI_ID
    yad_download_manager_result_file="$path_tmp"/yad_download_manager_result_file.$GUI_ID
    yad_link_manager_pid_file="$path_tmp"/yad_link_manager_pid.$GUI_ID
    yad_link_manager_result_file="$path_tmp"/yad_link_manager_result_file.$GUI_ID
    rm -f "$yad_button_result_file"
    rm -f "$path_tmp"/flag-start-links-gui
    
    YAD_ZDL=(
	--window-icon="$ICON"
	--borders=5
	--selectable-labels
    )

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
	display_multiprogress_gui
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

