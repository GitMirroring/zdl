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

function check_pid {
    local ck_pid=$1
    if [[ "$ck_pid" =~ ^[0-9]+$ ]] &&
	   ps ax | grep -P '^[^0-9]*'$ck_pid'[^0-9]+' &>/dev/null
    then
	return 0 
    fi
    return 1
}

function get_pid_regex {
    awk "BEGINFILE{if (ERRNO != \"\") nextfile} /$1/{match(FILENAME, /[0-9]+/, matched); print matched[0]}" /proc/*/cmdline
}

function check_instance_daemon {
    unset daemon_pid

    ## ritardare il controllo
    local date_daemon
    test -f "$path_tmp"/.date_daemon &&
	read date_daemon < "$path_tmp"/.date_daemon

    while (( $(date +%s) < (date_daemon + 2) ))
    do
	echo -ne "$(sprint_c 2 "$(gettext "Starting daemon mode")...")\r" #Avvio modalità demone
	sleep 0.1
    done

    ## controllo
    [ -d /cygdrive ] &&
	cyg_condition='&& ($2 == 1)'

    daemon_pid=$(ps ax | awk -f "$path_usr/libs/common.awk" \
			     -e "BEGIN{pwd=\"$PWD\"} /bash/ $cyg_condition {check_instance_daemon()}")

    if [[ "$daemon_pid" =~ ^([0-9]+)$ ]]
    then
	return 0
    else
	unset daemon_pid
	return 1
    fi
}

function check_instance_prog {
    local test_pid test_cmdline

    if [ -f "$path_tmp/.pid.zdl" ]
    then
	read test_pid < "$path_tmp/.pid.zdl"

	if test -f /proc/"$test_pid"/cmdline
	then
	    read test_cmdline < /proc/"$test_pid"/cmdline
	    
	    if [[ "$test_cmdline" =~ \/bin\/zdl ]] &&
		   check_pid "$test_pid" && [ "$pid_prog" != "$test_pid" ]
	    then
		that_pid=$test_pid
		tty_pid "$test_pid" that_tty
		return 0
	    fi
	fi
    fi

    return 1
}

function check_port {
    ## return 0 se la porta è libera (ancora chiusa)
    local port=$1
    
    if command -v nmap &>/dev/null
    then
    	nmap -p $port localhost |grep closed -q &&
    	    return 0

    elif command -v nc &>/dev/null
    then
    	nc -z localhost $port ||
    	    return 0

    elif command -v netstat &>/dev/null
    then
    	result=$(netstat -nlp 2>&1 |
    		     awk "/tcp/{if (\$4 ~ /:$port\$/) print \$4}")

    	[ -z "$result" ] && return 0

    else
	$nodejs "$path_usr/libs/nmap.js" $port &&
	    return 0
    fi
    
    return 1
}

function run_web_client {
    local port=8080

    while ! check_port $port
    do
	if grep -P "^$port$" "$path_server"/socket-ports &>/dev/null
	then
	    no_socket=true
	    break

	else
	    ((port++))
	fi
	sleep 0.1
    done

    if [ -z "$no_socket" ]
    then
	zdl "$@" --socket=$port -d &&
	    print_c 1 "$(gettext "New socket started at port") $port"
	#"Avviato nuovo socket alla porta $port"

    else
	zdl "$@" -d
    fi
    
    [ ! -d /cygdrive ] &&
	run_browser http://127.0.0.1 $port
}

function run_browser {
    local uri="$1"
    local port="$2"
    local default_port="80"    
    local default_url="http://127.0.0.1"


    if [[ ! "$port" =~ ^([0-9]+)$ ]]
    then
	port="$default_port"
    fi
    if [ -n "$uri" ]
    then
	uri="${default_url}:$port"
    fi
	
    while check_port $port
    do
	sleep 0.1
    done
    x_www_browser "$uri" &
}

function x_www_browser {
    if [ -z "$browser" ] ||
	   ! command -v "$browser" &>/dev/null
    then
	if command -v x-www-browser &>/dev/null
	then
	    browser=x-www-browser

	else
	    print_c 3 "$(gettext "No default web browser has been set. Start a web browser at:") $@"
	    return 1	
	fi
    fi
    $browser "$@" &>/dev/null &&
	return 0 ||
	    return 1
}

###### funzioni usate solo dagli script esterni per rigenerare la documentazione (zdl non le usa):
##

function rm_deadlinks {
    local dir="$1"
    if [ -n "$dir" ]
    then
	sudo find -L "$dir" -type l -exec rm -v {} + 2>/dev/null
    fi
}

function zdl-ext {
    ## $1 == (download|streaming|...)
    #rm_deadlinks "$path_usr/extensions/$line"
    local path_git="$HOME"/zdl-git/code
    
    while read line
    do
	test_ext_type=$(grep "## zdl-extension types:" < $path_git/extensions/$line 2>/dev/null |
			       grep "$1")
	
	if [ -n "$test_ext_type" ]
	then
	    grep '## zdl-extension name:' < "$path_git/extensions/$line" 2>/dev/null |
		sed -r 's|.*(## zdl-extension name: )(.+)|\2|g' |
		sed -r 's|\, |\n|g'
	fi
    done <<< "$(ls -1 $path_git/extensions/)"
}

function zdl-ext-sorted {
    local extensions
    while read line
    do
	extensions="${extensions}$line\n"
    done <<< "$(zdl-ext $1)"
    extensions=${extensions%\\n}

    echo $(sed -r 's|$|, |g' <<< "$(echo -e "${extensions}" |sort)") |
	sed -r 's|(.+)\,$|\1|g'
}
##
####################


function set_line_in_file { 	#### usage: 
    local op="$1"                     ## operator (+|-|in)
    local item="$2"                   ## string
    local file_target="$3"            ## file target
    local rewriting="$3-rewriting"    #### <- to linearize parallel rewriting file target
    local result

    if [ "$op" != "in" ]
    then
	if [ -f "$rewriting" ]
	then
	    while [ -f "$rewriting" ]
	    do
		sleep 0.1
	    done
	fi
	touch "$rewriting"
    fi

    if [ -n "$item" ]
    then
	case $op in
	    +)
		if ! set_line_in_file "in" "$item" "$file_target"
		then
		    echo "$item" >> "$file_target"

		    if grep -q "${XDCC_EU_SEARCHKEY_URL}" <<< "$item"
		    then
			display_xdcc_eu_gui "${item##*=}"
		    fi
		    result=0

		else
		    result=1
		fi
		rm -f "$rewriting"
		;;
	    -)
		if [ -f "$file_target" ]
		then
		    item="${item//'*'/\\*}"
		    item="${item//','/\\,}"
		    
		    sed -e "s,^${item}$,,g" \
			-e '/^$/d' -i "$file_target" 2>/dev/null
		    
		    if (( $(wc -l < "$file_target") == 0 ))
		    then
			rm "$file_target"
		    fi
		    result=0
		    
		else
		    result=1
		fi
		rm -f "$rewriting"
		;;
	    'in') 
		if [ -s "$file_target" ] &&
		       grep "^${item}$" "$file_target" &>/dev/null
		then 
		    result=0
		else
		    result=1
		fi
		;;
	esac
    else
	result=1
    fi
    return $result
}


function set_link {
    local op="$1"
    local link="$2"
    local i
    
    if [ "$op" == "+" ] &&
	   ! url "$link"
    then
	_log 12 "$link"
	return 1

    else
	if [ "$op" == "+" ]
	then
	    link="${link%'#20\x'}"
	    #clean_livestream 
	    #check_linksloop_livestream 
	    check_livestream_twice "$link"
	fi
	
	if set_line_in_file "$op" "$link" "$path_tmp/links_loop.txt"
	then
	    if [ "$op" == '-' ]
	    then
		if check_livestream "$link"
		then
		    remove_livestream_link_start "$link"
		    remove_livestream_link_time "$link"
		fi
		
		data_stdout &&
		    for ((i=0; i<${#file_out[@]}; i++))
		    do
			if [ "${url_out[i]}" == "$link" ]
			then
			    check_pid "${pid_out[i]}" && kill -9 "${pid_out[i]}" &>/dev/null
			    rm -rf "${file_out[i]}" \
			       "${file_out[i]}".st \
			       "${file_out[i]}".aria2 \
			   "${file_out[i]}".MEGAenc \
			   "$path_tmp"/"${file_out[i]}"_stdout.*
			    break
			fi
		    done
	    fi
	    return 0
	else
	    return 1
	fi
    fi
}

function check_link {
    local link="$1"
    local i ret=0
    local max_dl
    test -f "$path_tmp/max-dl" &&
	read max_dl < "$path_tmp/max-dl"
    
    if [ -z "$max_dl" ] &&
	   check_livestream_link_time "$link" &&
	   ! check_livestream_link_start "$link"
    then
	return 1
    fi

    if url "$link" &&
	   set_link in "$link"
    then
	if data_stdout
	then
	    if ( [ -n "$max_dl" ] && (( "${#pid_alive[*]}" >= "$max_dl" )) ) ||
		   ( check_livestream "$link" && ! check_livestream_link_start "$link" )
	    then
		ret=1
	    fi

	    for ((i=0; i<${#pid_out[@]}; i++))
	    do
		check_livestream_twice "$link"
		
		if ( [ "$link" == "${url_out[i]}" ] && check_pid "${pid_out[i]}" )		       
		then
		    ret=1
		fi
	    done	
	fi
	
    else
	ret=1
    fi

    check_livestream_link_time "$link" &&
	! check_livestream_link_start "$link" &&
	ret=1

    return $ret
}

function check_in_loop {
    local line i j max_dl ret=1
    test -f "$path_tmp/max-dl" &&
	read max_dl < "$path_tmp/max-dl"

    if data_stdout
    then
	for ((i=0; i<${#url_out[i]}; i++))
	do	    
	    check_livestream_link_start "${url_out[i]}" &&
		! check_pid "${pid_out[i]}" &&
		ret=1

	    if ! set_link in "${url_out[i]}" &&
		    [[ "${percent_out[i]}" =~ ^([0-9.]+)$ ]] &&
		    ((${percent_out[i]}<100))
	    then
		check_pid "${pid_out[i]}" && kill -9 "${pid_out[i]}" &>/dev/null
		rm -rf "${file_out[i]}" \
		   "${file_out[i]}".st \
		   "${file_out[i]}".aria2 \
		   "${file_out[i]}".MEGAenc \
		   "$path_tmp"/"${file_out[i]}"_stdout.*
	    fi

	    if ! check_livestream "${url_out[i]}" &&
		    ! check_pid "${pid_out[i]}"
	    then
		for ((j=0; j<${#url_out[@]}; j++))
		do
		    if check_pid "${pid_out[j]}" &&
			    [ "${url_out[j]}" == "${url_out[i]}" ]
		    then
			rm -rf "${file_out[i]}" \
			   "${file_out[i]}".st \
			   "${file_out[i]}".aria2 \
			   "${file_out[i]}".MEGAenc \
			   "$path_tmp"/"${file_out[i]}"_stdout.*
		    fi			
		done
	    fi
	done

	if [ -z "$max_dl" ] ||
	       (( "${#pid_alive[*]}" < "$max_dl" )) ||
	       [ -s "$path_tmp"/livestream_start.txt ]
	then	    	    
	    ret=1 ## rompe il loop (esce dall'attesa) => procede con un altro download
	else
	    ret=0 ## rimane nel loop (in attesa)
	fi
    fi
    return $ret
}

function check_in_file { 	## return --> no_download=1 / download=0
    sanitize_file_in
    url_in_bis="${url_in::100}"
    file_in_bis="${file_in}__BIS__${url_in_bis//\//_}.${file_in##*.}"
    if [ -n "$exceeded" ]
    then
	_log 4
	break_loop=true
	no_newip=true
	unset exceeded
	return 1

    elif [ -n "$not_available" ]
    then
	[ -n "$url_in_file" ] && _log 3
	no_newip=true
	unset not_available
	return 1

    elif [ "$url_in_file" != "${url_in_file//{\"err\"/}" ]
    then
	_log 2
	unset no_newip
	return 1

    elif [ -z "$url_in_file" ] ||                               
	( [ -z "$file_in" ] && [[ "$downloader_in" =~ (Aria2|Axel|Wget) ]] )
    then
	_log 2
	unset no_newip
    fi

    if [ -n "$file_in" ]
    then
	length_saved_in=0
		    
	no_newip=true
	if data_stdout
	then
	    if [ -z "$file_in" ]
	    then
		return 1
	    fi
	fi

	if [ -f "$file_in" ]
	then
	    ## `--bis` abilitato di default
	    [ "$resume" != "enabled" ] && bis=true
	    if [ "$bis" == true ]
	    then
		homonymy_treating=( resume_dl rewrite_dl bis_dl )
	    else
		homonymy_treating=( resume_dl rewrite_dl )
	    fi
	    
	    for i in ${homonymy_treating[*]}
	    do
		if [ "$downloader_in" == "Wget" ]
		then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    if [ -n "$length_in" ] &&                     
				   (( $length_in > $length_saved_in )) &&      
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then
				rm -f "$file_in" "${file_in}.st" "${file_in}.aria2" #"${file_in}.zdl"  
	 			unset no_newip
	 			[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac

		elif [ "$downloader_in" == "RTMPDump" ]
		then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    [ -f "$path_tmp/${file_in}_stdout.tmp" ] &&                                       
				test_completed=$(grep 'Download complete' < "$path_tmp/${file_in}_stdout.tmp")

			    if [ -f "${file_in}" ] &&                        
				   [ -z "$test_completed" ] &&                  
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then 
				unset no_newip
				[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac

		elif [ "$downloader_in" == "FFMpeg" ]
		then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    [ -f "$path_tmp/${file_in}_stdout.tmp" ] &&                                       
				test_completed=$(grep 'muxing' < "$path_tmp/${file_in}_stdout.tmp")

			    if [ -f "${file_in}" ] &&                        
				   [ -z "$test_completed" ] &&                  
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then 
				unset no_newip
				[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac

		elif [[ "$downloader_in" =~ (Aria2|Axel) ]]
		then
		    [ "$downloader_in" == Axel ] && rm -f "${file_in}" "${file_in}.aria2"
		    [ "$downloader_in" == Aria2 ] && rm -f "${file_in}.st"
		    
		    case "$i" in
			resume_dl) 
			    if ( [ -f "${file_in}.st" ] || [ -f "${file_in}.aria2" ] ) &&
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then                     
				unset no_newip
				[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
			rewrite_dl)
			    if ( [ -z "$bis" ] || [ "$no_bis" == true ] ) &&
				   [ -n "$length_in" ] && (( $length_in > $length_saved_in ))
			    then
				rm -f "$file_in" "${file_in}.st" "${file_in}.aria2" 
	 			unset no_newip
	 			[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac
		fi
		## case bis_dl
	        if [ "$i" == bis_dl ] && [ -z "$no_bis" ]
		then
		    file_in="$file_in_bis"

		    if [ ! -f "$file_in_bis" ]
		    then
			return 0

		    elif [ -f "$file_in_bis" ] ||
			     ( [ "${downloader_out[$i]}" == "RTMPDump" ] &&
				   [ -n "$test_completed" ] )
		    then
			set_link - "$url_in"

		    fi
		fi
	    done
	    
	    ## ignore link
	    if [[ "$length_saved_in" =~ ^[0-9]+$ ]] && (( "$length_saved_in" > 0 ))
	    then
		_log 1

	    elif [[ "$length_saved_in" =~ ^[0-9]+$ ]] && (( "$length_saved_in" == 0 ))
	    then
		rm -f "$file_in" "$file_in".st 

	    fi
	    break_loop=true
	    no_newip=true

	elif [ -n "$url_in_file" ] ||
		 ( [ -n "$playpath" ] && [ -n "$streamer" ] )
	then
	    return 0

	fi

    elif [ "$downloader_in" == DCC_Xfer ]
    then
	return 0
    fi

    return 1
}



function clean_file { ## URL, nello stesso ordine, senza righe vuote o ripetizioni
    if [ -f "$1" ]
    then
	local file_to_clean="$1"

	## impedire scrittura non-lineare da più istanze di ZDL
	if [ -f "${file_to_clean}-rewriting" ]
	then
	    while [ -f "${file_to_clean}-rewriting" ]
	    do
		sleeping 0.1
	    done
	fi
	touch "${file_to_clean}-rewriting"

	local lines=$(
	    awk '!($0 in a){a[$0]; gsub(" ","%20"); print}' < "$file_to_clean" 
	)

	if [ -n "$lines" ]
	then
	    grep_urls "$lines" > "$file_to_clean"
	else
	    rm -f "$file_to_clean"
	fi

	rm -f "${file_to_clean}-rewriting"
    fi
}

function check_start_file {
    if [ -f "${start_file}-rewriting" ] ||
	   [ -f "${start_file}" ]
    then
	return 0

    else
	return 1
    fi
    
}

function pipe_files {
    local line format print_out

    test -f "$path_tmp"/format-post_processor &&
	read format < "$path_tmp"/format-post_processor
    
    test -f "$path_tmp"/print_out-post_processor &&
	read print_out < "$path_tmp"/print_out-post_processor

    [ -z "$print_out" ] && [ -z "${pipe_out[*]}" ] && return

    if [ -f "$path_tmp"/pipe_files.txt ]
    then
	if [ -f "$path_tmp"/pid_pipe ]
	then
	    read pid_pipe_out < "$path_tmp"/pid_pipe
	else
	    pid_pipe_out=NULL
	fi
	
	if [ -n "$print_out" ] && [ -f "$path_tmp"/pipe_files.txt ]
	then
	    while read line
	    do
		if ! grep -P '^$line$' $print_out &>/dev/null
		then
		    echo "$line" >> "$print_out"
		fi
		
	    done < "$path_tmp"/pipe_files.txt 
	    
	elif [ -z "${pipe_out[*]}" ] || check_pid $pid_pipe_out 
	then
	    return

	else
	    outfiles=( $(< "$path_tmp"/pipe_files.txt) )

	    if [ -n "${outfiles[*]}" ]
	    then
		nohup "${pipe_out[@]}" "${outfiles[@]}" 2>/dev/null &
		pid_pipe_out="$!"
		echo $pid_pipe_out > "$path_tmp"/pid_pipe
		pipe_done=1
	    fi
	fi
    fi
}

function pid_list_for_prog {
    cmd="$1"
    
    if [ -n "$cmd" ]
    then
	if [ -e /cygdrive ]
	then
	    ps ax | grep $cmd | awk '{print $1}'
	else
	    _text="$(ps -aj $pid_prog | grep -P "[0-9]+ $cmd")"
	    cut -d ' ' -f1 <<<  "${_text## }"
	fi
    fi
}

## note:
#
# function children_pids {
#     local children
#     children=$(ps -o pid --no-headers --ppid $$1)
#
#     if [ -n "$children" ]
#     then
# 	printf "%s" "$children"
# 	return 0
#
#     else
# 	return 1
#     fi
# }

function children_pids {
    local result ppid 
    ppid=$1
    proc_pids=(
	$(ls -1 /proc |grep -oP '^[0-9]+$')
    )

    result=1
    
    for proc_pid in ${proc_pids[@]}
    do
	if [ -e /proc/$proc_pid/status ] &&
	       [ "$(awk '/PPid/{print $2}' /proc/$proc_pid/status)" == "${ppid}" ]
	then
	    echo $proc_pid
	    result=0
	fi
    done
    return $result
}


function set_downloader {
    if command -v ${_downloader[$1]} &>/dev/null
    then
	downloader_in=$1
	echo $downloader_in > "$path_tmp/downloader"
	#unlock_fifo downloader "$PWD" &
	init_client &>/dev/null
	
    else
	return 1
    fi
}


function tty_pid {
    local that_tty pid
    pid="$1"
    
    if [ -e "/cygdrive" ]
    then
	test -f /proc/$pid/ctty
	read that_tty < /proc/$pid/ctty
    else
	that_tty=$(ps ax |grep -P '^[\ ]*'$pid)
	that_tty="${that_tty## }"
	that_tty="/dev/"$(cut -d ' ' -f 2 <<< "${that_tty## }")
    fi

    if [ -n "$2" ]
    then
	declare -n ref="$2"
	ref="$that_tty"

    else
	echo "$that_tty"
    fi
}

function grep_tty {
    ## regex -> tty

    local matched_tty

    ## gnu/linux
    if [ -z "$2" ]
    then
	matched_tty=$(ps ax | grep -v grep | grep -P "$1")

    else
	matched_tty=$(grep -P "$1" <<< "$2")
    fi
    matched_tty="${matched_tty## }"
    matched_tty=$(cut -d ' ' -f 2 <<< "${matched_tty## }")

    if [ -n "$matched_tty" ]
    then
	echo "/dev/$matched_tty"
	return 0

    else
	return 1
    fi
}

function grep_pid {
    ## regex -> pid
    local matched_pid

    ## gnu/linux
    if [ -z "$2" ]
    then
	matched_pid=$(ps ax | grep -v grep | grep -P "$1")

    else
	matched_pid=$(grep -P "$1" <<< "$2")
    fi

    matched_pid="${matched_pid## }"
    matched_pid="/dev/"$(cut -d ' ' -f 2 <<< "${matched_pid## }")

    if [[ "$matched_pid" =~ ^([0-9]+)$ ]]
    then
	echo "$matched_pid"
	return 0

    else
	return 1
    fi
}


function start_mode_in_tty {
    local this_mode this_tty
    this_mode="$1"
    this_tty="$2"

    if [ "$this_mode" != daemon ]
    then
	if [ -f "$path_tmp/.stop_stdout" ] &&
	       check_instance_prog
	then
	    that_tty=$(cut -d' ' -f1 "$path_tmp/.stop_stdout")

	else
	    that_tty="$this_tty"
	fi
	    
	if [ "$this_tty" == "$that_tty" ]
	then
	    echo "$that_tty $this_mode" >"$path_tmp/.stop_stdout"
	fi
    fi
}


## check: può stampare in stdout? (params: 1-modalità e 2-terminale)
function show_mode_in_tty {
    ## livelli: priorità di stampa in ordine crescente
    ## per sistema "on the fly" valido solo su gnu/linux
    ##
    # declare -A _mode
    # _mode['daemon']=0
    # _mode['stdout']=1
    # _mode['lite']=2
    # _mode['interactive']=3
    # _mode['configure']=4
    # _mode['list']=5
    # _mode['info']=6
    # _mode['editor']=7

    local this_mode this_tty B1 B2 pattern psax
    this_mode="$1"
    this_tty="$2"

    if  [ -f "$path_tmp/.stop_stdout" ]
    then
	that_tty=$(cut -d' ' -f1 "$path_tmp/.stop_stdout")
	that_mode=$(cut -d' ' -f2 "$path_tmp/.stop_stdout")
    fi

    [ "$this_tty" != "$that_tty" ] &&
	return 0
       

    if [ "$this_mode" == "daemon" ]
    then
	return 1

    elif [ -f "$path_tmp/.stop_stdout" ] &&
	     [ "$this_tty $this_mode" != "$that_tty $that_mode" ]
    then
	return 1

	###########################################
	## sistema "on the fly" valido solo su gnu/linux (a causa dell'output di `ps ax`, incompleto su cygwin
	##
	# else
	# 	level="${_mode[$this_mode]}"
	# 	pattern="${this_tty##'/dev/'}"
	# 	pattern="${pattern//\//\\/}\s+[^ ]+\s+[^ ]+\s+(?!grep).+"
	# 	B1='('
	
	# 	((level<2)) && {
	# 	    pattern+="${B1}zdl\s(-l|--lite)|" 
	# 	    unset B1
	# 	}
	# 	((level<3)) && {
	# 	    pattern+="${B1}zdl\s--interactive|"
	# 	    unset B1
	# 	}
	# 	((level<4)) && {
	# 	    pattern+="${B1}zdl\s--configure|"
	# 	    unset B1
	# 	}
	# 	((level<5)) && {
	# 	    pattern+="${B1}zdl\s--list-extensions|" 
	# 	    unset B1
	# 	}
	# 	((level<6)) && {
	# 	    pattern+="${B1}p*info.+zdl|" 
	# 	    unset B1
	# 	}
	# 	((level<7)) && {
	# 	    pattern+="${B1}\/links_loop\.txt|" 
	# 	    unset B1
	# 	}

	# 	[ -z "$B1" ] &&
	# 	    B2=')'
	
	# 	pattern=${pattern%'|'}"$B2"

	# 	ps ax | grep -P "$pattern" &>/dev/null &&
	# 	    return 1
    fi
    return 0
}

function zero_dl {
    [ "$1" == show ] &&
	unset hide_zero
    
    test -f "$path_tmp"/max-dl &&
	read max_dl < "$path_tmp"/max-dl

    if [ -n "$max_dl" ] && ((max_dl < 1))
    then
	if [ -z "$hide_zero" ]
	then
	    print_c 3 "$(gettext "%s paused")" "$PROG" #"$PROG in pausa"
	    print_c 4 "$(gettext "To process new links, download a number of files greater than zero:")" 
	    print_c 0 "$(gettext "use the [-m|--multi [NUMBER]] option or enter the interactive mode and type in a number from 1 to 9")"
	    #hide_zero=true
	fi
	return 0

    else
	unset hide_zero
	return 1
    fi
}

function redirect {
    url_input="$1"
    sleeping 1
    local pid wpid

    if ! url "$url_input" 
    then
	return 1
    fi
    
    k=$(date +"%s")
    s=0
    while true
    do
    	if ! check_pid "$wpid" ||
		[ "$s" == 0 ] ||
		[ "$s" == "$max_waiting" ] ||
		[ "$s" == $(( $max_waiting*2 )) ]
    	then 
    	    kill -9 "$wpid" &>/dev/null
    	    rm -f "$path_tmp/redirect"
    	    wget -t 1 -T $max_waiting                       \
    		 --user-agent="$user_agent"                 \
    		 --no-check-certificate                     \
    		 --load-cookies="$path_tmp"/cookies.zdl     \
    		 --post-data="${post_data}"                 \
    		 "$url_input"                               \
    		 -SO /dev/null -o "$path_tmp/redirect" &
    	    wpid=$!
	    echo "$wpid" >> "$path_tmp"/pid_redirects
    	fi
	
    	if [ -f "$path_tmp/redirect" ]
	then
	    url_redirect="$(grep 'Location:' "$path_tmp/redirect" 2>/dev/null |head -n1)"
	    url_redirect="${url_redirect#*'Location: '}"
	fi

	if url "$url_redirect" &&
		[ "$url_redirect" != "https://tusfiles.net" ]
    	then
	    while read pid
	    do
    		kill -9 $pid &>/dev/null
	    done < "$path_tmp"/pid_redirects
    	    break

	elif (( $s>90 ))
    	then
	    while read pid
	    do
    		kill -9 $pid &>/dev/null
	    done < "$path_tmp"/pid_redirects
    	    return

	else
    	    [ "$s" == 0 ] &&
		print_c 2 "$(gettext "Redirection (wait up to 90 seconds):")" 

	    sleeping 1
    	    s=$(date +"%s")
    	    s=$(( $s-$k ))
    	    sprint_c 0 "%s\r" $s
    	fi
    done

    url_in_file="${url_redirect}"

    rm -f "$path_tmp/redirect"
    unset url_redirect post_data
    return 0
}

function redirect_links {
    redirected_link="true"
    if [ -n "$links" ]
    then
	header_box "$(gettext "Processing Links")" 
	echo -e "${links}\n"
    fi
    
    if [ -n "$links" ] ||
	   [ -n "$post_readline" ]
    then
	[ -z "$stdbox" ] &&
	    header_dl "Downloading in $PWD"
	print_c 1 "$(gettext "Download management is forwarded to another active instance of %s (pid: %d), in the following terminal: %s\n")" \
		"$name_prog" "$that_pid" "$that_tty"
    fi

    bindings
    check_linksloop_livestream
    
    [ -n "$xterm_stop_checked" ] && xterm_stop

    cursor on
    exit
}


function kill_external {
    local pid
    
    if [ -f "$path_tmp/external-dl_pids.txt" ]
    then
	cat "$path_tmp/external-dl_pids.txt" 2>/dev/null |
	    while read pid
	    do
		[[ "$pid" =~ ^[0-9]+$ ]] &&
		    kill -9 $pid 2>/dev/null
	    done &>/dev/null &
	rm -f "$path_tmp/external-dl_pids.txt"
    fi
}

function kill_downloads {
    kill_urls    
    kill_external
    
    if data_stdout
    then
	[ -n "${pid_alive[*]}" ] && kill -9 ${pid_alive[*]} &>/dev/null
    fi
}

function kill_urls {
    local test_url
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ] &&
	   [ -f "$path_tmp/links_loop.txt" ]
    then
	cat "$path_tmp/links_loop.txt" 2>/dev/null |
	    while read test_url
	    do
		url "$test_url" &&
		    kill_url "$test_url"
	    done &>/dev/null &
    fi
}

function kill_url {
    local pid
    local url="$1"
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ]
    then
	grep -P "^[0-9]+ $url$" "$path_tmp/${type_pid}" 2>/dev/null | cut -d' ' -f1 |
	    while read pid
	    do
		if [[ "$pid" =~ ^[0-9]+$ ]]
		then
		    kill -9 $pid &>/dev/null
		    del_pid_url "$url" "$type_pid"
		fi
	    done &>/dev/null &
    fi
}

function kill_pid_urls {
    local type_pid="$1"
    [ -z "$type_pid" ] && type_pid='pid-url'
    
    if [ -f "$path_tmp/${type_pid}" ]
    then
	cat "$path_tmp/${type_pid}" | cut -d' ' -f1 |
	    while read pid
	    do
		kill -9 "$pid" &>/dev/null
	    done &>/dev/null &
    fi
}

function add_pid_url {
    local pid="$1"
    local url="$2"
    local type_pid="$3"
    [ -z "$type_pid" ] && type_pid='pid-url'
    
    echo "$pid $url" >>"$path_tmp/${type_pid}"
}

function del_pid_url {
    local url="$1"
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ]
    then
	sed -r "/^.+ ${url//\//\\/}$/d" -i "$path_tmp/${type_pid}" 2>/dev/null
    fi
}

function set_exit {
    echo "$pid_prog" >"$path_tmp"/zdl_exit
}

function get_exit {
    if [ -f "$path_tmp"/zdl_exit ]
    then
	local test_exit
	read test_exit < "$path_tmp"/zdl_exit
	[ "$pid_prog" == "$test_exit" ] &&
	    return 0 ||
		return 1
    else
	return 1
    fi
}

function reset_exit {
    rm -rf "$path_tmp"/zdl_exit
}

function check_connection {
    local i
    
    for i in {0..5}
    do
	ping -q -c 1 8.8.8.8 &>/dev/null && return 0
	sleep 1
    done
    return 1
}

function check_freespace {
    ## per spazio minore di 50 megabyte (51200 Kb), return 1
    
    test_space=( $(df .) )
    (( test_space[11] < 51200 )) &&
	return 1

    return 0
}


function kill_server {
    local port="$1"
    local matched

    [ -z "$port" ] && port="$socket_port"    
    
    # for path2pid in /proc/*/cmdline
    # do
    # 	parse_int pid "$path2pid"
    # 	if [ -n "$pid" ] &&
    # 	       grep -P "socat.+LISTEN:${port}.+zdl_server\.sh" /proc/$pid/cmdline &>/dev/null #|.+zdl_server\.sh.*${port}
    # 	then
    # 	    kill "$pid"
    # 	fi
    # done

    # check_instance_server "$port" &&
    # 	kill_server "$port" 

    if ! check_port $port
    then
	init_client 2>/dev/null & 
	#set_line_in_file - "$port" "$path_server"/socket-ports &

	fuser -s -k -n tcp $port -n file /usr/local/share/zdl/zdl_server.sh &
    fi
}

