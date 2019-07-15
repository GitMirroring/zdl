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

# path_usr="/usr/local/share/zdl"

TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=zdl
export TEXTDOMAINDIR
export TEXTDOMAIN

source /usr/bin/gettext.sh

source $path_usr/docs/help.sh
source $path_usr/config.sh
source $path_usr/config_manager.sh

source $path_usr/libs/core.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/DLstdout_parser.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/extension_utils.sh
source $path_usr/libs/login.sh
source $path_usr/libs/ip_changer.sh
source $path_usr/libs/log.sh
source $path_usr/libs/post_processor.sh
source $path_usr/libs/ffmpeg_utils.sh

source $path_usr/ui/widgets.sh
source $path_usr/ui/ui.sh
source $path_usr/gui/gui.sh
