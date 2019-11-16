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
# Gianluca Zoni
# http://inventati.org/zoninoz    
# zoninoz@inventati.org
#

function show_downloads {
    local cols
    get_language
    
    if test -f "$path_tmp"/columns
    then
	read cols < "$path_tmp"/columns
	
	while [ -z "$cols" ] || ((cols==0))
	do
	    read cols < "$path_tmp"/columns
	    sleep 0.1
	done
    else
	cols=$COLUMNS
    fi
    
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	if data_stdout
	then
	    stdbuf -oL -eL                                          \
		   awk -f $path_usr/libs/common.awk                 \
		   -f $path_usr/ui/colors-${background}.awk.sh      \
		   -f $path_usr/ui/ui.awk                           \
		   -v cols="$cols"                                  \
		   -v TEXTDOMAIN="$TEXTDOMAIN"                      \
		   -v TEXTDOMAINDIR="$TEXTDOMAINDIR"                \
		   -v Color_Off="$Color_Off"                        \
		   -v Background="$Background"                      \
		   -e "BEGIN {$awk_data display()}" 
	fi
    else
	data_stdout
    fi
}

function show_downloads_lite {
    local no_clear="$1"
    [ -n "$no_clear" ] && force_header=force
    
    cursor off
    
    (( odd_run++ ))
    (( odd_run>1 )) && odd_run=0
    
    if data_stdout "no_check"
    then       
	rm -f "$path_tmp"/no-clear-lite
	header_lite $force_header
	
	stdbuf -oL -eL                                         \
	       awk -f $path_usr/libs/common.awk                \
	       -f $path_usr/ui/colors-${background}.awk.sh     \
	       -f $path_usr/ui/ui.awk                          \
	       -v cols="$COLUMNS"                              \
	       -v TEXTDOMAIN="$TEXTDOMAIN"                     \
	       -v TEXTDOMAINDIR="$TEXTDOMAINDIR"               \
	       -v lines="$LINES"                               \
	       -v no_clear="$no_clear"                         \
	       -v this_mode="lite"                             \
	       -v odd_run="$odd_run"                           \
	       -v Color_Off="$Color_Off"                       \
	       -v Background="$Background"                     \
	       -e "BEGIN {$awk_data display()}" 

    elif [ -f "$start_file" ]
    then
	local connecting="$(gettext "Connecting")"
	header_lite
	check_wait_connecting &&
	    print_header "$BYellow" "" " $connecting ..."  ||
		print_header "$BGreen" "" " $connecting . . . " 

	# [ -f "$path_tmp"/no-clear-lite ] ||
	#     [ -f "$path_tmp"/stop-binding ] ||
	#     clear_lite
    fi
}

function check_wait_connecting {
    if [ -f "$path_tmp"/wait_connecting ]
    then
	rm "$path_tmp"/wait_connecting 
	return 1

    else
	touch "$path_tmp"/wait_connecting
	return 0
    fi
}

function show_downloads_extended {
    unset instance_pid daemon_pid

    fclear
    header_z
    header_box_interactive "$(gettext "Interactive mode")"

    [ -f "$path_tmp/downloader" ] && read downloader_in < "$path_tmp/downloader"
    echo -e "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"

    check_instance_daemon

    if check_instance_daemon
    then
	print_c 1 "$(gettext "%s is active in daemon mode (pid: %s)\n")" "$PROG" "$daemon_pid"
	instance_pid="$daemon_pid"
	
    else
	if check_instance_prog
	then
	    if [ "$this_tty" == "$that_tty" ]
	    then
		term_msg="$(gettext "in this same terminal:") $this_tty (pid: $that_pid)"

	    else
		term_msg="$(gettext "in another terminal:") $that_tty (pid: $that_pid)"
	    fi
	    
	    print_c 1 "$(gettext "%s is running in standard mode %s")\n" "$PROG" "$term_msg" 

	    if [ "$that_tty" != "$this_tty" ]
	    then
		instance_pid="$that_pid"

	    else
		unset instance_pid
	    fi
	else
	    print_c 3 "$(gettext "There are no running instances of %s")\n" "$PROG" 
	fi
    fi

    if data_stdout "no_check"
    then
	stdbuf -oL -eL                                             \
	       awk -f $path_usr/libs/common.awk                    \
	       -f $path_usr/ui/colors-${background}.awk.sh         \
	       -f $path_usr/ui/ui.awk                              \
	       -v cols="$COLUMNS"                                  \
	       -v zdl_mode="extended"                              \
	       -v TEXTDOMAIN="$TEXTDOMAIN"                         \
	       -v TEXTDOMAINDIR="$TEXTDOMAINDIR"                   \
	       -v Color_Off="$Color_Off"                           \
	       -v Background="$Background"                         \
	       -e "BEGIN {$awk_data display()}" 
    fi
}


