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

function init_log {
    if [ -z "$log" ]
    then
	echo "$(eval_gettext "\$name_prog file log"):" > $file_log
	log=1
    fi
    echo >> $file_log
    date >> $file_log
}

function _log {
    get_language
    local color_code=3 no_filelog
    
    [ -n "$file_in" ] &&
	msg_file_in=" $file_in"
    
    case $1 in
	1)
	    msg=$(eval_gettext "File\$msg_file_in already present in \$PWD: \$url_in will not be processed.")
	    set_link - "${url_in}"
	    ;;
	2)
	    [ -n "$errMsg" ] &&
		errMsg=":
$errMsg"
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in not available, try again later \${errMsg}")"
	    [ -z "$file_in" ] && msg+="
$(gettext "The file name is missing")"

	    [ -n "$url_in_file" ] && msg_url_in_file=": $url_in_file"
	    url "$url_in_file" || msg+="
$(gettext "No valid url was found")$msg_url_in_file"

	    ;;
	3)
	    msg="$url_in --> $(gettext "Incorrect link or file not available")" 
	    set_link - "$url_in"
	    rm -f "$path_tmp"/"$file_in"_stdout.* "$path_tmp"/filename_"$file_in".txt
	    ;;
	4)
	    msg="$(eval_gettext "The\$msg_file_in file exceeds the size allowed by the server for free download") (link: $url_in)"
	    set_link - "$url_in"
	    ;;
	5)
	    msg="$(gettext "Connection interrupted: try again later")"
	    ;;
	6)
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in too large for free space in \$PWD on \$dev")"
	    print_c 3 "$msg"
	    echo "$msg" >> $file_log
	    exit
	    ;;
	7)
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in already in download") (${url_out[$i]})"
	    ;;
	8)
	    msg="$url_in --> $(gettext "Incorrect link or file not available")
$(gettext "Error downloading the video HTML page. Check that the URL has been entered correctly or that the video is not private.")"
	    set_link - "$url_in"
	    ;;
	9)
	    msg="$url_in --> $(gettext "Title of HTML page not found. Check the URL")."
	    set_link - "$url_in"
	    ;;
	10)
	    msg="$url_in --> $(gettext "Signature of video not found")"
	    ;;
	11)
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in downloadable only by users \"Premium\" or registered")"
	    set_link - "$url_in"
	    ;;
	12)
	    if [ -n "$2" ]
	    then
		msg="$2 --> $(eval_gettext "It is not a valid URL for \$name_prog")
