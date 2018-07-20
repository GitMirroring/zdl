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

### usate prima di run_gui:

function get_download_path {
    local path_gui
    ICON="$path_usr"/webui/icon-32x32.png
    local title="Directory di download"
    local text="Seleziona la directory di destinazione dei download:"
    local IMAGE2="$path_usr"/webui/zdl.png
    
    if hash yad
    then
	path_gui=$(yad --file-selection \
		       --directory \
		       --image="$IMAGE2" \
		       --image-on-top \
		       --text="$text" \
		       --title="$title" \
		       --center \
		       --window-icon "$ICON" \
		       --borders=5 \
		       --width=800 \
		       --height=600 \
		       --button="Esci!gtk-close":1 \
		       --button="Seleziona!gtk-yes":0)
	if [ "$?" == 0 ]
	then
	    echo "$path_gui"
	fi
    fi
}

#### usate DA run_gui in poi:

function add_start_file_gui {
    if [ -s "$start_file" ]
    then
	cp "$start_file" "$start_file_gui" &&
	    return 0 || return 1
    else
	rm -f "$start_file_gui" 
	return 1
    fi
}

function get_data_multiprogress {
    unset url_out_gui \
	  file_out_gui \
	  percent_out_gui \
	  eta_out_gui \
	  speed_out_gui \
	  pid_out_gui \
	  text_out_gui
    
#    add_start_file_gui &>/dev/null
    echo > "$start_file_gui_diff"
    rm -f "$start_file_gui_complete"

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
		grep -q "${url_out[i]}" "$start_file_gui_complete" 2>/dev/null ||
		    set_line_in_file + "${url_out[i]}" "$start_file_gui_complete" &>/dev/null
	    fi
	    
	    if url "${url_out_gui[$n]}" &>/dev/null &&
		    [ -n "${text_out_gui[$n]}" ] &&
		    [ -n "${percent_out_gui[$n]}" ]
	    then
		echo "${url_out[i]}" >> "$start_file_gui_diff"
		((n++))
	    fi
	done

	if [ -s "$start_file" ]
	then
	    while read link
	    do
		url_out_gui[$n]="$link"
		text_out_gui[$n]="${link%%'&'*}   attendi"
		percent_out_gui[$n]=0
		((n++))
	    done < <(awk 'NR == FNR {file1[$0]++; next} !($0 in file1)' "$start_file_gui_diff" "$start_file")
	fi
	
    else
	if [ -s "$start_file" ]
	then
	    while read link
	    do
		url_out_gui[$n]="$link"
		text_out_gui[$n]="${link%%'&'*}   attendi"
		percent_out_gui[$n]=0
		((n++))
	    done < "$start_file"		 
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

########################## CORE:

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



##########################################

function kill_pid_file {
    local pid_file="$1"

    if [ -s "$pid_file" ]
    then
	local pid=$(cat "$pid_file")
	[ -z "$2" ] &&
	    rm "$pid_file"
	kill -9 $pid
    fi
}

function kill_yad_multiprogress {
    kill_pid_file "$yad_multiprogress_pid_file"
}

function new_yad_multiprogress {
    kill_yad_multiprogress no-remove-pid-file
    display_multiprogress_gui
    kill_pid_file "$exit_file"
    exit
}

function quit_gui {
    #echo $GUI_ID > "$exit_file"
    kill_yad_multiprogress
    kill_pid_file "$exit_file"
    exit
}

function check_yad_multiprogress {
    local num_link_bars_status
    get_data_multiprogress num_link_bars_status
    if (( num_link_bars_status != num_link_bars ))
    then
	num_link_bars=$num_link_bars_status
	new_yad_multiprogress
    fi
}

###########################################

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
    
    get_data_multiprogress num_link_bars
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


#####################################################


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
		  --text="$text" \
		  --text-info \
		  --editable \
		  --show-uri \
		  --uri-color=blue \
		  --listen \
		  --tail \
		  --width=800 --height=600 \
		  --filename="$start_file_tmp" \
		  --width=800 \
		  --button="Salva!gtk-ok:0" \
		  --button="Annulla!gtk-no:1" \
		  "${YAD_ZDL}")
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