function services_box {
    local generated
    test -f $path_usr/generated.txt &&
	read generated < "$path_usr"/generated.txt
    
    fclear
    header_z
    header_box_interactive "$(gettext "Extensions")"
    print_C 4 "\n$(gettext "Streaming video skipping the browser player:")" #"\nVideo in streaming saltando il player del browser:"
    cat $path_usr/streaming.txt 2>/dev/null
    
    print_C 4 "\nFile hosting:"
    cat $path_usr/hosting.txt 2>/dev/null

    print_C 4 "\nLive stream:"
    cat $path_usr/livestream.txt 2>/dev/null

    print_C 4 "\n$(gettext "Web-generated links (even after captcha)")"
    echo -e "$generated $(gettext "and other services")"
    
    print_C 4 "\nShort links:"
    cat $path_usr/shortlinks.txt 2>/dev/null

    print_C 4 "\n$(gettext "All downloadable files with the following browser extensions:")"
    echo -e "$(gettext "Flashgot of Firefox/Iceweasel/Icecat, function 'M-x zdl' by Conkeror and script 'zdl-xterm' (XXXTerm/Xombrero and others)")" 

    print_C 4 "\n$(gettext "All downloadable files with the following programs:")"
    cat $path_usr/programs.txt 2>/dev/null
    echo
}


function standard_box {
    [ "$this_mode" == "lite" ] && header_lite_msg=" LITE"
    stdbox=true
    
    [ "$this_mode" == help ] &&
	header_msg="$(gettext "help of commands")" ||
	    header_msg="$(gettext "Standard output mode")${header_lite_msg}"
    header_box "$header_msg"

    [ -n "$init_msg" ] &&
	echo -ne "$init_msg" ||
	    echo
    
    [ -f "$path_tmp/downloader" ] && 
	read downloader_in < "$path_tmp/downloader"
    
    print_c 0 "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"
    #[ -z "$1" ] && services_box
    
    commands_box
    if [ -z "$1" ] &&
	   [ -n "$binding" ]
    then
	echo -e "${BBlue}       │${Color_Off}"
	header_box "$(gettext "Readline: enter URLs and service links")"
	echo -e ""

    elif [ -z "$1" ] &&
	   [ -n "$live_streaming" ]
    then
	echo -e "${BBlue}       │${Color_Off}"
	header_box "$(gettext "Live stream: select the live channel")"
	echo -e ""

    elif [ "$1" == help ] &&
	   [ -z "$binding" ]
    then
	echo -en "${BBlue}       │${Color_Off}"
	pause

    elif [ "$this_mode" != "lite" ] &&
	   [ -z "$binding" ]
    then
	separator- 7
	print_c 0 "\n"
    fi
}


function commands_box {
    header_dl "$(gettext "Commands in standard output mode (key M=Meta: <Alt>, <Ctrl> or <Esc>)")"

    echo -e "$(eval_gettext "\${BGreen} ENTER \${BBlue}│\${Color_Off}  enter a link and type \${BGreen}ENTER
\${BGreen} M-x   \${BBlue}│\${Color_Off}  performs downloads [e\${BGreen}x\${Color_Off}ec]
\${BGreen} M-e   \${BBlue}│\${Color_Off}  starts the default \${BGreen}e\${Color_Off}ditor
\${BGreen} M-c   \${BBlue}│\${Color_Off}  \${BGreen}c\${Color_Off}lean the information of the completed downloads
       \${BBlue}│\${Color_Off}
\${BYellow} M-i   \${BBlue}│\${Color_Off}  \${BYellow}i\${Color_Off}nteractive mode
\${BYellow} M-C   \${BBlue}│\${Color_Off}  \${BYellow}C\${Color_Off}onfigure \$PROG
       \${BBlue}│\${Color_Off} 
\${BRed} M-q   \${BBlue}│\${Color_Off}  close ZDL without interrupting the downloaders [\${BRed}q\${Color_Off}uit]
\${BRed} M-k   \${BBlue}│\${Color_Off}  kill all processes [\${BRed}k\${Color_Off}ill]
       \${BBlue}│\${Color_Off} 
\${BBlue} M-t   │\${Color_Off}  browse the \${BBlue}t\${Color_Off}utorial
\${BBlue} M-l   │\${Color_Off}  available services \${BBlue}l\${Color_Off}ist
\${BBlue} M-h   │\${Color_Off}  displays this box [\${BBlue}h\${Color_Off}elp]")"
    
}

