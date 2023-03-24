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
    get_language
    local path_gui
    ICON="$path_usr"/gui/icon-32x32.png
    local title=$(gettext "Download directory") \
	  text=$(gettext "Select the download destination directory:") \
	  button_quit=$(gettext "Quit") \
	  button_select=$(gettext "Select") \
	  IMAGE2="$path_usr"/gui/zdl.png
    
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
		       --button="${button_quit}!gtk-close":1 \
		       --button="${button_select}!gtk-yes":0 2>/dev/null)
	if [ "$?" == 0 ]
	then
	    if [ -n "$1" ]
	    then
		declare -n ref="$1"
		ref="$path_gui"

	    else
		echo "$path_gui"
	    fi
	    return 0

	else
	    return 1
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
		text_out_gui[$n]="${item:0:120}   ${percent_out[i]}\%   ${eta_out[i]}   ${speed_out_gui[n]}"
	    fi	

	    if [ -z "${text_out_gui[$n]}" ]
	    then
		text_out_gui[$n]="${item:0:120}  $(gettext "wait")"
	    fi
	    
	    if [ "${percent_out[i]}" == 100 ]
	    then
		text_out_gui[$n]="${item:0:120}   $(gettext "download completed")"
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
		text_out_gui[$n]="${link:0:120}   $(gettext "wait")"
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
		text_out_gui[$n]="${link:0:120}   $(gettext "wait")"
		percent_out_gui[$n]=0
		((n++))
	    done < "$start_file"		 
	fi
    fi

    if check_instance_daemon &>/dev/null ||
	    check_instance_prog &>/dev/null
    then
	text_out_gui[$n]=$(gettext "Active")
	percent_out_gui[$n]="50"

    else
	text_out_gui[$n]=$(gettext "Inactive")
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
    local item arg msg

    if ! check_instance_prog &>/dev/null &&
	    ! check_instance_daemon &>/dev/null
    then
	mkdir -p "$path_tmp"
	date +%s >"$path_tmp"/.date_daemon

	if [ -n "${args[*]}" ]
	then
	    nohup /bin/bash zdl --silent "$PWD" "${args[@]}" &>/dev/null &
	    for ((i=0; i<=$max_args; i++))
	    do
		if [[ "${args[i]}" =~ ^http ]]
		then
		    args[i]=$(sanitize_url "${args[i]}")
		fi
		url "${args[i]}" &&
		    unset args[i]
	    done
	    
	else
	    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &
	fi

    else
	for ((i=0; i<=$max_args; i++))
	do
	    if [[ "${args[i]}" =~ ^http ]]
	    then
		args[i]=$(sanitize_url "${args[i]}")
	    fi

	    if url "${args[i]}"
	    then
		msg=$(set_link + "${args[i]}")
		if [ -n "$msg" ]
		then
		    display_link_error_gui "$msg"
		else
		    echo "${args[i]}" >> links.txt
		fi
		unset args[i]
	    fi
	done
    fi
    start_daemon_msg="<b>${name_prog}:</b>\n\n$(gettext "The program is active in")\n\t$PWD\n\n $(gettext "You can control it with:")\n\t$prog -i \"$PWD\"\n"
}

function stop_daemon_gui {
    local pid
    
    if [ -d "$path_tmp" ] &&
	   [ -f "$path_tmp/.pid.zdl" ]
    then
	read pid < "$path_tmp/.pid.zdl"

	check_pid $pid &&
	    kill -9 $pid &>/dev/null
	
	rm -f "$path_tmp"/.date_daemon

	check_instance_daemon
	kill -9 $daemon_pid
	
	if check_instance_daemon &>/dev/null ||
		check_instance_prog &>/dev/null
	then
	    start_daemon_msg="<b>${name_prog}:</b>\n\n$(gettext "The program is still active in")\n\t$PWD\n\n $(gettext "You can control it with:")\n\t$prog -i \"$PWD\"\n"
	    return 1

	else
	    start_daemon_msg="<b>${name_prog}:</b>\n\n$(gettext "The program was killed in")\n\t$PWD\n\n $(gettext "You can control it with:")\n\t$prog -i \"$PWD\"\n"
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
    local pid_file="$1" pid

    if [ -s "$pid_file" ]
    then
	read pid < "$pid_file"
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
    kill_yad_multiprogress
    kill_pid_file "$exit_file"
    local pid=$(get_pid_regex "yad\0--title=Console\0--image=.+${PWD//\//\\/}\\\n")
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
	kill -9 $pid
    fi
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
    declare -a cmd

    if [ -s "$yad_button_result_file" ]
    then
	read -a cmd < "$yad_button_result_file"
        rm "$yad_button_result_file"

        eval "${cmd[@]}"
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

    msg="$(gettext "<b>Some links were not accepted </b> because they do not have the correct form, here are the error messages (the summary is saved in the zdl_log.txt file):")\n\n$msg"
    
    yad --center \
	--title=$(gettext "Warning!") \
	--window-icon="$ICON" \
	--borders=5 \
	--image "dialog-error" \
	--text="$msg" \
	--button="gtk-ok:0" \
	"${YAD_ZDL[@]}" 2>/dev/null
}