function get_server_pids {
    local port=$1

    if [ -s "$path_server"/pid_server ]
    then
	grep " $port$" "$path_server"/pid_server |
	    cut -d' ' -f1 &&
	    return 0
    fi
    return 1
}

function run_zdl_server {
    local port="$1"

    if [[ "$port" =~ ^[0-9]+$ ]] &&
	   ((port > 1024 )) && (( port < 65535 )) &&
	   check_port $port
    then
	socat TCP-LISTEN:$port,fork,reuseaddr EXEC:"$path_usr/zdl_server.sh $port" 2>/dev/null & #2>serverlog-$(date +%s).txt & 
	disown
	set_line_in_file + $port "$path_server"/socket-ports

	init_client 2>/dev/null
	return 0

    else
	return 1
    fi
}

function del_server_pid {
    local pid="$1"

    [ -f "$path_server"/pid_server ] &&
	sed -r "/^$pid .+/d" -i "$path_server"/pid_server
}

function add_server_pid {
    local port="$1"
    [ -z "$port" ] && port="$socket_port"
    local psline
    
    ps ax | while read -a psline
	    do
		if [[ "${psline[0]}" =~ ^([0-9]+)$ ]] &&
		       grep -P "socat.+LISTEN:${port}.+zdl_server\.sh" /proc/${psline[0]}/cmdline &>/dev/null
		then
		    set_line_in_file + "${psline[0]} $port" "$path_server"/pid_server 
		fi
	    done &>/dev/null
}    