function readline_links {
    local link    
    ## binding = {  true -> while immissione URL
    ##             unset -> break immissione URL                    }

    [ "$this_mode" != lite ] &&
	msg_end_input="$(gettext "URL entry completed: download start")\n" 

    ## bind -x "\"\C-l\":\"\"" 2>/dev/null
    bind -x "\"\C-x\":\"unset binding; print_c 1 '${msg_end_input}'; return\"" 2>/dev/null
    bind -x "\"\ex\":\"unset binding; print_c 1 '${msg_end_input}'; return\"" 2>/dev/null

    cursor on
    
    while :
    do
	trap_sigint
	read -e link
	link=$(sanitize_url "$link")

	[ -n "$link" ] &&
	    set_link + "$link"
	unset break_loop
    done
    
}


function trap_sigint {
    local next="$1"
    [ -z "$next" ] && next='trap "echo -n \"\"" SIGINT'
    
    if [[ "$1" == ^[0-9]+$ ]]
    then
	kill_pids="kill -9 $@; kill -9 $loops_pid; kill -9 $pid_prog"
	trap "$kill_pids" SIGINT
    else
	## trap "trap SIGINT; stty echo; kill -9 $loops_pid; exit 1" SIGINT
	########
	## disattivato per il bind aggiuntivo con ctrl:
	## \C-c per cancellare i file temporanei dei download completati
	trap "no_complete=true; data_stdout; unset no_complete; $next" SIGINT
    fi
}

function bindings {
    if [ "$this_mode" != "lite" ] ||
	   [ -n "$binding" ]
    then
	trap_sigint

    elif [ "$this_mode" == "lite" ]
    then

	trap_sigint return
    fi
    
    check_instance_prog

    stty stop ''
    stty start ''
    stty -ixon
    stty -ixoff
    stty -echoctl
    
    ## Alt:
    bind -x "\"\ei\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\eh\":\"change_mode help\"" 2>/dev/null
    bind -x "\"\ee\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\el\":\"change_mode list\"" 2>/dev/null
    bind -x "\"\et\":\"change_mode info\"" 2>/dev/null
    bind -x "\"\eq\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls irc-pids &>/dev/null; kill_external &>/dev/null; kill -9 $loops_pid &>/dev/null; kill -1 $pid_prog\"" &>/dev/null
    bind -x "\"\ek\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls xfer-pids &>/dev/null; kill_pid_urls irc-pids &>/dev/null; kill_downloads &>/dev/null; kill_server; kill_ffmpeg; kill -9 $loops_pid &>/dev/null; kill -9 $pid_prog\"" &>/dev/null
    bind -x "\"\ec\":\"no_complete=true; data_stdout; unset no_complete; export READLINE_LINE=' '\"" &>/dev/null
    bind -x "\"\eC\":\"change_mode configure\"" 2>/dev/null
    
    ## Ctrl:
    bind -x "\"\C-i\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\C-h\":\"change_mode help\"" 2>/dev/null
    bind -x "\"\C-e\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\C-l\":\"change_mode list\"" 2>/dev/null
    bind -x "\"\C-t\":\"change_mode info\"" 2>/dev/null
    bind -x "\"\C-q\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls irc-pids &>/dev/null; kill_external &>/dev/null; kill -9 $loops_pid &>/dev/null; kill -1 $pid_prog\"" &>/dev/null
    bind -x "\"\C-k\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls xfer-pids &>/dev/null; kill_pid_urls irc-pids &>/dev/null; kill_downloads &>/dev/null; kill_server; kill_ffmpeg; kill -9 $loops_pid &>/dev/null; kill -9 $pid_prog\"" &>/dev/null
    bind -x "\"\C-c\":\"no_complete=true; data_stdout; unset no_complete; export READLINE_LINE=' '\"" &>/dev/null
    bind -x "\"\C-C\":\"change_mode configure\"" 2>/dev/null
}

