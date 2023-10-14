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
    sed -r "/^${url//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
    
    for i in {0..18}
    do
	now=$(date +%s)
	diff_now=$(( now - start ))

	if grep -q "$url" "$path_tmp/irc-timeout"
	then
	    exit

	elif (( diff_now >= $max_seconds ))
	then
            print_c 3 "irc_client timeout: ${url//'%20'/' '}"

            irc_send QUIT
            exec 3>&-
            
            rm -rf "$test_xfer"
            touch "$path_tmp"/irc_done
	    sed -r "/^.+ ${url//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
	    #kill_url "$url" 'xfer-pids'
	    #kill_url "$url" 'irc-pids'

            
            for test_pid in get_pid_url "${url//\//\\/}" "irc-loop-pids"
            do
                [[ "$test_pid" =~ ^[0-9]+$ ]] && kill -9 $test_pid
            done

            del_pid_url "$url" "irc-wait"
            kill -9 $PID
	    exit
	fi
	
	sleep 10
    done &
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
    irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "XDCC REMOVE"
    kill_url "${xdcc['url',$xdcc_index]}" "xfer-pids"
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
    exec 3>&-

    #kill_url "$url" "irc-pids"
    
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

function check_notice {
    local chan match
    notice="$1"
    notice2=${notice%%:*}
    notice2=${notice2%%','*}
    notice2=${notice2%%[0-9]*}
    notice2=${notice2%%SEND*}
    notice2=$(trim "$notice2")

    if [[ "$line" =~ (Hai gi.+ richiesto questo pack|You already requested that pack)  ]]
    then
        notice="${BASH_REMATCH[1]}"
        _log 27
        xdcc_cancel
        irc_send QUIT
        del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
        return 1
    fi

    if grep -qP  =~ '(433|743|883|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' <<< "$notice"
    then
        _log 27
        return 1
    fi

    if [[ "$notice" =~ (Connection reset by peer) ]]
    then
        irc_quit
        return 1
    fi
    
    # if [[ "$notice" =~ 'JOIN #'([^\ ]+) ]]
    # then
    # 	chan="${BASH_REMATCH[1]}"
    # 	print_c 2 "/JOIN #${chan}"
    # 	irc_send "JOIN #${chan}"
    # fi
}

function check_ctcp {
    local irc_code key 
    declare -a ctcp_msg=( $(tr -d "\001\015\012" <<< "$*") )
    
    ########### codice del msg: 
    # irc_code=$(get_irc_code "${ctcp_msg[*]}")
    # case $irc_code in
    # 	743|883|878|879|1124|1131)
    # 	    irc_quit
    # 	    ;;
    # esac

    if [ "${ctcp_msg[0]}" == 'DCC' ] &&
	   [ -n "${xdcc['slot',$xdcc_index]}" ]
    then
	if [ "${ctcp_msg[1]}" == 'ACCEPT' ]
	then
	    print_c 1 "CTCP<< PRIVMSG ${xdcc['slot',$xdcc_index]} :${ctcp_msg[*]}"
	    set_resume
	    
	elif [ "${ctcp_msg[1]}" == 'SEND' ]
	then
	    print_c 1 "CTCP<< PRIVMSG ${xdcc['slot',$xdcc_index]} :${ctcp_msg[*]}"
	    
	    set_xdcc_key_value file "${ctcp_msg[2]}"
	    set_xdcc_key_value address "${ctcp_msg[3]}"
	    set_xdcc_key_value port "${ctcp_msg[4]}"
	    set_xdcc_key_value size "${ctcp_msg[5]}"
	    set_xdcc_key_value offset $(size_file "${xdcc['file',$xdcc_index]}")
	    [ -z "${xdcc['offset',$xdcc_index]}" ] && set_xdcc_key_value offset 0

            set_xdcc_key_value address $(check_ip_xfer "${xdcc['address',$xdcc_index]}") 
	    if [ -n "${xdcc['address',$xdcc_index]}" ] &&
		   [[ "${xdcc['port',$xdcc_index]}" =~ ^[0-9]+$ ]]
	    then
		return 0
	    fi
	fi
    fi

    return 1
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
	sed -r "/^${url//\//\\/}$/d" -i "$path_tmp"/irc_xdcc_resume
    fi
}

