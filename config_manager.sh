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

function colorize_values {
    print_case "$1" bg_color
    local txt="$2"
    declare -n ref="$3"
    
    txt="${txt//\(/\($BBlue}"
    txt="${txt//|/$bg_color|$BBlue}"
    txt="${txt//\)/$bg_color\)}"

    ref="$bg_color$txt$Color_Off"
}

function check_read {
    local input
    if [ -z "$1" ]
    then
	#print_c 2 "Nessun valore inserito: vuoi cancellare il valore precedente? (sì|*)"
	local res
	colorize_values 2 "$(gettext "No value entered: do you want to delete the previous value? (yes|*)")" res
	echo -e "$res"
	input_text input
	
	if [[ "$input" =~ (sì|yes) ]]
	then
	    return 0

	else
	    return 1
	fi
    fi
    return 0
}

function configure_key {
    opt=$1
    if [[ "$opt" =~ ^[0-9]+$ ]] && 
	   (( $opt > 0 )) && 
	   (( $opt <= ${#key_conf[*]} ))
    then 
	(( opt-- ))
	header_box "$(gettext "Enter the new value")" #"Inserisci il nuovo valore"

	if [ "${key_conf[$opt]}" == reconnecter ]
	then
	    extra_string=" [$(gettext "complete and valid path")]" #path completo e valido
	fi
	local label
	colorize_values 2 "${string_conf[$opt]}" label 
	echo -e "$label ($(gettext "name"): ${BRed}${key_conf[$opt]}${Color_Off})$extra_string:"

	input_text new_value
	
	check_read "$new_value" &&
	    if [[ "${key_conf[$opt]}" =~ (reconnecter|player|editor) ]] &&
		   ! command -v ${new_value%% *} >/dev/null
	    then
		printf "${BRed}%s" "$(gettext "Reconfiguration failed: non-existent program")${extra_string}$Color_Off"
		pause

	    else
		set_item_conf ${key_conf[$opt]} "$new_value"
	    fi
	
	touch "$path_conf/updated"
    fi
}

function show_conf {
    local res_color
    source "$file_conf"
    
    header_box "$(gettext "Current configuration")"
    for ((i=0; i<${#key_conf[*]}; i++))
    do       
	eval_echo=$(eval echo \$${key_conf[$i]})
	colorize_values 5 "${string_conf[$i]}" res_color
	printf "%b %+4s %b│  $res_color:${BGreen} $eval_echo\n" "${BBlue}" "$(( $i+1 ))" "$Color_Off"
    done
}

function configure {
    this_mode="configure"
    start_mode_in_tty "$this_mode" "$this_tty"
    local res_color intro
    
    while true
    do
	fclear
	header_z
	header_box "$(gettext "Settings")"

	printf "   ${BBlue} 1 ${Color_Off}│  %s\n   ${BBlue} 2 ${Color_Off}│  %s\n   ${BBlue} 3 ${Color_Off}│  %s\n   ${BBlue} q ${Color_Off}│  %s\n" \
	       "$(gettext "Change the configuration")" \
	       "$(gettext "Reset the web interface account (socket account)")" \
	       "$(gettext "Manage hosting service accounts")" \
	       "$(gettext "Quit")"
	
	colorize_values 2 "$(gettext "Select an option") (1|2|3|q)" res_color
	echo -e "\n$res_color"
	
	cursor off
	read -s -n1 option_0
	cursor on
	echo -en "\r \r"
	case $option_0 in
	    1)
		while :
		do
		    get_conf

		    fclear
		    header_z
		    header_box "$(gettext "ZigzagDownLoader configuration")"
		    
		    intro="$(eval_gettext "The configuration consists of \${BRed}names\${Color_Off} and \${BBlue}values\${Color_Off}.\n\n\${BYellow}For each name, a value can be specified:\${Color_Off}\n- the \${BBlue}available alternative values\${Color_Off}, in blue, can be suggested between the round brackets and separated by the vertical bar\n- the \${BRed}name\${Color_Off} to which the value is assigned is in red\n- \${BBlue}*\${Color_Off} means any value other than the others, even null\n- the current \${BGreen}values recorded\${Color_Off} are in green\n")"

		    echo -e "$intro"
		    show_conf

		    printf "\n${BYellow}%s (${BBlue}1-${#key_conf[*]}${BYellow} | ${BBlue}q${BYellow} %s):${Color_Off}\n" \
			   "$(gettext "Select the default item to edit")" \
			   "$(gettext "to go back")"
		    
		    input_text opt
		    
		    [ "$opt" == "q" ] && {
			get_conf
			break
		    }
		    configure_key $opt
		done
		;;

	    2)
		printf "${BYellow}$(gettext "Do you really want to reset the socket account? You can reset it from the web interface (yes|*)"):${Color_Off}\n"
		input_text opt
		
		if [[ "$opt" =~ (yes|sì) ]]
		then
		    rm -f "$path_conf"/.socket-account
		fi
		;;
	    3)	
		configure_accounts
		;;

	    q) 	echo -e -n "\e[0m\e[J"
		fclear
		exit
		;;
	esac
    done
}

function configure_accounts {
    ##
    ## esempio per implementare il login per nuovi servizi di hosting:
    ##
    # while true; do
    # 	print_c 2 "Servizi di hosting abilitati per l'uso di account:"
    # 	echo -e "\t1) easybytez" #\n\t2) uload\n\t3) glumbouploads\n"
    # 	print_c 2 "Scegli il servizio (1):"
    # 	cursor off
    # 	read -n 1 option_1
    # 	cursor on
    # 	case $option_1 in
    # 	    1)
    # 		host="easybytez"
    # 		break
    # 		;;
    # 	    2)
    # 		host="uload"
    # 		break
    # 		;;
    # 	    3)	
    # 		host="glumbouploads"
    # 		break
    # 		;;
    # 	esac
    # done
    ##
    
    host="easybytez"

    while true
    do
	init_accounts
	
	header_box "$(gettext "Options")" 

	printf "   ${BBlue} 1 ${Color_Off}│  %s\n   ${BBlue} 2 ${Color_Off}│  %s\n   ${BBlue} 3 ${Color_Off}│  %s\n   ${BBlue} q ${Color_Off}│  %s\n" \
	       "$(gettext "Add/edit an account")" \
	       "$(gettext "Delete an account")" \
	       "$(gettext "View account passwords")" \
	       "$(gettext "Return to the main configuration page")" 
	
	cursor off
	read -s -n1 option_2
	echo -e -n "\r \r"
	cursor on
	case $option_2 in
	    1)	##add
		while true
		do
		    ## clean file "$path_conf"/accounts/$host
		    init_accounts

		    header_box "$(gettext "Enter an account for automatic login") ($host)" 

		    echo -e "${BYellow}$(gettext "Username:")${Color_Off}"
		    input_text user
		    
		    if [ -n "$user" ]
		    then
			echo -e "${BYellow}Password ($(gettext "the characters will not be printed")):${Color_Off}"
			read -ers pass
			
			echo -e "${BYellow}$(gettext "Repeat the password (for verification)"):${Color_Off}"
			read -ers pass2

			if [ -n "$pass" ] &&
			       [ "$pass" == "$pass2" ]
			then
			    grep -P "^$user\s.+$" "$path_conf"/accounts/$host &>/dev/null &&
				sed -r "s|^$user\s.+$|$user $pass|g" -i "$path_conf"/accounts/$host ||
				    echo "$user $pass" >>"$path_conf"/accounts/$host
			    
			elif [ "$pass" != "$pass2" ]
			then
			    echo -e "${BRed}$(gettext "Repeat the operation: mismatched passwords")${Color_Off}"
			else
			    echo -e "${BRed}$(gettext "Repeat the operation: missing username or password")${Color_Off}"
			fi
			
			echo -e "${BYellow}$(gettext "Do you want to enter a new account? (y|*)"):${Color_Off}"
			cursor off
			read -s -n1 new_input
			cursor on
			[[ ! "$new_input" =~ ^(s|y)$ ]] && break

		    else
			echo -e "${BRed}$(gettext "No username entered")${Color_Off}"
			pause
			break
		    fi
		done
		;;
	    2)	##remove
		echo -e "${BYellow}$(gettext "Account username to be deleted"):${Color_Off}"
		input_text user
		
		if grep -P "^$user\s.+$" "$path_conf"/accounts/$host &>/dev/null
		then
		    sed -r "s|^$user\s.+$||g" -i "$path_conf"/accounts/$host

		else
		    echo -e "${BRed}$(gettext "No username entered")${Color_Off}"
		    pause
		fi
		;;

	    3)
		init_accounts pass
		pause
		;;
	    q)	##quit
		break
		;;
	esac
    done
}