function change_mode {
    local cmd=$1
    local change_out

    start_mode_in_tty "$cmd" "$this_tty"
    #cursor off

    case $cmd in
	configure)
	    zdl --configure
	    init
	    source $path_usr/ui/widgets.sh
	    ;;

	interactive)
	    zdl --interactive
	    ;;
	
	editor)
	    $editor "$path_tmp"/links_loop.txt
	    clean_file "$start_file"
	    ;;
    
	info)
	    command -v pinfo &>/dev/null &&
	    	pinfo -x zdl ||
		    info zdl
	    ;;
	
	list)
	    zdl --list-extensions
	    ;;

	'help')
	    $path_usr/help_bindings.sh
	    ;;
    esac
    
    start_mode_in_tty "$this_mode" "$this_tty"
    export READLINE_LINE=" "
    
    if [ "$this_mode" != "lite" ] ||
	   [ -n "$binding" ]
    then
	change_out=$(
	    fclear
	    header_z
	    standard_box
		  )
	echo -en "$change_out"
	trap_sigint
	
	[ -n "$binding" ] &&
	    command -v setterm &>/dev/null &&
	    setterm -cursor on

    elif [ "$this_mode" == "lite" ]
    then
	header_lite
	trap_sigint return
    fi

    if [ "$this_mode" != "lite" ] &&
	   [ -z "$binding" ]
    then
	zero_dl show ||
	    show_downloads
    fi
}

