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


path_usr="/usr/local/share/zdl"
path_conf="$HOME/.zdl"

hosts=$(curl -s "https://www.tubeoffline.com/sitemap.php"  |
	       grep -Po '>[^<>]+</a'                       |
	       sed -r 's|>(.+)<.+|\1|g'                    |
	       tr '[:upper:]' '[:lower:]'                  |
	       tr -d ' ')

n=$(wc -l <<< "$hosts")
hosts=$(head -n $((n - 6)) <<< "$hosts")
tail -n $((n - 6 - 7)) <<< "$hosts" > "$path_conf"/tubeoffline-hosts.txt


