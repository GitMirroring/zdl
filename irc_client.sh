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
path_tmp=".zdl_tmp"
gui_log="$path_tmp"/gui-log.txt

source $path_usr/libs/core.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/log.sh
source $path_usr/config.sh
source $path_usr/libs/ip_changer.sh
get_conf

[ -z "$background" ] && background=tty
source $path_usr/ui/widgets.sh

file_log="zdl_log.txt"
name_prog=ZigzagDownLoader

if [ -f "$file_log" ]
then
    log=1
fi


function start_timeout {
    local start=$(date +%s)
    local now
    local diff_now
    local max_seconds=60
    if [ -d /cygdrive ]
    then
	max_seconds=120
    fi
    
    touch "$path_tmp/irc-timeout"
    sed "/^${url//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
    
    for i in {0..18}
    do
	now=$(date +%s)
	diff_now=$(( now - start ))

	if grep -q "$url" "$path_tmp/irc-timeout"
	then
	    break

	elif (( diff_now >= $max_seconds ))
	then
            print_c 3 "irc_client timeout: ${url//'%20'/' '}"

            irc_send QUIT
            
            reset_irc_request
	    sed -r "/^.+ ${url//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
            
            for test_pid in get_pid_url "${url//\//\\/}" "irc-loop-pids"
            do
                [[ "$test_pid" =~ ^[0-9]+$ ]] && kill -9 $test_pid
            done

            del_pid_url "$url" "irc-wait"
            kill -9 $PID
	    break
	fi
	
	sleep 10
    done &
}


function irc_die {
    reset_irc_request force
    _log 26 "${xdcc['url',$xdcc_index]}"

    if [ -d /cygdrive ]
    then
	kill -9 $(children_pids $PID)
	
    else
	kill -9 $(ps -o pid --no-headers --ppid $PID)
    fi    
}


function set_mode {
    this_mode="$1"
    printf "%s %s\n" "$this_mode" "${xdcc['url',$xdcc_index]}" >>"$path_tmp/irc_this_mode"
}

function get_mode {
    this_mode=$(grep "${xdcc['url',$xdcc_index]}" "$path_tmp/irc_this_mode" | cut -d' ' -f1 | tail -n1)
    [ -z "$this_mode" ] && this_mode=stdout
}

function xdcc_cancel {
    irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "XDCC CANCEL"
}

function xdcc_send_remove {
    irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "XDCC REMOVE"
}

function irc_quit {
    local pid_list
    touch "$path_tmp"/irc_done
    rm -rf "$test_xfer"
    
    [ -f "$path_tmp/${file_xfer}_stdout.tmp" ] &&
	kill $(head -n1 "$path_tmp/${file_xfer}_stdout.tmp") 2>/dev/null

    xdcc_cancel
    exec 4>&-
    irc_send "QUIT"
    
    if [ -d /cygdrive ]
    then
    	pid_list=( $(children_pids $PID) $PID )

    else
    	pid_list=( $(ps -o pid --no-headers --ppid $PID) $PID )
    fi

    for pid in ${pid_list[@]} 
    do
	kill -9 $pid
    done &

    exit 1
}

function irc_send {
    printf "%s\r\n" "$*" >&3
}

function irc_ctcp {
    local pre=$1
    local post=$2
    
    ############ \015 -> \r ; \012 -> \n ######################
    printf "%s :\001%s\001\015\012" "$pre" "$post" >&3
}

function set_resume {
    echo "${xdcc['url',$xdcc_index]}" >>"$path_tmp"/irc_xdcc_resume
}

function get_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	grep -q "${xdcc['url',$xdcc_index]}" "$path_tmp"/irc_xdcc_resume &&
            return 0
    fi
    return 1
}

function init_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	sed "/^${url//\//\\/}$/d" -i "$path_tmp"/irc_xdcc_resume
    fi
}

function send_dcc_resume {
    if [ -f "${xdcc['file',$xdcc_index]}" ] &&
	   [ -f "${xdcc['file',$xdcc_index]}.zdl" ] &&
	   [ "$(cat "${xdcc['file',$xdcc_index]}.zdl")" == "${xdcc['url',$xdcc_index]}" ] &&
           (( xdcc['offset',$xdcc_index] > 0 )) &&
           (( xdcc['offset',$xdcc_index] < xdcc['size',$xdcc_index] )) # (( xdcc['offset',$xdcc_index] < xdcc['size',$xdcc_index] ))
    then
	irc_ctcp "PRIVMSG ${xdcc['slot',$xdcc_index]}" "DCC RESUME ${xdcc['file',$xdcc_index]} ${xdcc['port',$xdcc_index]} ${xdcc['offset',$xdcc_index]}"
	print_c 2 "CTCP>> PRIVMSG ${xdcc['slot',$xdcc_index]} :DCC RESUME ${xdcc['file',$xdcc_index]} ${xdcc['port',$xdcc_index]} ${xdcc['offset',$xdcc_index]}"
        test_resume=true
    fi
}