function check_instance_server {
    local port="$1"
    local pid path2pid

    grep -P "socat.+LISTEN:${port}.+zdl_server\.sh" /proc/[0-9]*/cmdline &>/dev/null &&
	{
	    set_line_in_file + "$port" "$path_server"/socket-ports
	    return 0
	}
    
    return 1
}

function init_client {
    local port
    local path="$1"
    local socket_port="$2"

    [ -s "$path_server"/socket-ports ] &&
	{
	    while read port
	    do
		if [ "$socket_port" == "$port" ]
		then
		    unlock_fifo status.$port "$path" &
		    
		else
		    unlock_fifo status.$port &
		fi
		
	    done < "$path_server"/socket-ports 
	} 
}

function unlock_fifo {
    local fifo_name="$1"
    local item_value="$2"
    local fifo_path="$3"
    [ -z "$fifo_path" ] && fifo_path="$path_server"
    
    # [ ! -e "$fifo_path"/"$fifo_name".fifo ] &&
    # 	mkfifo "$fifo_path"/"$fifo_name".fifo

    [ -e "$fifo_path"/"$fifo_name".fifo ] &&
	echo "$item_value" > "$fifo_path"/"$fifo_name".fifo 
}

function lock_fifo {
    local fifo_name="$1"
    local item_name="$2"
    local fifo_path="$3"
    [ -z "$fifo_path" ] && fifo_path="$path_server"
    
    [ ! -e "$fifo_path"/"$fifo_name".fifo ] &&
	mkfifo "$fifo_path"/"$fifo_name".fifo

    eval read $item_name < "$fifo_path"/"$fifo_name".fifo
}