function send_dcc_resume {
    if [ -f "${xdcc['file',$xdcc_index]}" ] &&
	   [ -f "${xdcc['file',$xdcc_index]}.zdl" ] &&
	   [ "$(cat "${xdcc['file',$xdcc_index]}.zdl")" == "${xdcc['url',$xdcc_index]}" ] &&
	   (( xdcc['offset',$xdcc_index] < xdcc['size',$xdcc_index] ))
    then
	irc_ctcp "PRIVMSG ${xdcc['slot',$xdcc_index]}" "DCC RESUME ${xdcc['file',$xdcc_index]} ${xdcc['port',$xdcc_index]} ${xdcc['offset',$xdcc_index]}"
	print_c 2 "CTCP>> PRIVMSG ${xdcc['slot',$xdcc_index]} :DCC RESUME ${xdcc['file',$xdcc_index]} ${xdcc['port',$xdcc_index]} ${xdcc['offset',$xdcc_index]}" 
    fi
}

function check_ip_xfer {
    local ip_address="$1"

    if [[ "$ip_address" =~ ^[0-9]+$ ]]
    then
	ip_address=$(dotless2ip $ip_address)
	
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
    
    if exec 4<>/dev/tcp/${xdcc['address',$xdcc_index]}/${xdcc['port',$xdcc_index]}
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

        if [ -n "$pid_cat" ]
	then
	    print_c 1 "$(gettext "Connected to the address"): ${xdcc['address',$xdcc_index]}:${xdcc['port',$xdcc_index]}"
            del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
            
	    #set_mode "daemon"
	    echo "${xdcc['url',$xdcc_index]}"  >"$file_xfer.zdl"
	    add_pid_url "$pid_cat" "${xdcc['url',$xdcc_index]}" "xfer-pids"
            set_xdcc_key_value pid_cat "$pid_cat"
            
	    until (
                [ -f "$path_tmp/${file_xfer}_stdout.tmp" ] &&
                    grep -q ____PID_IN____ "$xfer_tmp"
            )
            do
                sleep 0.1
            done
            sed -r "s,____PID_IN____,$pid_cat,g" -i "$xfer_tmp"

        else
            del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
            irc_quit
        fi

        this_mode=daemon

        until [ -f "$file_xfer" ]
        do
            sleep 0.1
        done

        set_done
        grep -v "${xdcc['url',$xdcc_index]}" "$path_tmp"/req_irc >"$path_tmp"/req_irc.new
        mv "$path_tmp"/req_irc.new "$path_tmp"/req_irc

        if [ -f "$path_tmp"/xdcc-remove ]
        then
            sed -r "/^${xdcc['url',$xdcc_index]//\//\\/}$/d" -i "$path_tmp"/xdcc-remove 
        fi

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

            if [[ "$(head -n2 "$path_tmp/${file_xfer}_stdout.tmp" | tail -n1)" =~ ^XDCC ]] ||
	           [[ "$file_xfer" =~ XDCC' ' ]]
            then		    
	        kill "$pid_cat"
	        rm -f "$path_tmp/${file_xfer}_stdout".*
            fi
            old_offset=$offset


            sleep 1
        done

        if [ "$(size_file "$file_xfer")" == "${xdcc['size',$xdcc_index]}" ]
        then
            kill $pid_cat
            rm -f "${file_xfer}.zdl"
            set_link - "${xdcc['url',$xdcc_index]}"
            del_xdcc_url "${xdcc['url',$xdcc_index]}" 
        fi
        exec 4>&-
        
    else
        set_done
    fi
    exit
}

function join_chan {
    source "$xdcc_struct_file"
    
    if check_pid "$irc_pid" &&
            [ "${xdcc['sent',$xdcc_index]}" == true ]
    then
        #### `xdcc send` already done in loop alive
        return 1
    fi    
    
    if [[ "$line" =~ (MODE "${irc['nick']}") ]] &&
           [ "${xdcc['sent',$xdcc_index]}" == false ]
    then
	print_c 1 "$line"
	
	print_c 2 ">> JOIN #${xdcc['chan',$xdcc_index]}"
	irc_send "JOIN #${xdcc['chan',$xdcc_index]}"
    fi

    if [ "$in_chan" == true ] || [[ "$line" =~ (JOIN :) ]] #&& [ -n "${irc['msg']}" ] )
    then
        #[[ "$line" =~ ^\: ]] ||
            print_c 1 "<< $line"
        in_chan=true

        return 0
    fi

    # if [[ "$line" =~ 'Join #'([^\ ]+)' for !search' ]]
    # then
    #     chan="${BASH_REMATCH[1]}"
    # 	print_c 2 ">> JOIN #${chan}"
    # 	irc_send "JOIN #${chan}"
    # fi

    return 1
}