function add_xdcc_url {
    local url="$1" counter key
    unset xdcc_index
    get_xdcc_host_url_data

    count_xdcc counter
    
    for ((i=0; i<=$counter; i++))
    do
        if [ -z "${xdcc['url',$i]}" ]
        then
            xdcc_index=$i
            break
            
        elif [ "${xdcc['url',$i]}" == "$url" ]
        then
            if [ -z "$xdcc_index" ]
            then
                xdcc_index=$i
                for key in ${keys[@]}
                do
                    unset xdcc[$key,$i]
                done
                break
                
            else
                for key in ${keys[@]}
                do
                    unset xdcc[$key,$i]
                done
                break
            fi
        fi
    done

    if [ -z "$xdcc_index" ]
    then
        for ((i=0; i<=$counter; i++))
        do
            if [ -z "${xdcc['url',$i]}" ]
            then
                xdcc_index=$i
                break
            fi
        done
    fi

    set_xdcc_key_value url "$url"
    
    ###### data structure in xdcc_struct:
    ## xdcc_pid
    ##
    #### hash table:
    ## xdcc['$key',$xdcc_index]
}


function del_xdcc_url {
    local res K i counter    

    if url "$1"
    then
        local match="$(grep "$1" "$xdcc_host_url_data" | grep -oP ',[0-9]+\]')"

        grep -v "$match" "$xdcc_host_url_data" > "$xdcc_host_url_data".new
        mv "$xdcc_host_url_data".new "$xdcc_host_url_data"

        echo "xdcc_pid='$xdcc_pid'" > "$xdcc_host_url_data"
        
        count_xdcc counter
        
        for ((i=0; i<=$counter; i++))
        do
            for K in ${keys[@]}
            do
                if [ "$1" == "${xdcc['url',$i]}" ]
                then
                    res+="unset xdcc[$K,$i]\n"
                fi
            done
        done
        echo -e "$res" >> "$xdcc_host_url_data"

        [ -f "$xdcc_host_url_data" ] && get_xdcc_host_url_data
    fi
}

