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

TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=zdl
export TEXTDOMAINDIR
export TEXTDOMAIN

source /usr/bin/gettext.sh

function usage {
    echo "$(gettext Usage): ./uninstall_zdl.sh [--purge] [-h|--help]"
}

function try {
    cmdline=( "$@" )
    
    if ! "${cmdline[@]}" 2>/dev/null 
    then	
	if ! sudo "${cmdline[@]}" 2>/dev/null 
	then
	    su -c "${cmdline[@]}" || (
		print_c 3 "$failure: ${cmdline[@]}"
		return 1
	    )
	fi
    fi
}


PROG=ZigzagDownLoader
prog=zdl
BIN="/usr/local/bin"
SHARE="/usr/local/share/zdl"
success="$(gettext "Uninstall complete")" #success="$(gettext "Disinstallazione completata")"
failure="$(gettext "Uninstall failed")" #failure="$(gettext "Disinstallazione non riuscita")"
path_conf="$HOME/.$prog"

option=$1

echo -e "\e[1m$(gettext "Uninstalling") $PROG\e[0m\n" #echo -e "\e[1m$(gettext "Disinstallazione di") $PROG\e[0m\n"

if [ "$option" == "--help" ] ||
       [ "$option" == "-h" ]
then
    usage
    exit

else
    read -p "$(gettext "Do you really want to uninstall ZigzagDownLoader?") [$(gettext "yes")|*]" result #    read -p "$(gettext "Vuoi davvero disinstallare ZigzagDownLoader?") [$(gettext "sì")|*]" result
    
    if [ "$result" == "$(gettext "yes")" ]
    then
	if [ "$option" == "--purge" ]
	then
	    rm -rf $HOME/.zdl
	fi
	try rm -rf "$SHARE" $BIN/zdl $BIN/zdl-xterm
	[ -e /cygdrive ] && rm /zdl.bat
    fi
fi