function check_line_regex {
    local line="$1"

    # if [[ "$line" =~ (Hai gi.+ richiesto questo pack|You already requested that pack|The session limit for your IP .+ has been exceeded\.)  ]]
    # then
    #     notice="${BASH_REMATCH[1]}"
    #     _log 27
    #     xdcc_cancel
    #     irc_send QUIT
    #     del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
    #     return 1
    # fi

    if [[ "$line" =~ (XDCC REMOVE|XDCC CANCEL)  ]]
    then
        notice="$line"
	_log 27
        irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc cancel"
        irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc remove"
        del_pid_url "${xdcc['url',$xdcc_index]}" "irc-wait"
        return 1
    fi
    
    if [[ "$line" =~ (Nickname is already in use|${xdcc['slot',$xdcc_index]//\|/\\\|}\ *:No such nick\/channel) ]]
    then
	notice="${BASH_REMATCH[1]}"
	_log 27
	irc_quit
        return 1
    fi

    return 0
}

function add_xdcc_url {
    local url="$1" counter key
    unset xdcc_index
    source "$xdcc_struct_file"

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
        echo "COUNTER=$counter"
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
    ## irc_pid
    ##
    #### hash table:
    ## xdcc['$key',$xdcc_index]
}


function set_xdcc_key_value {
    local Key="$1" Value="$2"

    source "$xdcc_struct_file"
    xdcc[$Key,$xdcc_index]="$Value"

    set_xdcc_struct
}

function del_xdcc_url {
    local res K i counter    

    if url "$1"
    then
        local match="$(grep "$1" "$xdcc_struct_file" | grep -oP ',[0-9]+\]')"

        grep -v "$match" "$xdcc_struct_file" > "$xdcc_struct_file".new
        mv "$xdcc_struct_file".new "$xdcc_struct_file"

        echo "irc_pid=$irc_pid" > "$xdcc_struct_file"
        
        count_xdcc counter
        #counter="${#xdcc[@]}"
        
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
        echo -e "$res" >> "$xdcc_struct_file"

        [ -f "$xdcc_struct_file" ] && source "$xdcc_struct_file"
    fi
}

function count_xdcc {    
    declare -n ref="$1"
    local c1=0 c2=0

    source "$xdcc_struct_file"
    
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

function set_xdcc_struct {    
    local counter res k i

    echo "irc_pid=$irc_pid" > "$xdcc_struct_file"

    count_xdcc counter
    #counter="${#xdcc[@]}"

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

    echo -e "$res" >> "$xdcc_struct_file"

    [ -f "$xdcc_struct_file" ] && source "$xdcc_struct_file"
}

function set_done {
    touch "$path_tmp"/irc_done
}

function irc_client {
    local line user from txt irc_cmd xdcc_proc
    dev_host="/dev/tcp/${irc[host]}/${irc[port]}"
    
    if [ -s "$xdcc_struct_file" ]        
    then
        source "$xdcc_struct_file"
        if check_pid "$irc_pid"
        then
            xdcc_proc=false
        else
            xdcc_proc=true
        fi
    fi
    
    if [ "$xdcc_proc" == true ]
    then
        if exec 3<>"$dev_host"
        then
            start_timeout
            
            ## /connect <host>            
	    irc_send "NICK ${irc['nick']}"
	    irc_send "USER ${irc['nick']} localhost ${irc['host']} :${irc['nick']}"
	    print_c 1 "host: ${irc['host']}\nchan: ${irc['chan']}\nmsg: ${irc['slot']} xdcc send #${irc['pack']}\nnick: ${irc['nick']}"
            {
                in_chan=false
                
	        while read line
	        do
	            line=$(tr -d "\001\015\012" <<< "${line//\*}")

	            if [ "${line:0:1}" == ":" ]
	            then
		        from="${line%% *}"
		        line="${line#* }"
	            fi

	            # from="${from:1}"
	            # user=${from%%\!*}
	            txt=$(trim "${line#*:}")
	            irc_cmd="${line%% *}"


	            check_line_regex "$line" 
	            # check_irc_command "$irc_cmd" "$txt"

                    ## ZDL cli mode output:
                    get_mode
	            ## per ricerche e debug:
                    # [[ "$line" =~ ^(372|333|353) ]] ||
                    print_c 4 "$line"                    

                    source "$xdcc_struct_file"
                         
                    ## join chan ---> send xdcc:                    
                    if join_chan #|| [ "$in_chan" == true ]
                    then

                        if [ "${xdcc['sent',$xdcc_index]}" == false ]
                        then
                            if [ -z "${xdcc['pid_cat',$xdcc_index]}" ] || ! check_pid "${xdcc['pid_cat',$xdcc_index]}"
                            then
                                ## /MSG <slot> XDCC SEND <#pack>
                                print_c 2 ">> PRIVMSG ${xdcc['slot',$xdcc_index]} :xdcc send ${xdcc['pack',$xdcc_index]}"
                                
                                # irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc remove"
                                # irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc cancel"                
                                
                                irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc send ${xdcc['pack',$xdcc_index]}"
                                [ -f "$path_tmp"/xdcc-remove ] &&
                                    sed -r "/^${xdcc['url',$xdcc_index]//\//\\/}$/d" -i "$path_tmp"/xdcc-remove
                                
                                set_xdcc_key_value sent true
                                
                            elif [ -n "${xdcc['pid_cat',$xdcc_index]}" ] && check_pid "${xdcc['pid_cat',$xdcc_index]}"
                            then
                                kill "${xdcc['pid_cat',$xdcc_index]}"
                            fi
                        fi
                    fi

                    if [ "${xdcc['sent',$xdcc_index]}" == true ]
                    then
                        if [ -n "${xdcc['pid_cat',$xdcc_index]}" ] && check_pid "${xdcc['pid_cat',$xdcc_index]}"
                        then
                            count_xdcc counter
                            
                            for ((i=0; i<$counter; i++))
                            do
                                if url "${xdcc['url',$i]}" &&
                                        ! check_pid "${xdcc['pid_cat',$i]}" &&
                                        [ -f "$path_tmp"/req_irc ] &&
                                        grep -q "${xdcc['url',$i]}" "$path_tmp"/req_irc
                                then
                                    xdcc_index=$i
                                    set_xdcc_key_value sent false
                                    sed -r "/^${xdcc['url',$xdcc_index]//\//\\/}$/d" -i "$path_tmp"/req_irc
                                fi
                            done
                        fi                    

                        if [ -s "$path_tmp"/xdcc-remove ]
                        then
                            local U I
                            while read U
                            do
                                grep "'$U'" "$xdcc_struct_file"
                                I=$(grep "'$U'" "$xdcc_struct_file")
                                I="${I%\]*}"
                                I="${I#*\,}"
                                
                                # irc_send "PRIVMSG ${xdcc['slot',$xdcc_index]}" "xdcc remove"
                                irc_send "PRIVMSG ${xdcc['slot',$I]}" "xdcc cancel"
                                sed -r "/^${xdcc['url',$I]//\//\\/}$/d" -i "$path_tmp"/xdcc-remove
                                # sed -r "/^${xdcc['url',$xdcc_index]//\//\\/}$/d" -i "$path_tmp"/req_irc
                                
                            done < "$path_tmp"/xdcc-remove

                            sleep 1
                            [ -n "${xdcc['pid_cat',$I]}" ] && kill ${xdcc['pid_cat',$I]}
                            
                            del_xdcc_url "${xdcc['url',$I]}"
                        fi
                    fi
                    
                    ## interaction with the input $line
                    case "$irc_cmd" in
	                PING)
	                    if [ -n "$txt" ]
	                    then
		                chunk=":$txt"
                                [ -z "$ping_code" ] && ping_code="$txt"
	                    else
		                chunk="${irc[nick]}"
	                    fi
                            print_c 2 "<< $line"
                            irc_send "PONG $chunk"
	                    print_c 1 ">> PONG $chunk"
	                    ;;

                        QUIT)
                            if [[ "$line" =~ "$ping_code" ]]
                            then
                                print_c 3 "$line"
                                break
                            fi
                            ;;
                        
                        ERROR)
                            get_ip real_ip proxy_ip
                            if [[ "$line" =~ \[$real_ip\] ]]
                            then
                                print_c 3 "$line"
                                break
                            fi
                            ;;
                        
	                NOTICE)
	                    check_notice "$line"
	                    print_c 4 "<< $txt"
	                    ;;
                        
	                PRIVMSG)
	                    if check_ctcp "$txt"
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
		                set_xdcc_key_value pid_xfer $!
                                
		                #add_pid_url "${xdcc['pid_xfer',$xdcc_index]}" "${xdcc['url',$xdcc_index]}" "xfer-pids"
                                sleep 2
	                    fi
	                    ;;
                    esac
                done <&3
                
                irc_send "QUIT"
                exec 3>&-
                rm -rf "$test_xfer"
                set_done
                kill -9 $PID
            } &
	    local irc_pid_new=$!
            disown $irc_pid_new

            source "$xdcc_struct_file"
            irc_pid=$irc_pid_new
            set_xdcc_struct
            
            until check_pid "$irc_pid"
            do sleep 0.1
            done

            while check_pid "$irc_pid"
            do
                rm -f "$path_tmp"/_stdout.tmp
                sleep  1
            done

	    add_pid_url "$irc_pid" "${xdcc['url',$xdcc_index]}" "irc-loop-pids"
	    echo "$irc_pid" >>"$path_tmp/external-dl_pids.txt"
            add_pid_url "$PID" "${xdcc['url',$xdcc_index]}" "irc-wait"

            while check_pid "$irc_pid"
            do sleep 1
            done

            #irc_send "QUIT"
            #exec 3>&-
            
	    return 0
            
        else
            set_done
            return 1
        fi

    else
        return 0
    fi
}