function load_download_manager_gui {
    local item length
    declare -a items

    get_data_multiprogress

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
    local waiting=15
    
    export PIPE_03=/tmp/yadpipe03.$GUI_ID
    test -e $PIPE_03 && rm -f $PIPE_03
    mkfifo $PIPE_03
    exec 33<> $PIPE_03

    export PIPE_04=/tmp/yadpipe04.$GUI_ID
    test -e $PIPE_04 && rm -f $PIPE_04
    mkfifo $PIPE_04
    exec 44<> $PIPE_04

    local text="${TEXT}\n\nSeleziona uno o più download (Ctrl+Click) e premi il bottone per scegliere la funzione o fai doppio click su un download:" 

    {
	declare -a res
	while :
	do
	    load_download_manager_gui >$PIPE_03
	    res=($(yad --list --grid-lines=hor \
		       --multiple \
		       --title="Downloads" \
		       --width=1200 --height=300 \
		       --image-on-top \
		       --text="$text" \
		       --image="$IMAGE2" \
		       --expand-column=3 \
		       --hide-column=6 \
		       --column "Link" --column "%:BAR" --column "File" --column "Grandezza" --column "DLer" --column "PID:NUM" \
		       --separator=' ' \
		       --button="Aggiorna!gtk-refresh!Aggiorna la tabella dei download (automatico ogni $waiting secondi):bash -c \"echo 'load_download_manager_gui' > '$yad_download_manager_result_file'\"" \
		       --button="Play!gtk-media-play-ltr!Riproduci il file audio/video selezionato":4 \
		       --button="Arresta!gtk-stop!Arresta il processo di download selezionato. Se ZDL core è attivo, il download sarà riavviato":2  \
		       --button="Arresta tutti!gtk-stop!Arresta tutti i download. Se ZDL core è attivo, i download saranno riavviati:bash -c \"echo 'kill_downloads &>/dev/null' > '$yad_download_manager_result_file'\"" \
		       --button="Elimina!gtk-delete!Arresta i download selezionati e cancella i file":0  \
		       --button="Completati!gtk-refresh!Togli i download completati dall'elenco:bash -c \"echo 'eval no_complete=true; data_stdout; load_download_manager_gui' > '$yad_download_manager_result_file'\"" \
		       --button="Log!dialog-information!Leggi le info sui download in corso o già effettuati:bash -c \"echo 'display_download_manager_log' > '$yad_download_manager_result_file'\"" \
		       --button="Chiudi!gtk-close!Chiudi questa finestra":1  \
		       --listen \
		       --dclick-action="bash -c \"echo 'yad_download_manager_dclick %s' >'$yad_download_manager_result_file'\"" \
		       "${YAD_ZDL[@]}" \
		       --borders=0 < $PIPE_03))
	    
	    
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
		4)
		    play_gui "${res[2]}"
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
	sleep $waiting
    	check_pid $pid || {
	    break
	}
    done &
}

function play_gui {
    local target="$1"
    local msg_error
    
    if [ -z "$player" ] #&>/dev/null
    then	
	msg_error="Non è stato configurato alcun player per audio/video"
	
    elif [[ ! "$(file -b --mime-type "$target")" =~ (audio|video) ]]
    then	
	msg_error="Non è un file audio/video"
	
    else
	nohup $player "$target" &>/dev/null &
    fi

    if [ -n "$msg_error" ]
    then
	yad --title="Attenzione" \
	    --text="$msg_error" \
	    --image="dialog-error" \
	    --center \
	    --on-top \
	    --button="Chiudi":0 \
	    "${YAD_ZDL[@]}" &	
    fi
}

function yad_download_manager_dclick {
    declare -a res
    res=( "$@" )

    local text="$TEXT\n\n<b>Link:</b>\n${res[0]}\n\n<b>Scegli cosa fare:</b>"
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
		3)
		    play_gui "${res[2]}"
		    ;;
	    esac
	    kill_pid_file "$path_tmp"/dclick_yad-pid.$GUI_ID
	    
	done < <(
	    yad --text "$text" \
    		     --title="Azione su un download" \
    		     --image="gtk-execute" \
		     --center \
		     --on-top \
		     --button="Riproduci!gtk-media-play-ltr!Riproduci il file audio/video selezionato":"bash -c 'echo 3'"  \
    		     --button="Arresta!gtk-stop!Arresta il processo di download selezionato. Se ZDL core è attivo, il download sarà riavviato":"bash -c 'echo 0'"  \
    		     --button="Elimina!gtk-delete!Arresta il processo di download selezionato e ancella il file":"bash -c 'echo 1'"  \
    		     --button="Chiudi!gtk-close":0  \
    		     "$YAD_ZDL" &
	    local pid=$!
	    echo $pid >"$path_tmp"/dclick_yad-pid.$GUI_ID
	)
    } &
}