function interactive {
    this_mode=interactive
    start_mode_in_tty "$this_mode" "$this_tty"
    
    trap "trap SIGINT; die" SIGINT

    while true
    do
	unset instance_pid daemon_pid that_pid that_tty list file_stdout file_out url_out downloader_out pid_out length_out

	show_downloads_extended
	if test -f "$path_tmp/max-dl"
	then
	    read max_dl < "$path_tmp/max-dl"
	else
	    max_dl=1
	fi
	
	if [ -z "$max_dl" ]
	then
	    num_downloads=$(gettext "unlimited")
	else
	    num_downloads=$max_dl
	fi
	
	header_box_interactive "$(gettext "Options [number of simultaneous downloads:") $num_downloads]" 
	
	echo -e "$(eval_gettext "\${BYellow}   s \${Color_Off}│ \${BYellow}s\${Color_Off}elect one or more downloads (to restart, delete, play audio/video files)\n     │
\${BGreen}   e \${Color_Off}│ change the queue of links to be downloaded, using the default \${BGreen}e\${Color_Off}ditor\n     │")"

	local Axel Aria2 Wget
	Axel="$(eval_gettext "\${BGreen}   a \${Color_Off}│ download with \${BGreen}a\${Color_Off}xel\n")"	
	Aria2="$(eval_gettext "\${BGreen}   A \${Color_Off}│ download with \${BGreen}A\${Color_Off}ria2\n")"
	Wget="$(eval_gettext "\${BGreen}   w \${Color_Off}│ download with \${BGreen}w\${Color_Off}get\n")"
	
	unset $downloader_in
	echo -en "$Axel$Aria2$Wget" 
	
	echo -e "$(eval_gettext "     │\n\${BGreen} 0-9 \${Color_Off}│ download \${BGreen}a number from 0 to 9\${Color_Off} files at a time (\$PROG pause = 0)
\${BGreen}   m \${Color_Off}│ download \${BGreen}m\${Color_Off}any files at a time\n     │")"
	
	[ -z "$daemon_pid" ] && [ -z "$that_pid" ] &&
	    echo -e "$(eval_gettext "\${BGreen}   d \${Color_Off}│ start \${BGreen}d\${Color_Off}aemon")"

	echo -e "$(eval_gettext "\${BGreen}   c \${Color_Off}│ \${BGreen}c\${Color_Off}lean temporary files of completed downloads
     │
\${BRed}   K \${Color_Off}│ stop all downloads and every instance of ZDL in the directory (\${BRed}K\${Color_Off}ill-all)")"

	( [ -n "$daemon_pid" ] || [ -n "$instance_pid" ] ) &&
	    echo -e "$(eval_gettext "\${BRed}   Q \${Color_Off}│ stop an active instance of \$PROG in \$PWD but not the downloads already started")"

	echo -e "$(eval_gettext "     │\n\${BBlue}   q \${Color_Off}│ \${BBlue}q\${Color_Off}uit from \$PROG --interactive ")"
	echo -e "$(eval_gettext "\${BBlue}   * \${Color_Off}│ \${BBlue}update status\${Color_Off} (automatic every 15 seconds)\n     │")"

	read -s -n 1 -t 15 action

	case "$action" in
	    s)
		fclear
		header_z
		echo
		show_downloads_extended
		header_box_interactive "$(gettext "Select (Restart/stop, Eliminate, Play audio/video)")"

		print_c 2 "$(gettext "Select download numbers, separated by spaces (you can not select):")"

		input_text inputs array
		
		if [ -n "${inputs[*]}" ]
		then
		    echo
		    header_box_interactive "$(gettext "Proceed")"
		    print_c 2 "$(gettext "What do you want to do with the selected downloads?")"
		    
		    echo -e "$(eval_gettext "\${BYellow} r \${Color_Off}│ \${BYellow}r\${Color_Off}estart, if an instance of ZDL is active (if --multi >0), otherwise suspend them
\${BRed} E \${Color_Off}│ definitively \${BRed}e\${Color_Off}liminate them (and delete the downloaded file)
   │
\${BGreen} p \${Color_Off}│ (\${BGreen}p\${Color_Off}lay) the audio/video files
   │
\${BBlue} * \${Color_Off}│ \${BBlue}main screen\${Color_Off}\n")"

		    print_c 2 "$(gettext "Select what to do: ( r | E | p | * ):")"

		    input_text input
		    
		    for ((i=0; i<${#inputs[*]}; i++))
		    do
			[[ ! "${inputs[$i]}" =~ ^[0-9]+$ ]] && unset inputs[i]
		    done

		    case "$input" in
			r)   
			    for i in ${inputs[*]}
			    do
				kill_url "${url_out[$i]}" 'xfer-pids'
				kill_url "${url_out[$i]}" 'irc-pids'

				kill -9 ${pid_out[$i]} &>/dev/null
				if [ ! -f "${file_out[$i]}.st" ] &&
				       [ ! -f "${file_out[$i]}.aria2" ] &&
				       [ ! -f "${file_out[$i]}.zdl" ] &&
				       [ "${percent_out[i]}" != 100 ]
				then
				    rm -f "${file_out[$i]}" 
				fi
			    done
			    ;;

			E)
			    for i in ${inputs[*]}
			    do
				set_link - "${url_out[$i]}"
				kill_url "${url_out[$i]}" 'xfer-pids'
				kill_url "${url_out[$i]}" 'irc-pids'
				
				kill -9 ${pid_out[$i]} &>/dev/null
				rm -f "${file_out[$i]}" \
				   "${file_out[$i]}.st" \
				   "${file_out[$i]}.zdl" \
				   "${file_out[$i]}.aria2" \
				   "$path_tmp"/"${file_out[$i]}_stdout.tmp" \
				   "$path_tmp"/"${file_out[$i]}.MEGAenc_stdout.tmp"

			    done
			    ;;

			p)
			    if [ -n "$player" ] #&>/dev/null
			    then
				for i in ${inputs[*]}
				do
				    playing_files+=( "${file_out[$i]}" )
				done

				nohup $player "${playing_files[@]}" &>/dev/null &
				unset playing_files

			    else
				configure_key 9
				get_conf
			    fi
			    ;;
		    esac
		fi
		;;
	    
	    [0-9])
		echo "$action" > "$path_tmp/max-dl"
		#unlock_fifo max-downloads "$PWD" &
		init_client 2>/dev/null
		;;
	
	    m)
		echo > "$path_tmp/max-dl"
		;;
	    
	    e)
		$editor "$path_tmp/links_loop.txt"
		clean_file "$path_tmp/links_loop.txt"
		;;
	    
	    c)
		no_complete=true
		data_stdout
		unset no_complete
		;;
	    
	    q)
		fclear
		break
		;;
	    
	    a)
		set_downloader "Axel" 
		;;
	    
	    A)
		set_downloader "Aria2" 
		;;
	    
	    w)
		set_downloader "Wget" 
		;;
	    
	    Q)
		[ -n "$daemon_pid" ] && {
		    kill "$daemon_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    unset daemon_pid
		}

		[ -n "$instance_pid" ] && {
		    kill -9 "$instance_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    unset instance_pid
		}

		;;
	    
	    K)
		kill_downloads
		#kill_server
		[ -n "$instance_pid" ] && {
		    kill -9 "$instance_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    wait "$instance_pid"
		    unset instance_pid
		} 
		;;
	    
	    d)
		[ -z "$daemon_pid" ] && [ -z "$that_pid" ] && {
		    zdl --daemon &>/dev/null
		    start_mode_in_tty "$this_mode" "$this_tty"
		}
		;;
	esac

	unset action input
    done
    
    die
}