function count_xdcc {    
    declare -n ref="$1"
    local c1=0 c2=0

    get_xdcc_host_url_data
    
    for ((i=0; i<${#xdcc[@]}; i++))
    do
        if [ -n "${xdcc['url',$i]}" ]
        then
            c1=$((c1 + c2 +1))
            c2=0
        else
            ((c2++))            
        fi
    done

    ref="$c1"
}

function set_xdcc_var_value {
    local var="$1" value="$2"
    sed -r "s;$var=.+;$var='$value';g" -i "$xdcc_host_url_data"
    source "$xdcc_host_url_data"
}

function set_xdcc_key_value {
    local Key="$1" Value="$2"

    source "$xdcc_host_url_data"
    xdcc[$Key,$xdcc_index]="$Value"

    set_xdcc_struct
}

function set_xdcc_pid {
    local host="$1"
    if [ -z "$host" ]
    then
        host="${xdcc['host',$xdcc_index]}"
    fi

    unset xdcc_pid

    touch "$xdcc_host_url_data"
    grep -q "xdcc_pid='" "$xdcc_host_url_data" ||
        echo "xdcc_pid=''" >>"$xdcc_host_url_data" 
    
    for test_xdcc_pid_file in $(get_xdcc_data_files "$host")
    do
        test_xdcc_pid=$(grep 'xdcc_pid=' "$test_xdcc_pid_file")
        test_xdcc_pid="${test_xdcc_pid#*\'}"
        test_xdcc_pid="${test_xdcc_pid%\'*}"
        
        if lsof -i -d3 |
                grep " $test_xdcc_pid " |
                grep -q irc_clien |
                grep -v CLOSE_WAIT
        then
            xdcc_pid="$test_xdcc_pid"
            set_xdcc_var_value xdcc_pid "$test_xdcc_pid"
            break
        fi
    done
    
    if [ -z "$xdcc_pid" ]
    then
        xdcc_pid="$PID"
        set_xdcc_var_value xdcc_pid "$PID"
    fi
    source "$xdcc_host_url_data"
}

function set_xdcc_struct {    
    local counter res k i

    echo "xdcc_pid='$xdcc_pid'" > "$xdcc_host_url_data"

    count_xdcc counter

    for ((i=0; i<=$counter; i++))
    do
        if url "${xdcc['url',$i]}"
        then
            for k in ${keys[@]}
            do
                [ $k == url ] && res+="\n"

                if grep -q "${xdcc['url',$i]}" "$path_tmp"/links_loop.txt
                then
                    res+="xdcc['$k',$i]='${xdcc[$k,$i]}'\n"
                else
                    res+="unset xdcc[$k,$i]\n"
                fi                    
            done
        fi
    done

    echo -e "$res" >> "$xdcc_host_url_data"

    [ -f "$xdcc_host_url_data" ] && source "$xdcc_host_url_data"
}


function start_xfer_killer {
    xdcc_remove_file="$path_tmp"/xdcc-remove-$(create_hash "${xdcc['url',$xdcc_index]}")

    rm -f "$xdcc_remove_file" ]

    get_xdcc_host_url_data
    if check_pid_regex "$xdcc_pid" irc_client
    then
        sleep 0.1
    fi

    {
        while check_pid_regex "$xdcc_pid" irc_client
        do
            if [ -f "$xdcc_remove_file" ] 
            then
                print_c 2 ">> PRIVMSG ${xdcc['slot',$xdcc_index]} xdcc cancel"
                ## irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc remove"
                irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc cancel"

                sleep 5
                kill "${xdcc['pid_cat',$xdcc_index]}"
                rm -rf "$xdcc_remove_file"
                break
            fi
            
            sleep 0.5
        done
    } &    
}


function get_xdcc_data_files {
    local host
    
    if [ -n "$*" ]
    then
        for host in $@
        do
            ls /tmp/"$host"--zdl--*.data
        done
    else
        ls /tmp/*--zdl--*.data
    fi
}

function get_xdcc_host_url_data {
    if [ -f "$xdcc_host_url_data" ]
    then
        grep -P "(=\'[^\']*\'$)" "$xdcc_host_url_data" >"$xdcc_host_url_data".new
        mv "$xdcc_host_url_data".new "$xdcc_host_url_data"

        if [ -f "$xdcc_host_url_data" ] &&
               [ -n "$(< "$xdcc_host_url_data")" ]
        then
            source "$xdcc_host_url_data"
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}


##########################################
function extract_irc_line {
    local line="$1"

    line=$(tr -d "\001\015\012" <<< "${line//\*}")

    irc['code']=$(cut -d' ' -f2 <<<"$line")  # ----> ['cmd']??

    irc['line']="$line"
    
    if [ "${line:0:1}" == ":" ]
    then
	local from="${line%% *}" 
        line="${line#* }"
    fi
    
    irc['from']="${from:1}"
    irc['to']="${from%%\!*}"
    irc['txt']=$(trim "${line#*:}")
    irc['cmd']="${line%% *}"
}


function irc_ping_pong {
    local chunk ping_code
    
    if [[ "${irc['line']}" =~ PING ]]
    then
	if [ -n "${irc['txt']}" ]
	then
	    chunk=":${irc['txt']}" 
            [ -z "$ping_code" ] && ping_code="${irc['txt']}" 
	else
	    chunk="${xdcc['nick',$xdcc_index]}"
	fi
        print_c 2 "<< ${irc['line']}"
        irc_send "PONG $chunk"
	print_c 1 ">> PONG $chunk"

    elif [[ "${irc['line']}" =~ PONG ]]
    then
        print_c 1 "<< ${irc['line']}"
    fi
}

function set_irc_request {
    echo "$xdcc_host_url_data" > "$path_tmp"/irc_request &&
        return 0 ||
            return 1
}

function get_irc_request {
    if [ -f "$path_tmp"/irc_request ]
    then
        local req=$(< "$path_tmp"/irc_request )
        
        if [[ "$req" =~ /tmp/${irc['host']}--zdl-- ]]
        then
            xdcc_host_url_data="$req"
            echo >"$path_tmp"/irc_request
            touch "$path_tmp"/irc_request_ok 
            return 0
        fi
    fi
    return 1
}

function reset_irc_request {    
    if [ -f "$path_tmp"/irc_request_ok ] || [ "$1" == force ]
    then
        rm -f "$path_tmp"/irc_request_ok "$path_tmp"/irc_request
        rm -f "$path_tmp"/irc_file_url
    fi
}

function check_ip_xfer {
    local ip_address="$1"

    if [[ "$ip_address" =~ ^[0-9]+$ ]]
    then
	ip_address=$(integer2ip $ip_address)
	
    elif [[ "$ip_address" =~ ^[0-9a-zA-Z:]+$ ]]
    then
	ip_address="[$ip_address]"
    fi

    if [ -n "$ip_address" ]
    then
	printf "$ip_address"
	return 0

    else
	return 1
    fi
}

function dcc_xfer {
    local offset old_offset pid_cat

    if [ "$test_resume" == true ]
    then
        unset test_resume
        for ((i=0; i<10; i++))
        do		    
	    if get_resume
	    then
                init_resume
                resume=true
	        break
	    fi
	    sleep 1
        done
    fi

    if [ "${xdcc['port',$xdcc_index]}" == 0 ]
    then        
	if [ -n "$resume" ]
	then
            unset resume
        else
            rm -f "$file_xfer"
        fi

        #socat -u TCP-L:$tcp_port,reuseaddr,fork,rcvbuf=1 OPEN:"$file_xfer",creat,append &
        socat -u TCP-L:$tcp_port,reuseaddr,fork OPEN:"$file_xfer",creat,append &
        pid_cat=$!
        
        until check_pid "$pid_cat"
        do sleep .1
        done
        
        get_ip real_ip proxy_ip
        print_c 2 "CTCP [reverse]>> PRIVMSG ${xdcc['slot',$xdcc_index]} :DCC SEND ${xdcc['file',$xdcc_index]} $(ip2integer $real_ip) $tcp_port ${xdcc['size',$xdcc_index]} ${xdcc['token',$xdcc_index]}"
        irc_ctcp "PRIVMSG ${xdcc['slot',$xdcc_index]}" "DCC SEND ${xdcc['file',$xdcc_index]} $(ip2integer $real_ip) $tcp_port ${xdcc['size',$xdcc_index]} ${xdcc['token',$xdcc_index]}"
        
    else
        local xfer_address="/dev/tcp/${xdcc['address',$xdcc_index]}/${xdcc['port',$xdcc_index]}"
        if exec 4<>"$xfer_address"
        then
	    if [ -n "$resume" ]
	    then
	        unset resume
	        cat <&4 >>"$file_xfer" &
	        pid_cat=$!
                
	    else
	        cat <&4 >"$file_xfer" &
	        pid_cat=$!
	    fi
        fi
    fi

    countdown- 3

    if [ -n "$pid_cat" ]
    then
	print_c 1 "$(gettext "Connected to the address"): ${xdcc['address',$xdcc_index]}:${xdcc['port',$xdcc_index]}"
        del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
        
	echo "${xdcc['url',$xdcc_index]}"  >"$file_xfer.zdl"
	add_pid_url "$pid_cat" "${xdcc['url',$xdcc_index]}" "xfer-pids"
        set_xdcc_key_value pid_cat "$pid_cat"
        
	until (
            [ -f "$xfer_tmp" ] &&
                grep -q ____PID_IN____ "$xfer_tmp"
        )
        do
            sleep 0.1
        done
        sed -r "s,____PID_IN____,$pid_cat,g" -i "$xfer_tmp"
    fi

    until [ -f "$file_xfer" ]
    do
        sleep 0.1
    done

    reset_irc_request
    start_xfer_killer

    while check_pid "$pid_cat" && [ "$offset" != "${xdcc['size',$xdcc_index]}" ]
    do
        [ -f "$path_tmp/irc-timeout" ] &&
	    ! grep -q "${xdcc['url',$xdcc_index]}" "$path_tmp/irc-timeout" &&
	    echo "${xdcc['url',$xdcc_index]}" >>"$path_tmp/irc-timeout"

        offset=$(size_file "$file_xfer")
        [ -z "$offset" ] && offset=0
        [ -z "$old_offset" ] && old_offset=$offset
        (( old_offset > offset )) && old_offset=$offset

        printf "XDCC %s %s %s XDCC\n" "$offset" "$old_offset" "${xdcc['size',$xdcc_index]}" >>"$xfer_tmp" 

        if [[ "$(head -n2 "$xfer_tmp" | tail -n1)" =~ ^XDCC ]] ||
	       [[ "$file_xfer" =~ XDCC' ' ]]                   
        then		    
	    kill "$pid_cat"
	    rm -f "$path_tmp/${file_xfer}_stdout".*
        fi
        old_offset=$offset

        check_pid_regex "$xdcc_pid" irc_client ||
            kill "$pid_cat"

        sleep 1
    done

    if [ "$(size_file "$file_xfer")" == "${xdcc['size',$xdcc_index]}" ]
    then
        kill $pid_cat
        rm -f "${file_xfer}.zdl"
        set_link - "${xdcc['url',$xdcc_index]}"
        #del_xdcc_url "${xdcc['url',$xdcc_index]}" 
    fi
    exec 4>&-   

    set_xdcc_key_value sent true
    
    if ! grep -qP "${xdcc['host',$xdcc_index]}.+xdcc%20send" "$path_tmp"/links_loop.txt
    then
        ## non chiudiamo/uccidiamo una connessione all'host se dobbiamo ancora scaricare link che la richiedono (se cade da sola viene rifatta da istanza di ZDL)
        irc_quit
        kill "$xdcc_pid"
    fi
    
    exit
}

function irc_set_nick {
    print_c 2 ">> NICK: ${xdcc['nick',$xdcc_index]}"
    irc_send "NICK ${xdcc['nick',$xdcc_index]}"
}

function irc_connect_server {
    local irc_line \
          retry=false \
          timeout=0
    
    print_c 2 ">> HOST: ${irc['host']}"
    irc_send "USER ${xdcc['nick',$xdcc_index]} localhost ${xdcc['host',$xdcc_index]} :${xdcc['nick',$xdcc_index]}"            

    while :
    do
        unset irc_line
        read -t 0.1 -u 3 irc_line
        
        if [ "$retry" == true ]
        then
            print_c 2 ">> HOST: ${irc['host']}"
            irc_send "USER ${xdcc['nick',$xdcc_index]} localhost ${xdcc['host',$xdcc_index]} :${xdcc['nick',$xdcc_index]}"
            retry=false
        fi
        
        get_mode       
        extract_irc_line "$irc_line"
        irc_ping_pong

        [ -n "${irc_line// }" ] &&
            print_c 4 "$irc_line"

        if [ -z "${irc['line']}" ]
        then
            ((timeout++))
        else
            timeout=0
        fi

        if [[ "${irc['line']}" =~ (MODE "${xdcc['nick',$xdcc_index]}") ]] 
        then
	    print_c 1 "${irc['line']}"
            print_c 1 "<< NICK: ${xdcc['nick',$xdcc_index]} HOST: ${xdcc['host',$xdcc_index]}"
            return 0
        fi
        
        ((timeout > 200)) && return 1
        
        case "${irc['cmd']}" in
            433)
                if [ "${irc['txt']}" == "Nickname is already in use." ]
                then
                    retry=true
                    irc['nick']="${irc['nick']:0:4}"$(date +%s)
                    set_xdcc_key_value nick "${irc['nick']}"
                    irc_set_nick
                    continue
                fi
                ;;
            
            # QUIT)
            #     if [[ "${irc['line']}" =~ "$ping_code" ]]
            #     then
            #         print_c 3 "${irc['line']}"
            #         irc_quit
            #         #exit
            #     fi
            #     ;;
            
            ERROR)
                get_ip real_ip proxy_ip
                if [[ "${irc['line']}" =~ \[$real_ip\] ]]
                then
                    print_c 3 "${irc['line']}"
                    #irc_quit
                    #exit
                    reset_irc_request
                    
                elif [[ "${irc['line']}" =~ (Closing link: ${xdcc['nick',$xdcc_index]}\[$real_ip\]) ]]
                then
                    print_c 3 "${irc['line']}"
                    
                    reset_irc_request
                    irc_quit                    
                fi
                ;;
        esac
        
    done 
}

function irc_join_chan {
    local irc_line 
    print_c 2 ">> CHAN: ${xdcc['chan',$xdcc_index]}"

    print_c 2 ">> JOIN #${xdcc['chan',$xdcc_index]}"
    irc_send "JOIN #${xdcc['chan',$xdcc_index]}"

    while :
    do
        unset irc_line
        read -t 0.1 -u 3 irc_line 

        get_mode       
        extract_irc_line "$irc_line"        
        irc_ping_pong

        [ -n "${irc_line// }" ] &&
            print_c 4 "[chan]\n$irc_line"        

        if [[ "${irc['line']}" =~ (JOIN :) ]] 
        then
            print_c 1 "<< ${irc['line']}"
            break           
        fi

        case "${irc['cmd']}" in
            QUIT)
                if [[ "${irc['line']}" =~ ${xdcc['nick',$xdcc_index]} ]] # "$ping_code" ]]
                then
                    print_c 3 "${irc['line']}"
                    break
                fi
                ;;
            
            ERROR)
                get_ip real_ip proxy_ip
                if [[ "${irc['line']}" =~ \[$real_ip\] ]]
                then
                    print_c 3 "${irc['line']}"
                    break

                elif [[ "${irc['line']}" =~ (Closing link: ${xdcc['nick',$xdcc_index]}\[$real_ip\]) ]]
                then
                    print_c 3 "${irc['line']}"

                    reset_irc_request
                    irc_quit                    
                fi
                ;;
        esac

        if ((timeout > 1800))
        then
            print_c 2 ">> CHAN: ${xdcc['chan',$xdcc_index]}"
            
            print_c 2 ">> JOIN #${xdcc['chan',$xdcc_index]}"
            irc_send "JOIN #${xdcc['chan',$xdcc_index]}"
            
            reset_irc_request
            exit
        fi
        ((timeout++))
    done
}

function irc_check_chan_user {
    local irc_line irc_cmd irc_txt
    [ "$chan" == true ] &&  {
        print_c 1 ">> NAMES #${xdcc['chan',$xdcc_index]}"
        irc_send "NAMES #${xdcc['chan',$xdcc_index]}"
    }
}

function irc_xdcc_send {
    local irc_line timeout_start=$(date +%s) connected=false
    declare -a ctcp_msg

    set_xdcc_key_value pid_cat ''
    set_xdcc_key_value pid_xfer ''
    
    # xdcc_cancel
    # countdown- 13
    
    print_c 2 ">> PRIVMSG ${xdcc['slot',$xdcc_index]} :xdcc send ${xdcc['pack',$xdcc_index]}"
    
    ##/MSG <slot> XDCC SEND <#pack>    
    irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc send ${xdcc['pack',$xdcc_index]}"
    timeout_dcc=$(date +%s)
    timeout_dcc_delay=30

    exec 6<>"$xdcc_host_url_fifo"
    
    while :
    do
        get_mode
        unset irc_line
        read -t 0.1 -u 3 irc_line
        
        get_xdcc_host_url_data
        
        extract_irc_line "$irc_line"
        irc_ping_pong

        if (( ( $(date +%s) - timeout_dcc ) > $timeout_dcc_delay )) ||
               (
                   [ "$connected" == true ] &&
                       [ -n "${xdcc['pid_cat',$xdcc_index]}" ] && check_pid "${xdcc['pid_cat',$xdcc_index]}" ||
                           [ "${xdcc['sent',$xdcc_index]}" == true ] ||
                           (( ( $(date +%s) - timeout_start ) > 190 )) ||
                           ! check_pid "$(< "$path_tmp/.pid.zdl")"
               )
        then
            (( ( $(date +%s) - timeout_dcc ) > $timeout_dcc_delay )) &&
                print_c 3 "TIMEOUT xdcc send (delay: $timeout_dcc_delay sec)"
            exec 6>&-
            rm -f "$xdcc_host_url_fifo"
            reset_irc_request
            break
        fi
        
        if [ -z "${irc_line// }" ]
        then
            unset irc_line
            read -t 0.1 -u 6 irc_line 
            
            extract_irc_line "$irc_line"
            irc_ping_pong

            if [ -z "${irc_line// }" ]
            then
                sleep 1
                continue
            else
                timeout_start=$(date +%s)
            fi
        else
            timeout_start=$(date +%s)
        fi

        ## triggers ########################################

        if [[ "$irc_line" =~ You\ cannot\ send\ messages\ to\ users\ until\ .+\ been\ connected\ for\ ([0-9]+)\ seconds\ or\ more ]]
        then
            xdcc_send_delay="${BASH_REMATCH[1]}"
            print_c 3 "\n$irc_line"
            
            print_c 2 ">> PRIVMSG ${xdcc['slot',$xdcc_index]} :xdcc send ${xdcc['pack',$xdcc_index]}"
            countdown- $(( $xdcc_send_delay +5 ))
            
            ##/MSG <slot> XDCC SEND <#pack>    
            irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc send ${xdcc['pack',$xdcc_index]}"
            timeout_dcc=$(date +%s)
            timeout_dcc_delay=180
        fi
        
        if [ "${irc['cmd']}" == NOTICE ]
        then
            local chan match
            notice="${irc['line']}"
            notice2="${notice%%:*}"
            notice2="${notice2%%','*}"
            notice2="${notice2%%[0-9]*}"
            notice2="${notice2%%SEND*}"
            notice2=$(trim "$notice2")
            
            if [[ "${irc['txt']}" =~ XDCC\ SEND\ (denied|negato) ]]
            then
                print_c 3 "${irc['txt']}"
                reset_irc_request
                break

            elif [[ "${irc['txt']}" =~ XDCC\ REMOVE ]]
            then
                print_c 3 "${irc['txt']}"
                xdcc_send_remove
                reset_irc_request
                break

            elif [[ "${irc['txt']}" =~ DCC\ Timeout\ \(180\ Sec\ Timeout\) ]]
            then
                print_c 3 "${irc['txt']}"
                xdcc_send_remove
                reset_irc_request
                break

            elif [[ "${irc['txt']}" =~ (Connection reset by peer) ]]
            then
                print_c 3 "${irc['txt']}"
                #exec 3>&-
                reset_irc_request
                break
                
            elif grep -qP '(richiesto questo pack|You already requested that pack)' <<< "$irc_line"
            then
                print_c 3 "$irc_line"
                notice="${BASH_REMATCH[1]}"
                _log 27 "${xdcc['url',$xdcc_index]}" 
                xdcc_cancel
                xdcc_remove
                #irc_send QUIT
                reset_irc_request
                #del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
                break
                
            elif grep -q "${xdcc['nick',$xdcc_index]}" <<< "${irc['line']}" &&
                    grep -q "pack errato" <<< "${irc['line']}"
            then
                print_c 3 "$irc_line"
                _log 3 "${xdcc['url',$xdcc_index]}"
                reset_irc_request
                break
            fi
            
            # if grep -P '(433|743|879|883|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' <<< "$notice"
            # then
            #     _log 27 "${xdcc['url',$xdcc_index]}"
            #     print_c 3 "NOTICE code: ${BASH_REMATCH[1]}"
            # fi
            
        elif [ "${irc['cmd']}" == PRIVMSG ] ||
                 [[ "${irc['line']}" =~ PRIVMSG.+"${xdcc['nick',$xdcc_index]}".+DCC(SEND|RESUME|ACCEPT) ]]
        then            
            local irc_code key 
            ctcp_msg=( $(tr -d "\001\015\012" <<< "${irc['txt']}") )
            ########### get msg code: 
            # irc_code=$(get_irc_code "${ctcp_msg[*]}")
            # case $irc_code in
            # 	743|883|878|879|1124|1131)
            # 	    irc_quit
            # 	    ;;
            # esac                
            
            if [ "${ctcp_msg[0]}" == 'DCC' ] &&
	           [ -n "${xdcc['slot',$xdcc_index]}" ]
            then
                timeout_dcc=$(date +%s)

	        if [ "${ctcp_msg[1]}" == 'ACCEPT' ]
	        then
	            print_c 1 "CTCP<< PRIVMSG ${xdcc['slot',$xdcc_index]} :${ctcp_msg[*]}"
	            set_resume
	            
	        elif [ "${ctcp_msg[1]}" == 'SEND' ]
	        then
	            print_c 1 "CTCP<< PRIVMSG ${xdcc['slot',$xdcc_index]} :${ctcp_msg[*]}"
                    
	            set_xdcc_key_value file "${ctcp_msg[2]}"
	            set_xdcc_key_value address "${ctcp_msg[3]}"
	            set_xdcc_key_value size "${ctcp_msg[5]}"
	            set_xdcc_key_value offset $(size_file "${xdcc['file',$xdcc_index]}")
                    [ -z "${xdcc['offset',$xdcc_index]}" ] && set_xdcc_key_value offset 0
                    set_xdcc_key_value address $(check_ip_xfer "${xdcc['address',$xdcc_index]}")
                    set_xdcc_key_value port "${ctcp_msg[4]}"
                    
                    if [ "${ctcp_msg[4]}" == 0 ] && [ -n "${ctcp_msg[6]}" ]
                    then
	                set_xdcc_key_value token "${ctcp_msg[6]}"
                    fi                  

                    if [ -n "${xdcc['address',$xdcc_index]}" ] &&
		           [[ "${xdcc['port',$xdcc_index]}${xdcc['token',$xdcc_index]}" =~ ^[0-9]+$ ]]
	            then
                        send_dcc_resume

		        file_xfer="${xdcc['file',$xdcc_index]}"
		        sanitize_file_xfer

		        url_xfer="/dev/tcp/${xdcc['address',$xdcc_index]}/${xdcc['port',$xdcc_index]}"
		        #echo -e "$file_xfer\n$url_xfer" > "$path_tmp/$(create_hash "${xdcc['url',$xdcc_index]}")"
                        echo -e "$file_xfer\n$url_xfer" > "$test_xfer"
                        
                        xfer_tmp="$path_tmp/${file_xfer}_stdout.tmp"
		        until [ -f "$xfer_tmp" ]
		        do
                            sleep 0.1
		        done

		        dcc_xfer &
                        local pid_xfer=$!
                        disown pid_xfer
		        set_xdcc_key_value pid_xfer $pid_xfer

                        until check_pid "${xdcc['pid_xfer',$xdcc_index]}"
                        do
                            sleep 0.1
                        done
                        connected=true

		        #add_pid_url "${xdcc['pid_xfer',$xdcc_index]}" "${xdcc['url',$xdcc_index]}" "xfer-pids"
	            fi
	        fi                
            fi
            
        elif [ -e "$xdcc_host_fifo" ]
        then
            echo "$irc_line" > "$xdcc_host_fifo"
            unset irc_line
        fi
        
        [ -n "${irc_line// }" ] &&
            print_c 4 "[xdcc]\n$irc_line"
    done

    sleep 2
    
    rm -rf "$path_tmp"/irc_file_url
    reset_irc_request
}


function irc_main {
    local irc_line \
          connected=false \
          connection=true \
          dev_host="/dev/tcp/${irc['host']}/${irc['port']}"
    countdown- 3

    get_xdcc_host_url_data
    xdcc_host_fifo="/tmp/${irc['host']}.fifo"
    unset test_pid

    if [ "$xdcc_pid" != "$PID" ]
    then
        connection=false
        connected=true       
    fi

    if [ "$connection" == true ]
    then
        [ -e "$xdcc_host_fifo" ] ||
            mkfifo "$xdcc_host_fifo"

        local ___timeout ___timeout_test 
        if [ "$connected" == false ]
        then
            {
                until lsof -a -d3 | grep -qP 'irc_clien.+TCP'
                do
                    ___timeout_test=$(lsof -a -d3 | grep -qP 'irc_clien.+TCP')
                    sleep 0.1
                done
                
                for ___timeout in {0..5}
                do
                    sprint_c 0 "%d\r" $___timeout
                    sleep 1
                    ___timeout_test=$(lsof -a -d3 | grep -P 'irc_clien.+TCP')
                    
                    if [[ "$___timeout_test" =~ ESTABLISHED ]]
                    then
                        exit
                        
                    elif [[ "$___timeout_test" =~ SYN_SENT ]]
                    then
                        sleep 1
                        
                    elif [ -z "$___timeout_test" ]
                    then
                        exit
                    fi
                done
                pid=$(cut -f2 <<< "$___timeout_test")

                print_c 3 "TIMEOUT host server connection"  ## SYN_SENT
                irc_die
            } &
            local piddd=$!

            countdown- 5
            if exec 3<>"$dev_host" 
            then
                connected=true
            fi
        fi

        if [ "$connected" == true ] 
        then
            get_mode
            irc_set_nick
            irc_connect_server 
        fi

        ###### MAIN-loop: JOIN-CHAN ---> XDCC SEND:
        if [ "$connected" == true ] 
        then
            exec 5<>"$xdcc_host_fifo"
            
            timeout_start=$(date +%s)
            timeout_start_PING=$(date +%s)

            declare -a chans_joined
            local chan_joined joined
            
            while check_pid "$(< "$path_tmp"/.pid.zdl)"
            do
                get_mode
                
                if get_irc_request
                then
                    if [[ "$xdcc_host_url_data" =~ /tmp/${irc['host']}--zdl-- ]]
                    then
                        get_xdcc_host_url_data
                        xdcc_host_url_fifo="${xdcc_host_url_data%.data}".fifo    
                        [ -e "$xdcc_host_url_fifo" ] ||
                            mkfifo "$xdcc_host_url_fifo"

                        joined=false

                        for chan_joined in "${chans_joined[@]}"
                        do
                            if [ "${xdcc['chan',$xdcc_index]}" == "$chan_joined" ]
                            then
                                joined=true
                            fi
                        done

                        countdown- 3

                        if [ "$joined" == false ]
                        then
                            irc_join_chan
                            chans_joined+=( "${xdcc['chan',$xdcc_index]}" )
                        fi

                        {
                            irc_xdcc_send
                        } &                
                        xdcc_send_pid=$!
                        disown $xdcc_send_pid
                        
                        until check_pid $xdcc_send_pid
                        do
                            sleep 0.1
                        done
                    else
                        reset_irc_request
                    fi
                fi
                
                unset irc_line
                read -t 1 -u 3 irc_line

                extract_irc_line "$irc_line"
                irc_ping_pong
                
                if (( ( $(date +%s) - timeout_start_PING ) > 90 ))
                then
                    print_c 2 ">> PING :${xdcc['nick',$xdcc_index]} $(date +%s)"
                    irc_send PING ":${xdcc['nick',$xdcc_index]} $(date +%s)"
                    timeout_start_PING=$(date +%s)
                fi

                if [ -z "${irc_line// }" ]
                then
                    unset irc_line
                    read -t 1 -u 5 irc_line
                    
                    extract_irc_line "$irc_line"
                    irc_ping_pong
                    
                    if [ -z "${irc_line// }" ]
                    then
                        sleep 1
                        continue
                    else
                        timeout_start=$(date +%s)
                    fi
                else
                    timeout_start=$(date +%s)
                fi
                
                case "${irc['cmd']}" in
                    ######## testing (move irc_xdcc_send?)
                    # 303)                           
                    #     echo "NICK ON: ${irc['txt']} ---------> ${irc['line']}"
                    #     ;;
                    # 353)
                    #     #echo "TXT: ${irc['txt']}"
                    #     if [[ "${irc['line']}" =~ End\ of\ \/NAMES\ list ]]
                    #     then
                    #         print_c 3 "${irc['line']}"
                    #         names="$names_buffer ${irc['txt']}"
                    #         unset names_buffer
                    
                    #     else
                    #         names_buffer+="${irc['txt']}"
                    #     fi
                    
                    #     if [[ "${irc['line']}" =~ (End of \/NAMES list) ]]
                    #     then
                    #         echo "NAMES: $names"
                    #         unset names
                    #     fi
                    #     ;;

                    QUIT)
                        if [[ "${irc['line']}" =~ ${xdcc['nick',$xdcc_index]} ]] # "$ping_code" ]]
                        then
                            print_c 3 "${irc['line']}"
                            break
                        fi
                        ;;
                    
                    ERROR)
                        get_ip real_ip proxy_ip
                        if [[ "${irc['line']}" =~ \[$real_ip\] ]]
                        then
                            print_c 3 "${irc['line']}"
                            break
                            
                        elif [[ "${irc['line']}" =~ (Closing link: ${xdcc['nick',$xdcc_index]}\[$real_ip\]) ]]
                        then
                            print_c 3 "${irc['line']}"

                            reset_irc_request
                            irc_quit                    
                        fi
                        ;;
                esac

                #### move to XDCC SEND / NOTICE function via FIFO
                
                if (
                    [[ "$irc_line" =~ (PRIVMSG|NOTICE) ]] ||
                        [[ "${irc['cmd']}" =~ (PRIVMSG|NOTICE) ]] ||
                        [[ "${irc['line']}" =~ (PRIVMSG|NOTICE) ]] ||
                        [[ "$irc_line" =~ (You\ cannot\ send\ messages\ to\ users\ until\ .+\ been\ connected\ for\ )([0-9]+)(\ seconds\ or\ more) ]]
                ) &&
                    [ -n "$xdcc_host_url_fifo" ] && [ -e "$xdcc_host_url_fifo" ]
                then
                    echo "$irc_line" > "$xdcc_host_url_fifo"

                elif [ -n "${irc_line// }" ]
                then
                    print_c 4 "[host/chan]\n$irc_line"        
                fi

            done

            return 0
        fi
    fi
    
    if [ "$connected" == true ]
    then
        return 0
    else
        return 1
    fi
}



#### MAIN ############ 
PID=$$

## input args:
url="$1"
test_xfer="$path_tmp"/irc_file_url #$(create_hash "$url")"
this_tty="$2"

## error codes:
#errors=$(grep -P '(743|883|878|879|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' $path_usr/irc/* -h) # |cut -d'"' -f2 |cut -d'%' -f1)
errors_again=$(grep -P '(743|883|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' $path_usr/irc/* -h)
errors_stop=$(grep -P '(878|879)' $path_usr/irc/* -h)

## data structures:
declare -A xdcc

declare -A irc
if [[ "$url" =~ ^irc:\/\/([^/]+)\/([^/]+)\/([^/]+$) ]]
then
    irc=(
	['host']="${BASH_REMATCH[1]}"
	['port']=6667
	['chan']="${BASH_REMATCH[2]}"
	['nick']=$(obfuscate_user) #$(date +%s) #$(obfuscate "$USER")
        ['slot']=$(cut -f2 -d' ' <<< "${url//%20/ }")
        ['pack']=$(cut -f5 -d' ' <<< "${url//%20/ }")
    )
fi

if [[ "${irc[host]}" =~ ^(.+)\:([0-9]+)$ ]]
then
    irc['host']="${BASH_REMATCH[1]}"
    irc['port']="${BASH_REMATCH[2]}"
fi

set_mode "stdout"

init_resume

keys=( url host chan slot pack pid_xfer pid_cat sent file address port size offset )
xdcc_host_url_data="/tmp/${irc[host]}"--zdl--$(create_hash "$url").data

if [ -f "$xdcc_host_url_data" ] &&
       grep -q "'$url'" "$xdcc_host_url_data"
then
    xdcc_index=$(grep "'$url'" "$xdcc_host_url_data")
    xdcc_index="${xdcc_index#*\,}"
    xdcc_index="${xdcc_index%\]*}"

    set_xdcc_key_value url "$url"

else
    add_xdcc_url "$url"
    set_xdcc_struct
fi

set_xdcc_pid "${irc['host']}"

## save input data in xdcc data structure:
set_xdcc_key_value nick "${irc['nick']}"
set_xdcc_key_value host "${irc['host']}"
set_xdcc_key_value chan "${irc['chan']}"
set_xdcc_key_value slot "${irc['slot']}"
set_xdcc_key_value pack "${irc['pack']}"
set_xdcc_key_value sent false

set_irc_request

irc_main || irc_die
