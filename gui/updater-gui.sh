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

. $HOME/.zdl/zdl.conf
prog=zdl
path_tmp=".${prog}_tmp"

path_usr="/usr/local/share/${prog}"

ICON="$path_usr"/webui/icon-32x32.png
TEXT="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD"
IMAGE="$path_usr"/webui/zdl-64x64.png
IMAGE2="$path_usr"/webui/zdl.png
YAD_ZDL=(
    --window-icon="$ICON"
    --borders=5
)


res=($(yad --title="Aggiornamento" \
	   --image="$IMAGE2" \
	   --text="$TEXT\n\nDisponibile un nuovo aggiornamento, scegli cosa fare: $@" \
	   --form \
	   --separator=' ' \
	   --field="Non chiederlo più in questa sessione":CHK FALSE \
	   --button="Rimanda":0 \
	   --button="Aggiorna":1 \
	   "${YAD_ZDL[@]}"))
case "$?" in
    1)
	echo update
	;;
    0)
	echo cancel
	touch /tmp/zdl-skip-update
	
	[ "${res[0]}" == TRUE ] &&
	    touch /tmp/zdl-skip-update-session
	;;
esac

[ -p /tmp/yadpipe-update-zdl ] &&
    echo quit >/tmp/yadpipe-update-zdl