function die {
    stty echo
    fclear
    exit
}

function sleeping {
    timer=$1
    ## l'interazione è stata sostituita con 'bind' e i processi sono in background: lo schermo non è più influenzato dalla tastiera
    #
    # if [ -z "$zdl_mode" ] && [ -z "$pipe" ]; then
    # 	read -es -t $timer -n 1 
    # else
	sleep $timer
    # fi
}

function input_text {
    declare -n ref="$1"
    local sttyset
    
    cursor on
    sttyset=$(stty -a|tail -n4)
    stty sane

    if [ "$2" == array ]
    then	
	ref=( $(rlwrap -o cat) )

    else
	ref=$(rlwrap -o cat)
    fi
    
    stty $sttyset
    cursor off
}

function input_xdcc {
    declare -A out_msg=(
	[host]="$(gettext "Address of the irc host (the 'irc://' protocol is not necessary):")" 
	[chan]="$(gettext "Channel (the hash '#' is not necessary):")"
	[msg]="$(gettext "Private message (the '/msg' command is not necessary):")" 
    )
    
    header_box "$(gettext "Acquisition of missing data for XDCC (enter 'quit' to cancel)")" 
    for index in host chan msg
    do
	while [ -z "${irc[$index]}" ]
	do
	    print_c 2 "${out_msg[$index]}"

	    cursor on
	    read -e irc[$index]
	    cursor off
	    
	    irc[$index]=$(head -n1 <<< "${irc[$index]}")
	    echo 
	    
	    if [ "$index" == host ]
	    then
		test_chan="${irc[$index]#'irc://'}"
		if [[ "${test_chan}" =~ ^.+\/([^/]+) ]] &&
		       [ -z "${irc[chan]}" ]
		then
		    irc[chan]=${BASH_REMATCH[1]}
		fi
	    fi
	    
	    if [ "${irc[$index]}" == quit ]
	    then
		unset irc
		return 1
	    fi
	done
    done
    return 0
}

function input_time {
    local val var max
    unset h m s
    
    for var in h m s
    do
	while [[ ! "$val" =~ ^([0-9]+)$ ]]
	do
	    case $var in
		h) print_c 2 "$(gettext "Hours:")";;
		m) print_c 2 "$(gettext "Minutes:")";;
		s) print_c 2 "$(gettext "Seconds:")";;
	    esac

	    read -e $var
	    eval val="\$$var"

	    if [[ "$val" =~ ^([0]+)$ ]]
	    then
		val=0

	    elif [[ "$val" =~ [1-9]+ ]]
	    then
		val=${val##0}
	    fi

	    case $var in
		h) max=23 ;;
		m|s) max=59 ;;
	    esac

	    if [[ ! "$val" =~ ^([0-9]+)$ ]] || ((val > max))
	    then
		print_c 3 "$(gettext "Enter an integer in the range from 0 to %d (inclusive)")\n" "$max"
		unset val
	    else
		val=$(printf "%.2d" "$val" 2>/dev/null)
		[[ ! "$val" =~ ^([0-9]{2})$ ]] && unset val || echo
	    fi
	done
	eval $var=$val
	unset val
    done
}