function display_old_links_gui {
    display_file_gui "$links_log" \
		     "Elenco dei link" \
		     "${TEXT}\n\nElenco dei link già immessi\n"
    
}

function display_download_manager_log {
    display_file_gui "$downloads_log" \
		     "Risultati attività di download" \
		     "${TEXT}\n\nLog delle operazioni di download: in particolare, sono registrati i tentativi senza successo e i reindirizzamenti\n"
}

function display_file_gui {
    local filename="$1"
    local title="$2"
    local text="$3"
    
    declare -a uri_opts=(
	--show-uri
	--uri-color=blue 
    )
    {
	if [ -f "$filename" ]
	then
	    (( $(wc -l <"$filename") >1000 )) && unset uri_opts
	    
	    tail -f "$filename" |
		yad --title="$title" \
		    --image="gtk-execute" \
		    --image="$IMAGE2" \
		    --text="$text" \
		    --text-info \
		    --tail \
		    "${uri_opts[@]}" \
		    --listen \
		    --filename="$filename" \
		    --button="Cancella il file!gtk-delete":"bash -c \"echo -e '\f' >'$filename'; rm '$filename'\"" \
		    --button="Chiudi!gtk-close":0 \
		    "${YAD_ZDL[@]}" \
		    --width=800 --height=600
	    
	else
	    yad --title="Attenzione!" \
		--text="Il file $filename non è disponibile in $PWD" \
		--image="dialog-error" \
		--center \
		--on-top \
		--button="Chiudi!gtk-ok:0" \
		"${YAD_ZDL[@]}"
	fi
    } &
}

function browse_xdcc_search {
    x-www-browser "http://www.xdcc.eu/search.php?searchkey=$1" &
}