"
	    else
		msg=$(gettext "URL not found")
	    fi
	    set_link - "$2"
	    ;;
	13)
	    msg="$url_in --> $(eval_gettext "The\$msg_file_in file will not be downloaded, because it matches to the regex"): $no_file_regex"
	    set_link - "$url_in"
	    ;;
	14)
	    msg="$url_in --> $(eval_gettext "The\$msg_file_in file will not be downloaded, because it does not match the regex"): $file_regex"
	    set_link - "$url_in"
	    ;;
	15)
	    msg="$url_in --> $(gettext "The link will not be processed, because it matches to the regex"): $no_url_regex"
	    set_link - "$url_in"
	    ;;
	16)
	    msg="$url_in --> $(gettext "The link will not be processed, because it does not matche to the regex"): $file_regex"
	    set_link - "$url_in"
	    ;;
	17)
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in still in transfer and not yet available: try again in a few hours")"
	    # set_link - "$url_in"
	    ;;
	18)
	    msg="$url_in --> $(eval_gettext "Unsupported resume: download of the\$msg_file_in file may end incomplete")"
	    ;;
	19)
	    msg="$url_in --> $(gettext "Unsupported download: user age control")"
	    set_link - "$url_in"
	    ;;
	20)
	    msg="$url_in --> $(gettext "Unsupported download: install") youtube-dl"
	    set_link - "$url_in"
	    ;;
	21)
	    msg="$url_in --> $(eval_gettext "Download supported by youtube-dl, started but not managed by \$PROG")"
	    set_link - "$url_in"
	    ;;
	22)
	    msg=$(eval_gettext "The \$i segment is missing: recovery attempt with Wget extracting the URL from a temporary file")
	    unset break_loop
	    ;;
	23)
	    msg=$(eval_gettext "Operation failed because \$dep is not installed")
	    ;;
	
	24)
	    msg=$(gettext "The operation could not be completed: the temporary file for segment recovery is missing")
	    unset break_loop
	    ;;
	25)
	    msg=$(eval_gettext "Reached the download limit for your IP address or account (link: \$url_in): try --proxy or --reconnect")
	    no_msg=true
	    ;;
	26)
	    msg="$url_in --> $(gettext "Connection to the IRC server failed: incorrect address or connection or file not available")"
	    ;;
	27)
	    msg="<< $notice [link: $url_in]"
	    ;;
	28)
	    msg="$url_in --> $(gettext "Another file is being downloaded from the same source, I will try again later")"
	    ;;
	29)
	    msg="<< $notice [link: $url_in]"
	    set_link - "$url_in"
	    ;;
	30)
	    msg="$url_in --> $(eval_gettext "File\$msg_file_in not available, try again later: I delete it from the queue")"
	    set_link - "$url_in"
	    ;;
	31)
	    msg=$(gettext "Internet connection not available: exit")
	    ;;
	32)
	    msg="$url_in --> $(gettext "Service temporarily not supported: request a developer intervention")"
	    set_link - "$url_in"
	    ;;
	33)
	    msg="$url_in --> $(gettext "Paused for") $(seconds_to_human $2)"
	    ;;
	34)
	    msg="$(gettext "Redirection"): $url_in --> $2"
	    color_code=4
	    ;;
	35)
	    msg="$url_in --> $(gettext "Unsupported download: install") phantomjs"
	    set_link - "$url_in"
	    ;;
	36)
	    msg="$url_in --> $(gettext "Unsupported download: enter the captcha code using a web browser")"
	    set_link - "$url_in"
	    ;;
	37)
	    msg="$url_in --> $(gettext "The service detects the use of AdBlock or software such as Kodi/XBMC/TV BOX (like ZigzagDownLoader).") 
$(gettext "Currently, ZDL is not able to download the requested file, I remove the link from the queue.")"
	    set_link - "$url_in"
	    ;;
	38)
	    msg="$url_in --> $(gettext "Unsupported service: use the web browser to resolve the extraction of the file URL")"
	    set_link - "$url_in"
	    ;;
	39)
	    msg="$url_in --> $(gettext "Your IP address has been banned by the server: the file cannot be reached via this link")" 
	    set_link - "$url_in"
	    ;;
	40)
	    msg=$(gettext "Unable to start the GUI: yad must be installed")
	    ;;
	41)
	    msg="$url_in --> $(gettext "FFMpeg/AvConv is not configured for libxml2")" 
	    set_link - "$url_in"
	    ;;
	42)
	    msg="$url_in --> $(gettext "FFMpeg/AvConv is not installed")" 
	    set_link - "$url_in"
	    ;;
	43)
	    msg="$url_in --> $(gettext "Duration of the unrecorded Live Stream: repeat the programming (the link is deleted from the queue)")" 
	    set_link - "$url_in"
	    ;;
	44)
	    msg="$url_in --> $(gettext "Wait set to non-premium users, try again later")" 
	    no_filelog=true
	    ;;
    esac
    
    if [ -z "$break_loop" ] 
    then
	[ -z "$no_filelog" ] && {
	    init_log
	    echo -e "$msg" >> $file_log
	}
	unset no_filelog
	print_c $color_code "%s" "$msg"

	[[ ! "$1" =~ ^(12|18|34)$ ]] && break_loop=true
    fi
}
