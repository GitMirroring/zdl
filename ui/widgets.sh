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

#### layout

[[ "$(tty)" =~ tty ]] &&
    background=tty

if [ "$installer_zdl" == "true" ]
then
    source "ui/colors-${background}.awk.sh"
else
    source "$path_usr/ui/colors-${background}.awk.sh"
fi

init_colors
[ "$background" == "black" ] &&
    Background="$On_Black" && Foreground="$White" ||
	unset Background Foreground

Color_Off="\033[0m${Foreground}${Background}" 

function print_case {
    [[ "$2" ]] &&
	declare -n ref="$2" ||
	    return
    
    case "$1" in
	0)
	    ref=""
	    ;;
	1)
	    ref="$BGreen" 
	    ;;
	2)
	    ref="$BYellow"
	    ;;	
	3)
	    ref="$BRed" 
	    ;;	
	4)
	    ref="$BBlue"
	    ;;	
	5)
	    ref="$Color_Off"
	    ;;	
    esac
}

function print_filter {
    local log filter
    
    if [[ "$PWD" =~ "$path_tmp" ]]
    then
	filter=print_filter_output
	log="${gui_log#*\/}"
    else
    	filter="$path_tmp"/print_filter_output
	log="$gui_log"
    fi

    if [ -f "$log" ]
    then
	if test deamon_filter == true
	then
    	    printf "$@" > "$filter"
    	    sanitize_text <"$filter" >>"$log" 
	else
    	    printf "$@" | tee "$filter"
    	    sanitize_text <"$filter" >>"$log" 
	fi
    else
    	printf "$@"
    fi
}

function print_c {
    local case
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1" case
	shift
	local text="$1"
	shift
	print_filter "${case}${text}${Color_Off}\n" "$@"

    elif [ "$this_mode" == daemon ]
    then
	daemon_filter=true

	print_case "$1" case
	shift
	local text="$1"
	shift
	print_filter "${case}${text}${Color_Off}\n" "$@"
    fi
}

function print_C {
    ## print_c FORCED
    print_case "$1" case
    shift

    local text="$1"
    shift
    
    printf "${case}${text}${Color_Off}\n" "$@"
}

function print_r {
    local case text
    
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1" case
	shift
	text="$1"
	shift
	#printf ?
	print_filter "\r${case}${text}${Color_Off}" "$@"
	
    elif [ "$this_mode" == daemon ]
    then
	daemon_filter=true
	
	print_case "$1" case
	shift
	text="$1"
	shift
	print_filter "\r${case}${text}${Color_Off}" "$@"

    fi
}

function sprint_c {
    local case text
    
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1" case
	shift
	text="$1"
	shift

	#printf ?
	print_filter "${case}${text}${Color_Off}" "$@"
	
    elif [ "$this_mode" == daemon ]
    then
	daemon_filter=true
	
	print_case "$1" case
	shift
	text="$1"
	shift
	print_filter "${case}${text}${Color_Off}" "$@"
    fi
}

function print_header { # $1=label ; $2=color ; $3=header pattern; $4=columns
    local text line hpattern color columns
    
    color="$1"
    shift
    
    hpattern="$1"
    [ -z "$hpattern" ] && hpattern="\ "
    shift
    
    text="$1"
    [ -n "$text" ] && text=" $text " 
    shift

    columns="$1"
    [ -z "$columns" ] && columns=$(stty size | cut -d' ' -f2)
    shift
    
    eval printf -v line "%.0s${hpattern}" {1..$(( columns-${#text} ))}

    [ "$this_mode" == daemon ] &&
	daemon_filter=true

    print_filter "${color}%s${line}${Color_Off}" "${text}" "$@"
}

function separator- {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	if [[ "$1" =~ ^([0-9]+)$ ]]
	then
	    print_header "$BBlue" "─" "" $1
	    echo -ne "${BBlue}┴"
	    print_header "$BBlue" "─" "" $((COLUMNS-$1-1))

	else
	    print_header "$BBlue" "─" ""
	    print_c 0 ""
	fi
    fi
}

function fclear {
    if [ "$1" == help ] ||
           ( [ -z "$already_clean" ] && show_mode_in_tty "$this_mode" "$this_tty" )
    then
	echo -ne "\033c${Color_Off}\033[J"

    else
	unset already_clean
	export already_clean
    fi
    rm -f "$path_tmp"/no-clear-lite
}

function cursor {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	stato=$1
	case $stato in
	    off)
		#echo -en "\033[?30;30;30c"
		stty -echo

		command -v setterm &>/dev/null &&
		    setterm -cursor off
		;;
	    on)
		#echo -en "\033[?0;0;0c"
		stty echo

		command -v setterm &>/dev/null &&
		    setterm -cursor on
		;;
	esac
    fi
}


function header_z {
    local title="$1"
    local menu="$2"
    local force="$3"
    
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	    [ -n "$force" ]
    then
	cursor off
	
	(( "$#" == 0 )) && {
	    text_start="$name_prog ($prog)"
	    text_end="$(zclock)"
	} || {
	    text_start="$title"
	    text_end="$menu"
	}
	eval printf -v text_space "%.0s\ " {1..$(( $COLUMNS-${#text_start}-${#text_end}-3 ))}
	print_header "$On_Blue" "" "$text_start$text_space$text_end" 
	print_c 0 ""
    fi
}

function header_box {
    local text="$1"
    shift
    
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	    [ -n "$redirected_link" ]
    then
	print_header "${Black}${On_White}" "─" "$text" "$@"

    elif [ "$this_mode" == daemon ]
    then
	daemon_filter=true
	print_header "${Black}${On_White}" "─" "$text" "$@"
    fi
}

function header_box_interactive {
    local text="$1"
    shift

    print_header "$Black${On_White}" "─" "$text" "$@"
    print_c 0 ""
}

function header_dl {
    local text="$1 "
    shift

    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	print_header "$White${On_Blue}" "" "$text" "$@"
	print_c 0 ""
    fi
}

function pause_msg {
    	echo
	print_header "$On_Blue$BWhite" "\<" ">>>>>>>> $(gettext "<Return> to continue")"
	print_c 0 ""
}

function pause {
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	    [ "$1" == "force" ]                  ||
	    [ "$redir_lnx" == true ]             ||
	    [ -n "$redirected_link" ]
    then
        pause_msg
	cursor off
	read -e
	cursor on
    fi
}

function xterm_stop {
    local res
    
    if [ "$1" == "force" ] ||
	   ( show_mode_in_tty "$this_mode" "$this_tty" &&
		   [ -z "${pipe_out[*]}" ]             ||
		       [ -n "$redirected_link" ] )
    then
	print_header "$On_Blue$BWhite" "\<" ">>>>>>>> $(gettext "<Return> to exit")"
	echo -ne "\n"
	read -s
    fi
}

function zclock {
    week=( "dom" "lun" "mar" "mer" "gio" "ven" "sab" )
    echo -n -e "$(date +%R) │ ${week[$( date +%w )]} $(date +%d·%m·%Y)"
}

function header_lite {
    echo -en "\033[1;0H"
    local pwd_size=$((COLUMNS - 35))
    local pwd_resized="${PWD:0:$pwd_size}"
    header_z "ZigzagDownLoader in $pwd_resized" "│ help: M-h" $1
    print_header
}

function clear_lite {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	spaces=$(((LINES-i-3) * COLUMNS))
	eval printf "%.0s\ " {1..$spaces}

	touch "$path_tmp"/no-clear-lite
    fi
}

function quit_clear {
    case "$this_mode" in
	lite)
	    fclear
	    ;;
    esac
}