function display_set_livestream {
    local link="$1" \
	  i h m s opt \
	  start_time 

    if [ "$post_readline" == true ] &&
     	   [ "$from_editor" != true ]
    then
     	stty -echo
	unset post_readline
	
    else
    	cursor on
    fi
    
    if ! url "$link"
    then
	print_c 4 "$(gettext "Available channels (choose the corresponding number):")" 
	for ((i=0; i<${#live_streaming_chan[@]}; i++))
	do
	    printf "${BYellow}%3d  ${BCyan}%-20s ${Color_Off}%s\n" $i "${live_streaming_chan[i]}" "${live_streaming_url[i]}"
	done

	while [[ ! "$opt" =~ ^([0-9]+)$ ]] ||
		  ((opt > (i -1 )))
	do
	    print_c 2 "\n$(gettext "Select the channel from which to download the live") (0-$[i-1]):" 
	    read -e opt
	done
	    
	tag_link "${live_streaming_url[opt]}" link

	if check_livestream_link_time "$link"
	then
	    print_c 3 "$(gettext "A schedule already exists for this channel:")"
	    print_c 0 "$(gettext "you can delete the previous one and create a new one or leave the previous one and cancel this operation.\n")"
	    print_c 2 "$(gettext "Do you want to create a new schedule, deleting the previous one? [yes|*]")"
	    read -e opt
	    
	    if [ "$opt" == "$(gettext "yes")" ]
	    then
		remove_livestream_link_start "$link"
		
		if data_stdout
		then
		    for ((i=0; i<${#pid_out[@]}; i++))
		    do
			if [ "$link" == "${url_out[i]}" ] &&
			       check_pid "${pid_out[i]}"
			then
			    kill -9 "${pid_out[i]}"
			fi
			
			if [ "$link" == "${url_out[i]}" ] &&
			       [ -f "${file_out[i]}" ]
			then
			    rm -f "${file_out[i]}" "$path_tmp"/"${file_out[i]}"_stdout.*
			fi
		    done	
		fi
	    else
		print_c 1 "$(gettext "Operation canceled: previous programming is maintained")"
		return 1
	    fi
	fi
	
	unset opt i live_streaming
    fi
    
    header_box "$(gettext "Live stream: program for downloading the live")"
    print_c 4 "Link: $link"
    print_c 0 "$(gettext "It is necessary to indicate the recording start time and its duration")\n"

    print_c 4 "$(gettext "Recording start time:")"
    print_c 2 "$(gettext "Do you want to register right away? [yes|*]")"
    read -e opt

    if [ "$opt" == "$(gettext "yes")" ]
    then
	h=$(date +%H)
	m=$(date +%M)
	s=$(date +%S)
	start_time_now="$h $m $s"
	echo
    else
	start_time_now=$(date +%H\ %M\ %S)
	input_time
    fi
    start_time="$h:$m:$s"
    
    print_c 4 "$(gettext "Recording duration:")" 
    input_time
    duration_time="$h:$m:$s"

    local now_in_sec=$(human_to_seconds $start_time_now)       
    local start_time_in_sec=$(human_to_seconds ${start_time//\:/ })

    if ((start_time_in_sec<now_in_sec))
    then
	print_c 2 "$(gettext "The starting time is lower than the current one: is it tomorrow? [*|no]")"
	read -e opt

	[ "$opt" == no ] ||
	    start_time+=':tomorrow'
    fi

    set_link + "$link"
    set_livestream_time "$link" "$start_time" "$duration_time"
    run_livestream_timer "$link" "$start_time"

    print_c 1 "\n$(gettext "The download from %s will start around %s for the duration of %s")\n" \
	    "$link" "$start_time" "$duration_time"
    cursor off
}

function display_livestreams {
    local line
    if [ -s "$path_tmp"/livestream_time.txt ]
    then
	print_c 4 "$(gettext "Scheduled Live Streams (link, start time, duration):")"
	while read line
	do
	    print_c 4 "$line"
	done < "$path_tmp"/livestream_time.txt
	print_c 0 ""
    fi
}