function create_hash {
    openssl dgst -whirlpool -hex <<< "${*}" | cut -d' ' -f2
}

function kill_ffmpeg {
    local pid
    if [ -s "$path_tmp"/ffmpeg-pids ]
    then
	while read pid
	do	    
	    kill $line &>/dev/null
	done  < "$path_tmp"/ffmpeg-pids
    fi
}

links_timer="$path_tmp/links_timer.txt"
## link ip timeout

function check_link_timer {
    local link="$1"
    local this_ip that_ip now timeout line

    [ ! -s "$links_timer" ] && return 0
    line=$(grep "$link" "$links_timer" |tail -n1)

    if [ -z "$line" ]
    then
	return 0

    else
	get_ip this_ip
	read that_ip timeout < <(awk '{print $2" "$3}' <<< "$line")
	now=$(date +%s)

	if [ "$this_ip" != "$that_ip" ] ||
	       ((now >= timeout))
	then
	    del_link_timer "$link"
	    return 0
	else
	    print_c 3 "$url_in -> $(gettext "Link paused"): $(seconds_to_human $((timeout - now)) )"
	    return 1
	fi
    fi
}

function set_link_timer {
    if ! url "$1" ||
	    [[ "$2" =~ ^[^0-9]+$ ]]
    then
	return 1
    fi
    
    local link="$1"
    local timeout=$(($(date +%s) + $2))
    local ip
    get_ip ip
    
    del_link_timer "$link"

    echo "$link $ip $timeout" >>"$links_timer"
    _log 33 "$2"
}

function del_link_timer {
    local link="$1"
    sed -r "s|^$link\s+.+||g" -i "$links_timer"
    [ ! -s "$links_timer" ] && rm -f "$links_timer"
}

function add_path4server {
    mkdir -p "$path_server"
    echo "$1" >>"$path_server"/paths.txt

    ##clean
    if [ -s "$path_server"/paths.txt ]
    then
	rm -f "$path_server"/paths.txt.new
	while read line
	do
	    [ -d "$line" ] && echo "$line" >>"$path_server"/paths.txt.new
	done < <(awk '!($0 in a){a[$0]; print}' "$path_server"/paths.txt)

	if [ -s "$path_server"/paths.txt.new ]
	then
	    mv "$path_server"/paths.txt.new "$path_server"/paths.txt

	else
	    rm -f "$path_server"/paths.txt.new
	    echo >"$path_server"/paths.txt
	fi
    fi
}