function show_accounts {
    local accounts
    header_box "$(gettext "Account registered for") $host:"

    read -d '' accounts < "$path_conf"/accounts/$host

    if [ -z "$accounts" ]
    then
	echo -e "${BRed}$(gettext "No username entered")${Color_Off}"
	return 1
    fi
    
    if [ "$1" == "pass" ]
    then
	get_accounts
	((length_user+=4))
	
	printf "${BBlue}%+${length_user}s ${Color_Off}│${BBlue} %s${Color_Off}\n" "Username:" "Password:"
	for ((i=0; i<${#accounts_user[@]}; i++))
	do
	    printf "%+${length_user}s │ %s\n" "${accounts_user[i]}" "${accounts_pass[i]}"
	done

    else
	echo -e "${BBlue}$(gettext "List of registered users"):${Color_Off}"
	awk '{print $1}' <<< "$accounts"
    fi
    return 0
}

function get_accounts {
    unset accounts_user accounts_pass

    if [ -f "$path_conf"/accounts/$host ]
    then
	while read line
	do
	    username=${line%% *}
	    accounts_user+=( "$username" )

	    ((${#username}>length_user)) &&
		length_user="${#username}"
	    
	    accounts_pass+=( "${line#* }" )
	    
	done < "$path_conf"/accounts/$host
    fi
}


function init_accounts {
    mkdir -p "$path_conf"/accounts
    touch "$path_conf"/accounts/$host
    ftemp="$path_tmp/init_accounts"
    awk '($0)&&!($0 in a){a[$0]; print}' "$path_conf"/accounts/$host >$ftemp
    mv $ftemp "$path_conf"/accounts/$host

    fclear
    header_z
    show_accounts $1
    echo
}