function display_link_manager_gui {
    local IFS_old="$IFS"
    IFS="€"
    local msg
    local text="${TEXT}\n\n<b>Gestisci i link:</b>"

    {
	declare -a res
	while :
	do

	    res=($(yad --form \
		       --columns=1 \
		       --title="Links" \
		       --image="$IMAGE2" \
		       --image-on-top \
		       --text="$text" \
		       --separator="€" \
		       --align=right \
		       --field="Nuovo link:":CE \
		       --field="Aggiungi file .torrent:":FL \
		       --field="Cerca in www.XDCC.eu:":CE \
		       --field="Aggiungi XDCC server:":CE \
		       --field="Aggiungi XDCC canale:":CE \
		       --field="Aggiungi XDCC comando:":CE \
		       --button="Edita links!gtk-edit!Modifica il file da cui ZDL core estrae i link da processare":"bash -c \"echo edit_links_gui >'$yad_link_manager_result_file'\"" \
		       --button="Leggi links.txt!dialog-information!Leggi l'elenco dei link già immessi":"bash -c \"echo display_old_links_gui >'$yad_link_manager_result_file'\"" \
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

function display_sockets_gui {
    declare -a socket_ports
    local port
    while read port
    do
	! check_port $port &&
	    socket_ports+=( $port )
    done < "$path_server"/socket-ports

    local text="${TEXT}\n\nAttiva o disattiva connessioni TCP:\nindicare una porta libera\n\n"
    local title="Sockets"
    local msg_img msg_server

    local default_port=8080
    if [ -n "${socket_ports[*]}" ]
    then
	local port
	for port in "${socket_ports[@]}"
	do
	    ((default_port == port)) &&
		((default_port++))
	done
    fi
    
    if [ -n "${socket_ports[*]}" ]
    then
	text+="<b>Socket già attivati:</b>\n"
	for port in "${socket_ports[@]}"
	do
	    text+="$port\n"
	done
	text+="\n"
    else
	text+="<b>Nessun socket attivato</b>\n"
    fi

    {
	res=($(yad --form \
		   --title="$title" \
		   --image="$IMAGE2" \
		   --text "$text" \
		   --on-top \
		   --center \
		   --align=right \
		   --field="Porta socket:":NUM "$default_port!1024..65535" \
		   --field="Comando:":CB "Attiva!Disattiva" \
		   --button="Esegui!gtk-ok":0 \
		   --button="Chiudi!gtk-close":1 \
		   --separator=' ' \
		   "${YAD_ZDL[@]}"))

	[ "$?" == 0 ] &&
	    {
		local socket_port="${res[0]}"
		if [ "${res[1]}" == Attiva ]
		then
		    local PWD_TO_SERVER_PATHS=$(realpath "$PWD")
		    if ! set_line_in_file in "$PWD_TO_SERVER_PATHS$" "$path_server"/paths.txt
		    then
			echo "$PWD_TO_SERVER_PATHS" >>"$path_server"/paths.txt
		    fi
		    
		    if ! check_instance_server $socket_port &>/dev/null
		    then
	    		unset start_socket
	    		if run_zdl_server $socket_port
	    		then
			    msg_server="Avviato nuovo socket alla porta $socket_port"
			    msg_img="gtk-ok"
			fi
			
		    elif ! check_port "$socket_port"
		    then
			msg_server="Socket già in uso alla porta $socket_port"
			msg_img="dialog-error"
			
		    elif [[ "$socket_port" =~ ^([0-9]+)$ ]] &&
			     ((socket_port > 1024)) && ((socket_port < 65535))
		    then
			msg_server="<b>Porta $socket_port non valida!</b>\n\nInserire come porta TCP un numero naturale compreso fra 1024 e 65535"
			msg_img="dialog-error"
		    else
			msg_server="Socket alla porta $socket_port fallito"
			msg_img="dialog-error"
		    fi	    
		else
		    if ! check_port $socket_port
		    then
			kill_server $socket_port
			sleep 2
			
			if ! check_port $socket_port
			then
			    msg_server="Arresto socket fallito alla porta $socket_port"
			    msg_img="gtk-dialog-error"
			else
			    msg_server="Arrestato socket alla porta $socket_port"
			    msg_img="gtk-ok"
			fi
		    else
			msg_server="Socket già non disponibile alla porta $socket_port"
			msg_img="gtk-dialog-error"
		    fi
		fi

		if [ -z "$msg_server" ]
		then
			msg_server="Qualcosa non ha funzionato"
			msg_img="gtk-dialog-error"		    
		fi
		
		yad --image="$msg_img" \
		    --center \
		    --on-top \
		    "${YAD_ZDL[@]}" \
		    --button="Chiudi":0 \
		    --text="$msg_server" &
	    }
    } &
}

function display_multiprogress_opts {
    declare -a dlers=( Aria2 Wget Axel )
    local dler=$(cat "$path_tmp"/downloader)
    dlers=( ${dlers[@]//$dler} )
    local downloaders="${dler}!"
    downloaders+=$(tr ' ' '!' <<< "${dlers[*]}")

    local max_dl="$(cat "$path_tmp"/max-dl)!0..20"
  
    local text="$TEXT\n\n"
    local format=$(cat "$path_tmp"/format-post_processor 2>/dev/null)
    [[ "$format" =~ ^(flac|mp3)$ ]] && format="${BASH_REMATCH[1]}!"
    
    {
	res=($(yad --title="Opzioni" \
    		   --text="$text" \
    		   --form \
    		   --separator=' ' \
		   --on-top \
    		   --center \
		   --image="$IMAGE2" \
		   --align=right \
    		   --field="Downloader predefinito:":CB "${downloaders#\!}"\
    		   --field="Download simultanei:":NUM "${max_dl#\!}"\
		   --field="Formato del file:":CB "${format}Non convertire!mp3!flac"\
    		   --button="Salva!gtk-save":0 \
		   --button="Chiudi!gtk-close":1  \
    		   ${YAD_ZDL[@]}))
	[ "$?" == 0 ] &&
	    {
    		echo ${res[0]} >"$path_tmp"/downloader
    		echo ${res[1]%[.,]*} >"$path_tmp"/max-dl
		if [[ "${res[2]}" =~ ^(flac|mp3)$ ]]
		then
		    echo "${res[2]}" > "$path_tmp"/format-post_processor
		    echo "scaricati_da_zdl.txt" >"$path_tmp"/print_out-post_processor 2>/dev/null

		else
		    echo > "$path_tmp"/format-post_processor
		fi
	    }
    } &
}

function display_multiprogress_gui {
    local res i err_msg yad_bars
    get_yad_multiprogress_args yad_bars num_link_bars

    rm -f "$yad_multiprogress_result_file"

    while : 
    do
	check_yad_multiprogress
	get_data_multiprogress
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
	    --button="Links!gtk-connect!Gestisci i link:bash -c \"echo display_link_manager_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Downloads!browser-download!Gestisci i download:bash -c \"echo display_download_manager_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Opzioni!gtk-properties!Modifica le opzioni di controllo dei download:bash -c \"echo 'display_multiprogress_opts' > '$yad_multiprogress_result_file'\"" \
	    --button="Console ZDL!dialog-information!Segui le operazioni del gestore di download (ZDL core):bash -c \"echo display_console_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Dis/Attiva ZDL core!gtk-execute!Attiva o disattiva il gestore di download (ZDL core):bash -c \"echo toggle_daemon_gui >'$yad_multiprogress_result_file'\"" \
	    --button="ZDL sockets!gtk-execute!Attiva o disattiva i socket per l'accesso a ZDL attraverso la rete:bash -c \"echo display_sockets_gui >'$yad_multiprogress_result_file'\"" \
	    --button="Esci!gtk-quit!Esci solo dalla GUI, lasciando attivi i downloader, il core o i sockets:bash -c \"echo quit_gui >'$yad_multiprogress_result_file'\"" \
	    --title "Principale" \
    	    "${YAD_ZDL[@]}" &

    yad_multiprogress_pid=$!
    echo "$yad_multiprogress_pid" >"$yad_multiprogress_pid_file"
    
    wait $yad_multiprogress_pid
}

function display_console_gui {
    tail -f "$gui_log" </dev/null |
	yad --title="Console" \
	    --image="$IMAGE2" \
	    --text="${TEXT}\n\nConsole dei processi di estrazione e donwload\n\n" \
	    --text-info \
	    --show-uri \
	    --uri-color=blue \
	    --listen \
	    --tail \
	    --filename="$gui_log" \
	    "${YAD_ZDL[@]}" \
	    --button="Pulisci!gtk-refresh":"bash -c \"echo -e '\f' >'$gui_log'\"" \
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
		    return 1
		fi
	    fi
	done < <(ls -1t "$path_tmp"/yad_multiprogress_pid.*)
    fi
    return 1
}

function check_updates {
    update_updater
}

function run_gui {
    if ! hash yad
    then
	_log 40
	exit 1
    fi

    ARGV=( "$@" )
    this_mode=gui

    . $HOME/.zdl/zdl.conf
    prog=zdl
    path_tmp=".${prog}_tmp"
    
    path_usr="/usr/local/share/${prog}"
    start_file="$path_tmp"/links_loop.txt

    #IMAGE="browser-download"
    #ICON="$path_usr"/webui/favicon.png
    ICON="$path_usr"/webui/icon-32x32.png
    TEXT="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD"
    IMAGE="$path_usr"/webui/zdl-64x64.png
    IMAGE2="$path_usr"/webui/zdl.png
    YAD_ZDL=(
	--window-icon="$ICON"
	--borders=5
    )

    [ -f /tmp/zdl-skip-update-session ] ||
	check_updates
    
    get_GUI_ID
    links_log="links.txt"
    downloads_log="zdl_log.txt"
    start_file_gui_diff="$path_tmp"/start_file_gui_diff.$GUI_ID
    start_file_gui_complete="$path_tmp"/start_file_gui_complete.$GUI_ID
    yad_multiprogress_result_file="$path_tmp"/yad_multiprogress_result.$GUI_ID
    yad_multiprogress_pid_file="$path_tmp"/yad_multiprogress_pid.$GUI_ID
    yad_download_manager_pid_file="$path_tmp"/yad_download_manager_pid.$GUI_ID
    yad_download_manager_result_file="$path_tmp"/yad_download_manager_result_file.$GUI_ID
    yad_link_manager_pid_file="$path_tmp"/yad_link_manager_pid.$GUI_ID
    yad_link_manager_result_file="$path_tmp"/yad_link_manager_result_file.$GUI_ID
    rm -f "$yad_button_result_file"
    rm -f "$path_tmp"/flag-start-links-gui
    
    start_daemon_gui

    check_instance_gui &&
	exit
    
    while ! check_instance_prog &&
	    ! check_instance_daemon
    do
	sleep 0.1
    done

    exit_file="$path_tmp"/exit_file_gui.$GUI_ID
    echo $$ > "$exit_file"
    display_multiprogress_gui
}

function tail_recall {
	display_multiprogress_gui

	if [ "$(cat "$exit_file")" == $GUI_ID  ]
	then
	    rm "$exit_file"
	    exit
	fi
	tail_recall
}

function check_pid_file {
    if [ -s "$1" ] && check_pid $(cat "$1")
    then
	return 0
    else
	return 1
    fi
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


