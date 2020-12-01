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

#### change IP address
ip_server_url="http://indirizzo-ip.com/ip.php"

function newip_add_host {
    local host
    
    if [ -z $no_newip ]
    then
	for host in ${newip_hosts[*]}
	do	
	    [ "$url_in" != "${url_in//$host.}" ] &&
		newip[${#newip[*]}]=$host
	done
    fi
}

function check_ip {
    local ip="$1"
    get_language
    
    if [ -f "$path_tmp/reconnect" ] &&
	   command -v "${reconnecter%% *}" &>/dev/null
    then
	noproxy
	print_c 4 "\n$(gettext "Starting modem/router reconnection program"): $reconnecter\n" 

	if show_mode_in_tty "$this_mode" "$this_tty"
	then
	    $reconnecter

	else
	    $reconnecter &>/dev/null
	fi

	rm -rf "$path_tmp/links_timer.txt" "$path_tmp/cookies.zdl"
	
    elif [ -f "$path_tmp"/proxy ] &&
	     [[ ! "$(cat "$path_tmp"/proxy)" =~ [0-9.]+ ]]
    then
	unset newip 
	new_ip_proxy
	
    elif [ "${newip[*]}" != "${newip[*]//$ip}" ]
    then
	if [ -f "$path_tmp/reconnect" ] &&
	       command -v "${reconnecter%% *}" &>/dev/null
	then
	    noproxy
	    print_c 4 "\n$(gettext "Starting modem/router reconnection program"): $reconnecter\n"
	    
	    if show_mode_in_tty "$this_mode" "$this_tty"
	    then
		$reconnecter

	    else
		$reconnecter &>/dev/null
	    fi
	    rm -rf "$path_tmp/links_timer.txt" "$path_tmp/cookies.zdl"

	else
	    new_ip_proxy
	fi
	
    elif [ -s "$path_tmp"/proxy ] &&
	     [[ "$(cat "$path_tmp"/proxy)" =~ [0-9.]+ ]]
	 #[ "$update_defined_proxy" == "true" ]
    then
	export http_proxy=$(cat "$path_tmp"/proxy)
	export https_proxy=$http_proxy
    fi
}

function get_ip {
    declare -n real_ip="$1"

    if [ -n "$2" ] && [ -s "$path_tmp"/proxy-active ]
    then
	declare -n proxy_address="$2"
	export http_proxy=$(cat "$path_tmp"/proxy-active)
	
	proxy_address=$(wget -qO- -t1 -T20 "$ip_server_url" -o /dev/null)
	unset http_proxy
    fi
    
    real_ip=$(wget -qO- -t1 -T20 "$ip_server_url" -o /dev/null)
}


function noproxy {
    unset_proxy
}

function unset_proxy {
    unset http_proxy https_proxy
    export http_proxy https_proxy
}

## servizi che offrono liste di proxy
function proxyscrape {
    unset http_proxy https_proxy
    if [[ "$url_in" =~ ^https ]] ||
           ( url "$url_in_file" && [[ "$url_in_file" =~ ^https ]] )
    then
        yes_no=yes
    else
        yes_no=no
    fi

    if [ -n "${proxy_types[*]}" ] &&
           (( ${#proxy_types[*]} == 1 ))
    then
        proxy_type="${proxy_types[0]}"
        
    elif [ -z "${proxy_types[*]}" ] ||
             (( ${#proxy_types[*]} == 0 ))
    then
        proxy_type=Transparent
        
    else
        proxy_type=All
    fi
    
    get_language_prog
    wget "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=10000&country=all&ssl=${yes_no}&anonymity=${proxy_type}&simplified=true" \
         -qO- \
         -o /dev/null |
        tr -d '\r' |
        sed -r "s|(.+)|\1:$proxy_type|g" > "$path_tmp/proxy_list.txt" 
    get_language
    
    [ -s "$path_tmp/proxy_list.txt" ] && return 0 || return 1
}

function ip_adress {
    local proxy_regex
    ## ip-adress.com

    get_language_prog
    wget -q -t 1 -T 20                              \
	 --user-agent="$user_agent"                 \
	 ${list_proxy_url[$proxy_server]}           \
	 -O "$path_tmp/proxy_page.html"             \
	 -o /dev/null
    get_language
    
    for proxy_type in ${proxy_types[*]}
    do
	case "$proxy_type" in
	    Transparent)
		proxy_regex='<td>transparent'
		;;
	    Anonymous)
		proxy_regex='<td>anonymous'
		;;
	    Elite)
		proxy_regex='<td>highly-anonymous'
		;;
	esac
	
	grep "${proxy_regex}" "$path_tmp/proxy_page.html" -B1  |
	    grep href |
	    sed -r "s|.+>([^>]+)</a>([^<]+)<.+|\1\2:$proxy_type|g"  >> "$path_tmp/proxy_list.txt"	
    done
}


function proxy_list {
    #### attualmente non ancora integrata nel più recente sistema
    ## proxy-list.org
    get_language_prog
    wget -q -t 1 -T 20                              \
	 --user-agent="$user_agent"                 \
	 ${list_proxy_url[$proxy_server]}           \
	 -O "$path_tmp/proxy_page.html"             \
	 -o /dev/null
    get_language
    
    for proxy_type in ${proxy_types[*]}
    do
	html=$(grep -B 4 "${proxy_type}" "$path_tmp/proxy_page.html" |grep class)
    done
    ## da fare:
    ## sostituire $html con "$path_tmp"/proxy_list.txt: accodare in modo uniforme questi proxy con quelli dell'altro servizio
    

    ## get_proxy proxy:
    ##
    # n=$(( $(wc -l <<< "$html")/4 ))
    # proxy_type=$(sed -n $(( ${line}*4 ))p <<< "$html")
    # proxy_type="${proxy_type%%'</'*}"
    # proxy_type="${proxy_type##*>}"

    # proxy=$(sed -n $(( ${line}*4-3 ))p <<< "$html")
    # proxy="${proxy#*proxy\">}"
    # proxy="${proxy%<*}"
}

function get_proxy_list {    
    print_c 4 "$(gettext "Proxy list search") %s: %s" "$proxy_server" "${list_proxy_url[$proxy_server]}" 

    $proxy_server
    if [ ! -s "$path_tmp/proxy_list.txt" ]
    then
	print_c 3 "$(gettext "Proxy not available, please try again later")" 
	break
    fi
}

function get_proxy {
    declare -n ref_address="$1"
    declare -n ref_type="$2"

    [ -s "$path_tmp/proxy_list.txt" ] || return 1
    
    local max=$(wc -l < "$path_tmp/proxy_list.txt")
    local proxy_line=$(head -n1 "$path_tmp/proxy_list.txt")
    
    [[ "$proxy_line" =~ Anonymous ]] && ref_type="Anonymous"
    [[ "$proxy_line" =~ Transparent ]] && ref_type="Transparent"
    [[ "$proxy_line" =~ Elite ]] && ref_type="Elite"

    [ -z "${ref_type}" ] && ref_type=All
    
    ref_address="${proxy_line%:${ref_type}*}"
}

function del_proxy {
    local proxy_address="$1"

    if [ -s "$path_tmp/proxy_list.txt" ]
    then
	grep -v "${proxy_address}" "$path_tmp/proxy_list.txt" >"$path_tmp/proxy_list.temp"
	mv "$path_tmp/proxy_list.temp" "$path_tmp/proxy_list.txt"
    fi
}

function check_speed {
    ## $1 == url to test
    local maxspeed=0
    local minspeed=25
    local num_speed type_speed speed
    local test_url="$1"
    get_language
    print_c 2 "\n$(gettext "Download speed test"):" 

    i=0
    while (( i<3 ))
    do
	i=${#speed[*]}
	#speed[$i]=$(wget -t 1 -T 60 -O /dev/null "http://indirizzo-ip.com/ip.php" 2>&1 | grep '\([0-9.]\+ [KM]B/s\)' )
	#speed[$i]=$(wget -t 1 -T $max_waiting -O /dev/null "$url_in" 2>&1 | grep '\([0-9.]\+ [KM]B/s\)' )

	get_language_prog
	wget -t 1 -T $max_waiting \
	     --user-agent="$user_agent" \
	     -O /dev/null "$test_url" \
	     -o "$path_tmp"/speed-test-proxy
	get_language
	
	speed[$i]=$(grep '\([0-9.]\+ [KM]B/s\)' "$path_tmp"/speed-test-proxy)
	
	if [ -n "${speed[$i]}" ]
	then
	    speed[$i]="${speed[$i]#*'('}"
	    speed[$i]="${speed[$i]%%)*}"
	    
	    type_speed[$i]="${speed[$i]//[0-9. ]}"
	    num_speed[$i]="${speed[$i]//${type_speed[$i]}}"
	    num_speed[$i]="${num_speed[$i]//[ ]*}"
	    num_speed[$i]="${num_speed[$i]//[.,]*}"

	    if [ "${type_speed[$i]}" == 'B/s' ]
	    then
		num_speed[$i]="0"

	    elif [ "${type_speed[$i]}" == 'MB/s' ]
	    then
		num_speed[$i]=$(( ${num_speed[$i]}*1024 ))
	    fi
	else
	    speed[$i]="0 KB/s"
	    num_speed[$i]="0"
	    type_speed[$i]='KB/s'
	fi
	print_c 0 "${speed[i]}"

	if (( "${num_speed[0]}" == 0 ))
	then
	    break

	elif (( "${num_speed[i]}" >= 25 ))
	then
	    print_c 1 "$(gettext "Sufficient download speed using the proxy") $http_proxy: ${num_speed[i]} KB/s"
	    echo "$http_proxy" > "$path_tmp"/proxy-active
	    return 0
	fi
    done 2>/dev/null
    
    for k in ${num_speed[*]}
    do
    	(( $maxspeed<$k )) && maxspeed=$k 
    done
    
    if (( $maxspeed<$minspeed ))
    then
    	print_c 3 "$(gettext "The maximum download speed achieved using the proxy is less than the minimum required") ($minspeed KB/s)"
	rm -f "$path_tmp"/proxy-active
	return 1

    else
    	print_c 1 "$(gettext "Maximum download speed achieved using the proxy") $http_proxy: $maxspeed KB/s"
    	return 0
    fi 
}

function new_ip_proxy {
    local test_url

    rm -f "$path_tmp/proxy.tmp" "$path_tmp/cookies.zdl" "$path_tmp/proxy_list.txt" 

    if [ -s "$path_tmp"/proxy ]
    then
	proxy_types=( $(cat "$path_tmp"/proxy) )
    fi
    
    ##########################################
    ## tipi di proxy: Anonymous Transparent Elite
    ## da impostare nelle estensioni in cui si fa uso di check_ip:
    ## proxy_types=( ELENCO TIPI DI PROXY )
    ##
    ## predefinito:
    if [ -z "${proxy_types[*]}" ]
    then
	proxy_types=( "Transparent" )
    fi
    ##########################################
    
    while true
    do
	noproxy
	unset proxy_address proxy_type
	get_language
	print_c 1 "\n$(gettext "Update proxy") (${proxy_types[*]// /, }):"

	if [ ! -s "$path_tmp/proxy_list.txt" ]
	then
	    get_proxy_list
	fi
	get_proxy proxy_address proxy_type
        
	export http_proxy="$proxy_address"
	export https_proxy="$http_proxy"
	print_c 0 "Proxy: $http_proxy ($proxy_type)\n"
	
	del_proxy "$proxy_address"

 	url "$url_in" &&
	    [[ "$url_in" =~ ^http ]] &&
	    test_url="$url_in" ||
		test_url="$ip_server_url"
	
	if check_speed "$test_url"
	then
	    break

	elif [ ! -s "$path_tmp/proxy_list.txt" ]
	then
	    print_c 3 "$(gettext "Proxy currently unavailable: attempt with proxy disabled")"
	    break
	    
	else
	    show_downloads
	fi
    done
    
    [ ! -s "$path_tmp/proxy_list.txt" ] && rm -f "$path_tmp/proxy_list.txt"

    print_c 4 "\n$(gettext "Start connection"): $url_in ...\n\n"
}


function set_temp_proxy {
    (( $# )) &&
	echo $@ >> "$path_tmp"/proxy
    new_ip_proxy
    get_language
    print_c 4 "$(gettext "Temporary proxy enabled")"
    touch "$path_tmp"/temp-proxy
}

function unset_temp_proxy {
    if [ -f "$path_tmp"/temp-proxy ]
    then
	get_language
	rm -f "$path_tmp"/temp-proxy "$path_tmp"/proxy
	noproxy
	print_c 4 "$(gettext "Temporary proxy disabled")" 
    fi
}