################ 
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
declare -A ctcp
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


## MAIN:
set_mode "stdout"

#add_pid_url "$PID" "$url" "irc-pids"

init_resume
#add_pid_url "$PID" "$url" "irc-client-pid"

keys=( url host chan slot pack pid_xfer pid_cat sent file address port size offset )
xdcc_struct_file="/tmp/${irc[host]//\/}--zdl--${irc[chan]//\/}"
if [ -f "$xdcc_struct_file" ]
then
    source "$xdcc_struct_file"
    check_pid "$irc_pid" &&
        xdcc_struct_file_exists=true ||
            unset irc_pid
fi

if [ "$xdcc_struct_file_exists" == true ] &&
       grep -q "'$url'" "$xdcc_struct_file"
then
    xdcc_index=$(grep "'$url'" "$xdcc_struct_file")
    xdcc_index="${xdcc_index#*\,}"
    xdcc_index="${xdcc_index%\]*}"
    set_xdcc_key_value url "$url"
    
else
    for F in /tmp/${irc['host']}--zdl--*
    do
        test_pid=$(head -n1 "$F" | cut -d'=' -f2)
        if check_pid "$test_pid"
        then
            irc['nick']+="$(create_hash "${irc[chan]}")" #$(date +%s)
            break
        fi
    done
    add_xdcc_url "$url"
    set_xdcc_struct
fi

## save input data in xdcc data structure:
set_xdcc_key_value host "${irc['host']}"
set_xdcc_key_value chan "${irc['chan']}"
set_xdcc_key_value slot "${irc['slot']}"
set_xdcc_key_value pack "${irc['pack']}"
set_xdcc_key_value sent false

echo "$url" >> "$path_tmp"/req_irc

irc_client ||
    {
        echo "irc_client error"
	touch "$path_tmp"/irc_done
        rm -rf "$test_xfer" 

	_log 26
	exec 3>&-

	if [ -d /cygdrive ]
	then
	    kill -9 $(children_pids $PID)
	    
	else
	    kill -9 $(ps -o pid --no-headers --ppid $PID)
	fi
    }