function edit_links_gui {
    local title="Editor links"
    local pid=$(get_pid_regex "yad\0--title=$title\0--image=.+\\\n")

    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
        return 1
    fi

    {
	declare -a links
	local matched text

	local start_file_tmp=$(mktemp)
	if [ -s "$start_file" ]
	then
	    cp "$start_file" "$start_file_tmp"
	fi
	
	text="$TEXT\n\n$(gettext "Edit the list of links to start downloading:")\n$(gettext "head to each link (the spaces between the lines and around the links will be ignored)")\n"	
	links=(
	    $(yad --title="$title" \
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
		  --button="$(gettext "Save")!gtk-ok:0" \
		  --button="$(gettext "Cancel")!gtk-no:1" \
		  "${YAD_ZDL[@]}" 2>/dev/null)
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
			sanitize_url "$link" link
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
    while [ -f "$path_tmp"/load_download_manager_gui_lock.$GUI_ID ]
    do
	sleep 0.1
    done
    touch "$path_tmp"/load_download_manager_gui.lock.$GUI_ID
    
    local item length pid dler file percent link
    get_data_multiprogress &>/dev/null

    echo -e "\f"
    for ((i=1; i<="${#url_out_gui[@]}"; i++))
    do
	link="${url_out_gui[i]}"
	length=$(length_to_human "${length_out_gui[i]}")
	[ -z "$length" ] && length=0

	if [[ "${pid_out_gui[i]}" =~ ^([0-9]+)$ ]] &&
	       [ "${pid_out_gui[i]}" != 0 ]
	then
	    pid="${pid_out_gui[i]}"
	else
	    pid="-"
	fi

	if [ -n "${downloader_out_gui[i]}" ]
	then
	    dler="${downloader_out_gui[i]}"
	else
	    dler="-"
	fi

	if [ -n "${file_out_gui[i]}" ]
	then
	    file="${file_out_gui[i]}"
	else
	    file="-"
	fi

	if [[ "${percent_out_gui[i]}" =~ ^([0-9]+)$ ]]
	then
	    percent="${percent_out_gui[i]}"
	else
	    percent=0
	fi

	printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
	      "$link" "$percent" "$file" "$length" "$dler" "$pid"
    done

    rm -f "$path_tmp"/load_download_manager_gui.lock.$GUI_ID
}

function display_download_manager_gui {
    local pid=$(get_pid_regex "yad\0--list\0--grid-lines=hor\0--multiple\0--title=Downloads\0.+\\\n")    
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
        return 1
    fi

    exec 33<&-
    local waiting=15
    
    export PIPE_03=/tmp/yadpipe03.$GUI_ID
    test -e $PIPE_03 && rm -f $PIPE_03
    mkfifo $PIPE_03
    exec 33<> $PIPE_03

    local text="${TEXT}\n\n$(gettext "Select one or more downloads (Ctrl + Click) and press the button to choose the function or double click on a download:")"
    
    {
	declare -a res
	while :
	do
	    load_download_manager_gui >$PIPE_03
	    touch "$path_tmp"/start_display_download_lock.$GUI_ID
	    
	    res=($(yad --list --grid-lines=hor \
		       --multiple \
		       --title="Downloads" \
		       --width=1200 --height=300 \
		       --image-on-top \
		       --text="$text" \
		       --image="$IMAGE2" \
		       --expand-column=3 \
		       --hide-column=6 \
		       --column "Link" --column "%:BAR" --column "File" --column "$(gettext "Length")" --column "DLer" --column "PID" \
		       --separator=' ' \
		       --button="$(gettext "Update")!gtk-refresh!$(gettext "Update the download table (automatically every") $waiting seconds":"bash -c \"echo 'load_download_manager_gui' > '$yad_download_manager_result_file'\"" \
		       --button="Play!gtk-media-play-ltr!$(gettext "Play the selected audio/video file")":4 \
		       --button="$(gettext "Stop")!gtk-stop!$(gettext "Stop the selected download process. If ZDL core is active, the download will be restarted")":2  \
		       --button="$(gettext "Stop all")!gtk-stop!$(gettext "Stop all downloads. If ZDL core is active, the downloads will be restarted"):bash -c \"echo 'kill_downloads &>/dev/null' > '$yad_download_manager_result_file'\"" \
		       --button="$(gettext "Remove")!gtk-delete!$(gettext "Stop selected downloads and delete files")":0  \
		       --button="$(gettext "Completed")!gtk-refresh!$(gettext "Remove completed downloads from the list"):bash -c \"echo 'eval no_complete=true; data_stdout; load_download_manager_gui' > '$yad_download_manager_result_file'\"" \
		       --button="Log!dialog-information!$(gettext "Read the info on the downloads in progress or already made"):bash -c \"echo 'display_download_manager_log' > '$yad_download_manager_result_file'\"" \
		       --button="$(gettext "Close")!gtk-close!Chiudi questa finestra":1  \
		       --listen \
		       --dclick-action="bash -c \"echo 'yad_download_manager_dclick %s' >'$yad_download_manager_result_file'\"" \
		       "${YAD_ZDL[@]}" \
		       --borders=0 < $PIPE_03 2>/dev/null))

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
			for ((i=0; i<${#res[@]}; i=i+6))
			do
			    set_link - "${res[i]}"

			    [[ "${res[i+5]}" =~ ^([0-9]+)$ ]] &&
			    	kill -9 "${res[i+5]}" &>/dev/null

			    [ "${res[i+2]}" != '-' ] &&
			    	rm -f "${res[i+2]}" \
				   "${res[i+2]}.st" \
				   "${res[i+2]}.zdl" \
				   "${res[i+2]}.aria2" \
				   "$path_tmp"/"${res[i+2]}_stdout.tmp" \
				   "$path_tmp"/"${res[i+2]}.MEGAenc_stdout.tmp"
			done
		    fi
		    ;;
		4)
		    play_gui "${res[2]}"
		    ;;
	    esac
	done 
    } &
    pid=$!
    
    while ! check_pid $pid
    do
	sleep 0.1
    done
    
    while :
    do
	exe_button_result "$yad_download_manager_result_file" >$PIPE_03
	if test ! -s "$exit_file"
	then
	    kill -9 $pid
	    kill -9 $(get_pid_regex "yad\0--list\0--grid-lines=hor\0--multiple\0--title=Downloads\0.+\\\n")
	fi
	check_pid $pid || break
	sleep 0.1
    done &
    
    while :
    do
	if [ -f "$path_tmp"/start_display_download_lock.$GUI_ID ]
	then
	    sleep 5
	    rm -f "$path_tmp"/start_display_download_lock.$GUI_ID
	fi

	load_download_manager_gui >$PIPE_03

	if test ! -s "$exit_file"
	then
	    kill -9 $pid
	    kill -9 $(get_pid_regex "yad\0--list\0--grid-lines=hor\0--multiple\0--title=Downloads\0.+\\\n")
	fi
	check_pid $pid || break
    	sleep $waiting
    done &
}

function play_gui {
    local target="$1"
    local msg_error
    [ -f "$target" ] &&
	local mime_type=$(file -b --mime-type "$target")
    
    if [ -z "$player" ] #&>/dev/null
    then	
	msg_error=$(gettext "No audio/video player has been configured")
	
    elif [[ ! "$mime_type" =~ (audio|video) ]]
    then	
	msg_error="$target $(gettext "is not an audio/video file.")\n\nmime-type: $mime_type"
	
    else
	nohup $player "$target" &>/dev/null &
    fi

    if [ -n "$msg_error" ]
    then
	yad --title="$(gettext "Warning!")" \
	    --text="$msg_error" \
	    --image="dialog-error" \
	    --center \
	    --on-top \
	    --button="$(gettext "Close")":0 \
	    "${YAD_ZDL[@]}" 2>/dev/null &	
    fi
}

function yad_download_manager_dclick {
    declare -a res
    res=( "$@" )
    
    local text="$TEXT\n\n<b>Link:</b>\n${res[0]}\n\n<b>$(gettext "Choose what to do:")</b>"
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
		    rm -f "${res[2]}" \
		       "${res[2]}.st" \
		       "${res[2]}.zdl" \
		       "${res[2]}.aria2" \
		       "$path_tmp"/"${res[2]}_stdout.tmp" \
		       "$path_tmp"/"${res[2]}.MEGAenc_stdout.tmp"
		    ;;
		3)
		    play_gui "${res[2]}"
		    ;;
	    esac
	    kill_pid_file "$path_tmp"/dclick_yad-pid.$GUI_ID
	    
	done < <(
	    yad --text "$text" \
    		--title="$(gettext "Action on a download")" \
    		--image="gtk-execute" \
		--center \
		--on-top \
		--button="$(gettext "Play")!gtk-media-play-ltr!$(gettext "Play the selected audio/video file")":"bash -c 'echo 3'"  \
		--button="$(gettext "Stop")!gtk-stop!$(gettext "Stop the selected download process. If ZDL core is active, the download will be restarted")":"bash -c 'echo 0'"  \
		--button="$(gettext "Remove")!gtk-delete!$(gettext "Stop selected downloads and delete files")":"bash -c 'echo 1'"  \
    		--button="$(gettext "Close")!gtk-close":0  \
    		"${YAD_ZDL[@]}" 2>/dev/null &
	    local pid=$!
	    echo $pid >"$path_tmp"/dclick_yad-pid.$GUI_ID
	)
    } &
}

function display_old_links_gui {
    display_file_gui "$links_log" \
		     "$(gettext "List of links")" \
		     "${TEXT}\n\n$(gettext "List of links already entered")\n"
    
}

function display_download_manager_log {
    display_file_gui "$downloads_log" \
		     "$(gettext "Download activity results")" \
		     "${TEXT}\n\n$(gettext "Log of download operations: in particular, unsuccessful attempts and redirects are recorded")\n"
}

function display_file_gui {
    local filename="$1"
    local title="$2"
    local text="$3"
    
    declare -a uri_opts=(
	--show-uri
	--uri-color=blue 
    )

    exec 88<&-
    
    export PIPE_088=/tmp/yadpipe088.$GUI_ID
    test -e $PIPE_088 && rm -f $PIPE_088
    mkfifo $PIPE_088
    exec 88<> $PIPE_088

    {
	if [ -f "$filename" ]
	then
	    (( $(wc -l <"$filename") >1000 )) && unset uri_opts
	    
	    cat < $PIPE_088 |
		yad --title="$title" \
		    --image="gtk-execute" \
		    --image="$IMAGE2" \
		    --text="$text" \
		    --text-info \
		    --tail \
		    --wrap \
		    --show-uri \
		    --uri-color=blue \
		    --listen \
		    --filename="$filename" \
		    --button="$(gettext "Delete the file")!gtk-delete":"bash -c \"echo -e '\f' >'$filename'; rm '$filename'\"" \
		    --button="$(gettext "Close")!gtk-close":0 \
		    "${YAD_ZDL[@]}" \
		    --width=800 --height=600 2>/dev/null &
	    local pid=$!
	    
	    tail -f "$filename" --pid=$pid </dev/null >>$PIPE_088
	    
	else
	    yad --title="$(gettext "Warning!")" \
		--text="$(eval_gettext "The file \$filename is not available in \$PWD")" \
		--image="dialog-error" \
		--center \
		--on-top \
		--button="$(gettext "Close")!gtk-ok:0" \
		"${YAD_ZDL[@]}" 2>/dev/null
	fi
    } &
}

function browse_xdcc_search {
    x-www-browser "${XDCC_EU_SEARCHKEY_URL}$1" &
}

function get_livestream_list {
    local livestream_list
    
    for chan in "${live_streaming_chan[@]}"
    do
	[ -n "$livestream_list" ] && livestream_list+='!'
	livestream_list+="$chan"
    done
    echo "$livestream_list"
}

function check_livestream_gui {
    if [ -s "$path_tmp"/livestream_gui_pid ]
    then
	local pid
	read pid < "$path_tmp"/livestream_gui_pid
	check_pid $pid &&
	    return 0		
    fi
    return 1
}

function display_livestream_gui {
    local chan="$1" link="$2"
    
    if check_livestream_gui
    then
	return
    fi

    local h=$(date +%H)
    local m=$(date +%M)
    local s=$(date +%S)
    local text button_res

    {
	declare -a res
	## in verticale su 2 colonne e 3 righe:
	#
	# yad --title="Links LIVE stream" \
	#     --image="$IMAGE2" \
	#     --image-on-top \
	#     --text="$text" \
	#     --separator="€" \
	#     --form \
	#     --columns=2 \
	#     --align=left \
	#     --field="<b>Orario di inizio</b> (attuale: $h:$m:$s)":LBL \
	#     --field="Ore:":NUM \
	#     --field="Minuti:":NUM \
	#     --field="Secondi:":NUM \
	#     --field="<b>Durata</b>":LBL \
	#     --field="Ore:":NUM \
	#     --field="Minuti:":NUM \
	#     --field="Secondi:":NUM \
	#     '' $h'!0..23' $m'!0..59' $s'!0..59' '' '!0..23' '!0..59' '!0..59' 

	###### <b>Orario di inizio</b> (attuale:
               
	## in orizzontale su 3 colonne e 2 righe:
        if [ -z "$link"  ] #&&               [[ "$chan" =~ (youtube|dailymotion) ]]
        then
            fres0=$(mktemp)
            fres1=$(mktemp)

            text="${TEXT}\n\n$(gettext "Programming of live broadcasting from") <b>$chan</b>:\n"
      	    yad --plug=123123 \
		--form \
		--separator=' ' \
		--columns=1 \
                --tabnum=1 \
		--align=center \
                --field="$(gettext "Enter livestream URL:")":CE '' 2>/dev/null 1>$fres0 &

            yad --plug=123123 \
                --form \
                --separator=' ' \
                --tabnum=2 \
                --columns=3 \
                --field=" ":LBL \
		--field="$(gettext "Hours:")":NUM \
		--field="":LBL \
		--field=" ":LBL \
		--field="$(gettext "Hours:")":NUM \
		--field="$(gettext "<b> Start time </b> (current:") $h:$m:$s)":LBL \
		--field="$(gettext "Minutes:")":NUM \
		--field="":LBL \
		--field="<b>$(gettext "Duration")</b>":LBL \
		--field="$(gettext "Minutes:")":NUM \
                --field=" ":LBL \
		--field="$(gettext "Seconds:")":NUM \
		--field="":LBL \
		--field=" ":LBL \
		--field="$(gettext "Seconds:")":NUM \
		'' $h'!0..23' '' '' 0'!0..23' '' $m'!0..59' '' '' 0'!0..59' '' $s'!0..59' '' '' 0'!0..59' \
		"${YAD_ZDL[@]}" 2>/dev/null 1>$fres1 &

            yad --paned \
                --key=123123 \
                --title="Links LIVE stream" \
		--image="$IMAGE2" \
		--image-on-top \
		--text="$text"
            
            button_res=$?

            # echo "button_res0: $button_res" >> test
            
            if [ "$button_res" == 0 ] &&
                   [ -s "$fres0" ]
	    then
                link=$(< $fres0)
                link=$(sanitize_url "$link")
                
                url "$link" || unset button_res
            fi        

            res=($(< $fres1))

            # echo "link: $link" >> test
            # echo "res: ${res[@]}" >> test
            # echo "button_res1: $button_res" >> test
        else
            text="${TEXT}\n\n$(gettext "Programming of live broadcasting from") <b>$chan</b> ($link):\n"
	    res=($(yad --title="Links LIVE stream" \
		       --image="$IMAGE2" \
		       --image-on-top \
		       --text="$text" \
		       --form \
		       --separator=' ' \
		       --columns=3 \
		       --align=center \
		       --field=" ":LBL \
		       --field="$(gettext "Hours:")":NUM \
		       --field="":LBL \
		       --field=" ":LBL \
		       --field="$(gettext "Hours:")":NUM \
		       --field="$(gettext "<b> Start time </b> (current:") $h:$m:$s)":LBL \
		       --field="$(gettext "Minutes:")":NUM \
		       --field="":LBL \
		       --field="<b>$(gettext "Duration")</b>":LBL \
		       --field="$(gettext "Minutes:")":NUM \
		       --field=" ":LBL \
		       --field="$(gettext "Seconds:")":NUM \
		       --field="":LBL \
		       --field=" ":LBL \
		       --field="$(gettext "Seconds:")":NUM \
		       '' $h'!0..23' '' '' 0'!0..23' '' $m'!0..59' '' '' 0'!0..59' '' $s'!0..59' '' '' 0'!0..59' \
		       "${YAD_ZDL[@]}" 2>/dev/null))
            
            button_res=$?
        fi
        
        if check_livestream "$link" &&
                [ "$button_res" == 0 ]
	then
            # echo "res: ${res[@]}" >> test
            # echo "button_res: $button_res" >> test
            
	    local now_h=$(printf "%.2d" $h)
	    local now_m=$(printf "%.2d" $m)
	    local now_s=$(printf "%.2d" $s)

	    local start_h=$(printf "%.2d" "${res[0]}")
	    local start_m=$(printf "%.2d" "${res[2]}")
	    local start_s=$(printf "%.2d" "${res[4]}")

	    local duration_h=$(printf "%.2d" "${res[1]}")
	    local duration_m=$(printf "%.2d" "${res[3]}")
	    local duration_s=$(printf "%.2d" "${res[5]}")
	    
	    local start_time="$start_h:$start_m:$start_s"
	    local duration_time="$duration_h:$duration_m:$duration_s"
	    
	    local now_in_sec=$(human_to_seconds $now_h $now_m $now_s)       
	    local start_time_in_sec=$(human_to_seconds $start_h $start_m $start_s)
	    
	    text="$(gettext "The start time is lower than the current one: is it tomorrow?\nIf it is not, ZDL will proceed as soon as possible")"

	    if ((start_time_in_sec<now_in_sec))
	    then
		yad --title "$(gettext "Start time")" \
		    --image dialog-question \
		    --text "$text" \
		    --button=gtk-yes:0 \
		    --button=gtk-no:1 \
		    "${YAD_ZDL[@]}" 2>/dev/null &&
		    start_time+=':tomorrow'
	    fi

	    if [[ ! "$link" =~ \#[0-9]+$ ]] #&& [[ ! "$link" =~ (youtube|dailymotion) ]]
	    then 
		tag_link "$link" link
	    fi
	    
	    set_livestream_time "$link" "$start_time" "$duration_time"
	    set_link + "$link"
	    run_livestream_timer "$link" "$start_time"
        fi
    } &
    local pid=$!
    echo $pid > "$path_tmp"/livestream_gui_pid

    wait $pid
}

function display_link_manager_gui {
    local pid=$(get_pid_regex "yad\0--form\0--columns=1\0--title=Links\0--image=.+\\\n")
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
        return 1
    fi
    
    local IFS_old="$IFS"

    local msg
    local text="${TEXT}\n\n<b>$(gettext "Manage the links:")</b>"
    
    ## è strano, ma non funziona per riferimento:
    local livestream_list=$(get_livestream_list)

    {
	declare -a res
	while :
	do
	    IFS="€"
	    res=($(yad --form \
		       --columns=1 \
		       --title="Links" \
		       --image="$IMAGE2" \
		       --image-on-top \
		       --text="$text" \
		       --separator="€" \
		       --align=right \
		       --field="$(gettext "New link:")":CE '' \
		       --field="$(gettext "Live stream:")":CB "^!$livestream_list" \
		       --field="$(gettext "Add .torrent file:")":FL \
		       --field="$(gettext "Search in www.XDCC.eu:")":CE \
		       --field="$(gettext "Add XDCC server:")":CE \
		       --field="$(gettext "Add XDCC channel:")":CE \
		       --field="$(gettext "Add XDCC command:")":CE \
		       --button="$(gettext "Edit links")!gtk-edit!$(gettext "Edit the file from which ZDL core extracts the links to be processed")":"bash -c \"echo edit_links_gui >'$yad_link_manager_result_file'\"" \
		       --button="$(gettext "Read links.txt")!dialog-information!$(gettext "Read the list of links already entered")":"bash -c \"echo display_old_links_gui >'$yad_link_manager_result_file'\"" \
		       --button="$(gettext "Enter")!gtk-execute":0  \
		       --button="$(gettext "Close")!gtk-close":1  \
		       "${YAD_ZDL[@]}" 2>/dev/null))
	    ret=$?
	    IFS="$IFS_old"
	    
	    case $ret in
		0)
		    ## URL http
		    if [ -n "${res[0]}" ]
		    then
			if [[ "${res[0]}" =~ ^http ]]
			then
			    res[0]=$(sanitize_url "${res[0]}")
			fi
			
			msg=$(set_link + "${res[0]}")
			if [ -n "$msg" ]
			then
			    display_link_error_gui "$msg"
			fi
		    fi

                    if [ -z "${res[0]}" ] ||
                            check_livestream "${res[0]}"
                    then                        
                        clean_livestream
		        ## livestream
		        if [ -n "${res[1]}" ]
		        then
                            local link
			    for ((i=0; i<${#live_streaming_chan[@]}; i++))
			    do
			        if [ "${live_streaming_chan[i]}" == "${res[1]}" ]
			        then
                                    if [[ "${res[0]}" =~ (youtube|dailymotion)\. ]]
                                    then
                                        tag_link "${res[0]}" link
                                        
                                    elif [[ ! "${live_streaming_url[i]}" =~ (youtube|dailymotion)\. ]]
                                    then
				        tag_link "${live_streaming_url[i]}" link
				    fi
                                    
				    if check_livestream_link_time "$link"
				    then
				        text=$(gettext "<b> A schedule already exists for this channel: </b>
you can delete the previous one and create a new one or leave the previous one and cancel this operation
<b> Do you want to create a new schedule, deleting the previous one? </b>")
				        
				        if yad --title "$(gettext "Already existing")" \
					       --image dialog-question \
					       --text "$text" \
					       --button=gtk-yes:0 \
					       --button=gtk-no:1 \
					       "${YAD_ZDL[@]}" #2>/dev/null
				        then
					    if data_stdout
					    then
					        for ((j=0; j<${#pid_out[@]}; j++))
					        do
						    if [ "$link" == "${url_out[j]}" ] &&
						           check_pid "${pid_out[j]}"
						    then
						        kill -9 "${pid_out[j]}"
						    fi
						    
						    if [ "$link" == "${url_out[j]}" ] &&
						           [ -f "${file_out[j]}" ]
						    then
						        rm -f "${file_out[j]}" "$path_tmp"/"${file_out[j]}"_stdout.* "$path_tmp"/"${file_out[j]}".MEGAenc_stdout.* 
						    fi
					        done					    
					    fi
				        else					
					    break
				        fi
				    fi

				    display_livestream_gui "${live_streaming_chan[i]}" "$link"
				    break
			        fi
			    done
                        fi
		    fi
		    		    
		    ## torrent
		    if [ -f "${res[2]}" ] &&
			 [[ "$(file -b --mime-type "${res[2]}")" =~ ^application\/(octet-stream|x-bittorrent)$ ]]
		    then
			local ftorrent="${res[2]}"
			[ "${ftorrent}" == "${ftorrent%.torrent}" ] &&
			    mv "${ftorrent}" "${ftorrent}.torrent"
			set_link + "${ftorrent%.torrent}.torrent"
		    fi

		    ## cerca XDCC
		    if [ -n "${res[3]}" ]
		    then
			display_xdcc_eu_gui "${res[3]}"
		    fi

		    ## campi XDCC
		    if [[ -n "${res[4]}" && -n "${res[5]}" && -n "${res[6]}" ]]
		    then
			declare -A irc
			## server XDCC
			irc[host]="${res[4]}"
			irc[host]="${irc[host]## }"
			irc[host]="${irc[host]#'irc://'}"
			irc[host]="${irc[host]%%'/'*}"
			irc[host]="${irc[host]%% }"
		
			## cerca XDCC
			irc[chan]="${res[5]}"
			irc[chan]="${irc[chan]##*\#}"
			irc[chan]="${irc[chan]%% }"

			## cerca XDCC
			irc[msg]="${res[6]}"
			irc[msg]="${irc[msg]## }"
			irc[msg]="${irc[msg]#'/msg'}"
			irc[msg]="${irc[msg]#'/ctcp'}"
			irc[msg]="${irc[msg]%% }"
			
			set_link + "$(sanitize_url "irc://${irc[host]}/${irc[chan]}/msg ${irc[msg]}" >>"$start_file")"
			unset irc

		    elif [[ -n "${res[4]}${res[5]}${res[6]}" ]]
		    then
			yad --title="Attenzione" \
			    --image="dialog-error" \
			    --text="<b>ZigzagDownLoader</b>\n\n$(gettext "You have not entered a form field required to download via XDCC: repeat the operation")" \
			    "${YAD_ZDL[@]}" 2>/dev/null &
		    fi
		    print_links_txt
		    ;;
		1)
		    break
		    ;;
	    esac
	done
	IFS="$IFS_old"
    } &
    pid=$!
    while ! check_pid $pid
    do
	sleep 0.1
    done
    
    while :
    do
	exe_button_result "$yad_link_manager_result_file"
	if test ! -s "$exit_file"
	then
	    kill -9 $pid
	    kill -9 $(get_pid_regex "yad\0--form\0--columns=1\0--title=Links\0--image=.+\\\n") 
	fi
	check_pid $pid || break
	sleep 0.2
    done &
    
    IFS="$IFS_old"
}


function display_sockets_gui {
    local title="Sockets"
    local pid=$(get_pid_regex "yad\0--form\0--title=$title\0.+\\\n")    
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
        return 1
    fi

    declare -a socket_ports
    local port
    while read port
    do
	! check_port $port &&
	    socket_ports+=( $port )
    done < "$path_server"/socket-ports

    local text="${TEXT}\n\n$(gettext "Enable or disable TCP connections:")\n$(gettext "enter a free port")\n\n"
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
	text+="<b>$(gettext "Sockets already enabled:")</b>\n"
	for port in "${socket_ports[@]}"
	do
	    text+="$port\n"
	done
	text+="\n"
    else
	text+="<b>$(gettext "No socket enabled")</b>\n"
    fi

    {
	res=($(yad --form \
		   --title="$title" \
		   --image="$IMAGE2" \
		   --text "$text" \
		   --on-top \
		   --center \
		   --align=right \
		   --field="$(gettext "Socket port:")":NUM "$default_port!1024..65535" \
		   --field="$(gettext "Command:")":CB "$(gettext "Start")!$(gettext "Stop")" \
		   --button="$(gettext "Enter")!gtk-ok":0 \
		   --button="$(gettext "Close")!gtk-close":1 \
		   --separator=' ' \
		   "${YAD_ZDL[@]}" 2>/dev/null))

	[ "$?" == 0 ] &&
	    {
		local socket_port="${res[0]}"
		if [ "${res[1]}" == "$(gettext "Start")" ]
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
			    msg_server="$(gettext "New socket started at the port") $socket_port"
			    msg_img="gtk-ok"
			fi
			
		    elif ! check_port "$socket_port"
		    then
			msg_server="$(gettext "Socket already in use at the port") $socket_port"
			msg_img="dialog-error"
			
		    elif [[ "$socket_port" =~ ^([0-9]+)$ ]] &&
			     ((socket_port > 1024)) && ((socket_port < 65535))
		    then
			msg_server=$(eval_gettext "<b>Port \$socket_port not valid!</b>\n\nEnter a natural number between 1024 and 65535 as the TCP port")
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
			    msg_server="$(gettext "Socket stopping failed at the port") $socket_port"
			    msg_img="gtk-dialog-error"
			else
			    msg_server="$(gettext "The socket is stopped at the port") $socket_port"
			    msg_img="gtk-ok"
			fi
		    else
			msg_server="$(gettext "Socket not already available at the port") $socket_port"
			msg_img="gtk-dialog-error"
		    fi
		fi

		if [ -z "$msg_server" ]
		then
		    msg_server="$(gettext "Something didn't work")"
		    msg_img="gtk-dialog-error"		    
		fi
		
		yad --image="$msg_img" \
		    --center \
		    --on-top \
		    "${YAD_ZDL[@]}" \
		    --button="$(gettext "Close")":0 \
		    --text="$msg_server" 2>/dev/null &
	    }
    } &
}

function display_multiprogress_opts {
    local title="$(gettext "Options")"
    local text="$TEXT\n\n"
    local pid=$(get_pid_regex "yad\0--title=$title\0--text=.+\0--form\0--separator=.+")
    
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
	return 1
    fi

    declare -a dlers=( Aria2 Wget Axel )
    local dler
    read dler < "$path_tmp"/downloader
    dlers=( ${dlers[@]//$dler} )
    local downloaders="${dler}!"
    downloaders+=$(tr ' ' '!' <<< "${dlers[*]}")

    local max_dl format
    test -f "$path_tmp"/max-dl && read max_dl < "$path_tmp"/max-dl
    max_dl+="!0..20"
    
    test -f "$path_tmp"/format-post_processor &&
	read format < "$path_tmp"/format-post_processor
    [[ "$format" =~ ^(flac|mp3)$ ]] && format="${BASH_REMATCH[1]}!"
    
    {
	res=($(yad --title="$title" \
    		   --text="$text" \
    		   --form \
    		   --separator=' ' \
		   --on-top \
    		   --center \
		   --image="$IMAGE2" \
		   --align=right \
    		   --field="$(gettext "Default downloader:")":CB "${downloaders#\!}" \
    		   --field="$(gettext "Simultaneous downloads:")":NUM "${max_dl#\!}" \
		   --field="$(gettext "File format:")":CB "${format}$(gettext "Don't convert")!mp3!flac" \
		   --button="$(gettext "Configure")!dialog-information!$(gettext "ZDL configuration")":3 \
		   --button="$(gettext "Update")!gtk-save!$(gettext "Re/Install the latest ZDL update available")":2 \
    		   --button="$(gettext "Save")!gtk-ok!$(gettext "Save the download directory options")":0 \
		   --button="$(gettext "Close")!gtk-close!$(gettext "Cancel the operation and close the window")":1  \
    		   ${YAD_ZDL[@]} 2>/dev/null))
	case $? in
	    0)
    		echo ${res[0]} >"$path_tmp"/downloader
    		echo ${res[1]%[.,]*} >"$path_tmp"/max-dl
		if [[ "${res[2]}" =~ ^(flac|mp3)$ ]]
		then
		    echo "${res[2]}" > "$path_tmp"/format-post_processor
		    echo "$downloaded_by_zdl" >"$path_tmp"/print_out-post_processor 2>/dev/null

		else
		    echo > "$path_tmp"/format-post_processor
		fi
		;;
	    2)
		force_update=true
		check_updates #&		disown
		exit 0
		;;
	    3)
		display_configure_gui
		;;
	esac
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
            --button="Links!gtk-connect!Gestisci i link":"bash -c \"echo display_link_manager_gui >'$yad_multiprogress_result_file'\"" \
            --button="Downloads!browser-download!$(gettext "Manage downloads")":"bash -c \"echo display_download_manager_gui >'$yad_multiprogress_result_file'\"" \
	    --button="$(gettext "Options")!gtk-properties!$(gettext "Change the download control options"):bash -c \"echo 'display_multiprogress_opts' > '$yad_multiprogress_result_file'\"" \
	    --button="$(gettext "ZDL console")!dialog-information!$(gettext "Follow the download manager operations") (ZDL core)":"bash -c \"echo display_console_gui pid_console >'$yad_multiprogress_result_file'\"" \
	    --button="$(gettext "Start/Stop ZDL core")!gtk-execute!$(gettext "Start/Stop the download manager") (ZDL core)":"bash -c \"echo toggle_daemon_gui >'$yad_multiprogress_result_file'\"" \
	    --button="ZDL sockets!gtk-execute!$(gettext "Enable or disable sockets for ZDL access through the network")":"bash -c \"echo display_sockets_gui >'$yad_multiprogress_result_file'\"" \
	    --button="$(gettext "Quit")!gtk-quit!$(gettext "Exit only from the GUI, leaving the downloaders, core or sockets running")":"bash -c \"echo quit_gui >'$yad_multiprogress_result_file'\"" \
	    --title "Main" \
    	    "${YAD_ZDL[@]}" 2>/dev/null &
    
    yad_multiprogress_pid=$!
    echo "$yad_multiprogress_pid" >"$yad_multiprogress_pid_file"
    
    wait $yad_multiprogress_pid
}


function display_console_gui {
    local pid=$(get_pid_regex "yad\0--title=Console\0--image=.+${PWD//\//\\/}\\\n")
    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
	return 1
    fi

    if [ -n "$1" ]
    then
	declare -n ref="$1"
    fi

    exec 99<&-
    
    export PIPE_099=/tmp/yadpipe099.$GUI_ID
    test -e $PIPE_099 && rm -f $PIPE_099
    mkfifo $PIPE_099
    exec 99<> $PIPE_099

    {
	cat < $PIPE_099 |
	    yad --title="Console" \
		--image="$IMAGE2" \
		--text="${TEXT}\n\n$(gettext "Extraction and download process console")\n\n" \
		--text-info \
		--show-uri \
		--uri-color=blue \
		--back=black \
		--fore=white \
		--show-cursor \
		--wrap \
		--tail \
		"${YAD_ZDL[@]}" \
		--button="$(gettext "Clean")!gtk-refresh":"bash -c \"echo -e '\f' >'$gui_log'\"" \
		--button="$(gettext "Close")!gtk-ok:0" \
		--width=800 --height=600 &
	
	local pid=$!
	echo $pid > /tmp/display_console_gui_zdl.pid
	tail -f "$gui_log" --pid=$pid </dev/null >>$PIPE_099
    } &
    #local pid_c=$!
    local pid_c

    while ! check_pid_file /tmp/display_console_gui_zdl.pid
    do
	sleep 0.1
    done

    read pid_c < /tmp/display_console_gui_zdl.pid
    
    if [ -n "$1" ]
    then
	ref="$pid_c"
    fi    
}

function display_configure_gui {
    local title="$(gettext "Configuration")"
    local pid=$(get_pid_regex "yad\0--title=$title\0--text=.+\\\n")

    if [[ "$pid" =~ ^[0-9]+$ ]]
    then
        return 1
    fi

    local res i ret OIFS="$IFS"
    IFS="€"
    {
	source "$file_conf"

	## local locale_code_list=$(awk '/\.UTF-8/{opts = opts "!" $1; }END{print opts}' /usr/share/i18n/SUPPORTED)
	res=($(yad --title="$title" \
		   --text="${TEXT}\n\n$(gettext "Manage ZDL configuration")" \
		   --form \
		   --align=right \
		   --separator='€' \
		   --scroll \
		   --height=700 --width=800 \
		   --image="$IMAGE2" \
		   --field="$(gettext "Default downloader:")":CB "${downloader}!Aria2!Axel!Wget" \
		   --field="$(gettext "Number of download parts for Axel:")":NUM "$axel_parts!1..32" \
		   --field="$(gettext "Number of download parts for Aria2:")":NUM "$aria2_connections!1..16" \
		   --field="$(gettext "Maximum number of concurrent downloads:")":NUM "$max_dl!0..20" \
		   --field="$(gettext "Background color in virtual terminals:")":CB "$background!transparent!black" \
		   --field="$(gettext "Language:")":CB "$language!it!en" \
		   --field="$(gettext "Script/command/program to reconnect the modem/router:")":CE "$reconnecter" \
		   --field="$(gettext "Automatic updates:")":CB "$autoupdate!enabled!disabled" \
		   --field="$(gettext "Script/command/program to play audio/video files:")":MFL "$player" \
		   --field="$(gettext "Default editor to edit the link queue:")":MFL "$editor" \
		   --field="$(gettext "Homonymous files recovery as the option --resume:")":CB "${resume}!enabled!disabled" \
		   --field="$(gettext "Default program startup mode:")":CB "${zdl_mode}!stdout!lite!daemon" \
		   --field="$(gettext "Torrent TCP port:")":NUM "$tcp_port!1024..65535" \
		   --field="$(gettext "Torrent UDP port:")":NUM "$udp_port!1024..65535" \
		   --field="$(gettext "TCP port for sockets (--socket|--web-ui):")":NUM "$socket_port!1024..65535" \
		   --field="$(gettext "Web browser (--web-ui):")":MFL "$browser" \
		   --field="$(gettext "Web User Interface (--socket|--web-ui):")":CB "$web_ui!1!1_flat!2!2_lite" \
		   --button="$(gettext "Configuration backup")!gtk-save":3 \
		   --button="$(gettext "Save")!gtk-ok":2 \
		   --button="$(gettext "Cancel")!gtk-close":0 \
		   "${YAD_ZDL[@]}" 2>/dev/null))
	ret=$?
	case $ret in
	    2)
		for ((i=0; i<${#key_conf[@]}; i++))
		do
		    
		    set_item_conf ${key_conf[i]} "${res[i]}"
		done
		get_conf
		stop_daemon_gui
		start_daemon_gui
		new_yad_multiprogress
		;;
	    3)
		local ext=$(date +%F)
		cp "$file_conf" "$file_conf".$ext
		yad --title="Configuration backup" \
		    --text="$TEXT\n\n\n<b>$(gettext "Configuration backup in"):</b>\n$file_conf.$ext" \
		    --image="gtk-ok" \
		    --button="$(gettext "Close")!gtk-ok":0 \
		    --on-top --center \
		    --borders=10 \
		    "${YAD_ZDL[@]}" 2>/dev/null
		;;
	esac
	IFS="$OIFS"
    } &	
}

function get_GUI_ID {
    GUI_ID=$(date +%s)
}

function check_instance_yad_multiprogress {
    if [ -s "$yad_multiprogress_pid_file" ]
    then
	local pid
	read pid < "$yad_multiprogress_pid_file"
	check_pid $pid &&
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
    local pid_id pid

    if [ -n "$(ls "$path_tmp"/yad_multiprogress_pid.* 2>/dev/null)" ]
    then
	
	while read line
	do
	    if [[ "$line" =~ \.([0-9]+)$ ]]
	    then
		pid_id=${BASH_REMATCH[1]}
		read pid < "$line"
		if check_pid $pid
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

    this_mode=gui

    source $HOME/.zdl/zdl.conf
    prog=zdl
    path_tmp=".${prog}_tmp"
    
    path_usr="/usr/local/share/${prog}"
    start_file="$path_tmp"/links_loop.txt

    #IMAGE="browser-download"
    #ICON="$path_usr"/gui/favicon.png
    ICON="$path_usr"/gui/icon-32x32.png
    TEXT="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD"
    IMAGE="$path_usr"/gui/zdl-64x64.png
    IMAGE2="$path_usr"/gui/zdl.png
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

    if check_instance_gui
    then
	exit
    else
	ls "$path_tmp"/start_file_* "$path_tmp"/exit_file_* "$path_tmp"/yad_* |
	    grep -vP "\\.$GUI_ID\$" |
	    while read line
	    do
		rm -f "$line"
	    done
    fi
    
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
    local id_test
    read id_test < "$exit_file"
    if [ "$id_test" == $GUI_ID  ]
    then
	rm "$exit_file"
	exit
    fi
    tail_recall
}

function check_pid_file {
    local pid

    if [ -s "$1" ] &&
	   read pid < "$1" &&
	   check_pid $pid
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


function display_xdcc_eu_gui {
    TEXTDOMAINDIR=/usr/local/share/locale
    TEXTDOMAIN=zdl
    export TEXTDOMAINDIR
    export TEXTDOMAIN

    get_language

    path_usr="/usr/local/share/zdl"
    ICON="$path_usr"/gui/icon-32x32.png
    TEXT="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD"
    IMAGE="$path_usr"/gui/zdl-64x64.png
    IMAGE2="$path_usr"/gui/zdl.png
    YAD_ZDL=(
	--window-icon="$ICON"
	--borders=5
    )

    test -f "$path_tmp"/xdcc_eu_lock &&
	read pid < "$path_tmp"/xdcc_eu_lock
    local xdcc_eu_searchkey="$1"
    local xdcc_eu_search_link="${XDCC_EU_SEARCHKEY_URL}${xdcc_eu_searchkey// /+}"
    
    get_data_xdcc_eu "$xdcc_eu_search_link"

    local IFS_old="$IFS"
    IFS=' '

    if       [ -z "${link_xdcc_eu[0]}" ]
    then
        local msg="$(gettext "<b>No links found</b> corresponding to the following search keys:") $xdcc_eu_searchkey"
	yad --center \
	    --title="$(gettext "Warning!")" \
	    --window-icon="$ICON" \
	    --borders=5 \
	    --image "dialog-error" \
	    --text="$msg" \
	    --button="gtk-ok:0" \
	    "${YAD_ZDL[@]}" 2>/dev/null
	return 1
    fi

    declare -a data_xdcc_eu
    for ((i=0; i<${#link_xdcc_eu[@]}; i++))
    do
	data_xdcc_eu+=( FALSE "${file_xdcc_eu[i]}" "${length_xdcc_eu[i]}" "${link_xdcc_eu[i]}" )
    done


    declare -a res
    res=($(yad --list --checklist --multiple \
	       --separator=' ' \
	       --title="$(gettext "Search in www.XDCC.eu:")" \
	       --text="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD\n\n$(gettext "Select the links found by xdcc.eu:")" \
    	       --width=1200 --height=300 \
    	       --image-on-top --image="$IMAGE2" \
	       "${YAD_ZDL[@]}" \
	       --column ":CHK" --column "File" --column "$(gettext "Length")" --column "Link" \
	       "${data_xdcc_eu[@]}" 2>/dev/null))

    if [ "$?" == 0 ] &&
	   (( ${#res[@]}>0 ))
    then	    
	for ((i=3; i<${#res[@]}; i=i+4))
	do
	    set_link + "${res[i]}"
	done
    fi
    set_link - "$xdcc_eu_search_link"
    print_links_txt

    IFS="$IFS_old"
}
