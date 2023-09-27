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


function force_dler {
    dler=$downloader_in
    downloader_in="$1"
    ch_dler=1
    if [ "$dler" != "$downloader_in" ]
    then
	print_c 2 "$(gettext "The server does not allow the use of %s: the download will be made with %s")" "$dler" "$downloader_in"
    fi
}


function dler_type {
    case "$1" in
	aria2)
	    type_links=( "${aria2_links[@]}" )
	    ;;
	dcc_xfer)
	    type_links=( "${dcc_zfer_links[@]}" )
	    ;;
	rtmp)
	    type_links=( "${rtmp_links[@]}" )
	    ;;
	youtube-dl)
	    type_links=( "${youtubedl_links[@]}" )
	    ;;
	wget)
	    type_links=( "${wget_links[@]}" )
	    ;;
	no-resume)
	    type_links=( "${noresume_links[@]}" )
	    ;;
	no-check)
	    type_links=( "${no_check_links[@]}" )
	    ;;
	no-check-ext)
	    type_links=( "${no_check_ext[@]}" )
	    ;;
    esac
    
    for h in ${type_links[*]}
    do
	[[ "$2" =~ ($h) ]] && return
    done
    return 1
}

function check_dler_forcing {
    if dler_type "wget" "$url_in"
    then
	force_dler "Wget"

    elif dler_type "aria2" "$url_in"
    then
	if command -v aria2c &>/dev/null
	then
	    force_dler "Aria2"
	fi

    elif dler_type "dcc_xfer" "$url_in"
    then
	force_dler "DCC_Xfer"	

    elif dler_type "youtube-dl" "$url_in"
    then
	if check_youtube-dl
	then
	    force_dler "youtube-dl"
	else
	    _log 20
	fi

    elif dler_type "rtmp" "$url_in"
    then
	if command -v rtmpdump &>/dev/null
	then
	    force_dler "RTMPDump"
    	    url_in_file="http://DOMA.IN/PATH"
	    
	elif command -v curl &>/dev/null
	then
	    force_dler "cURL"
	    url_in_file="http://DOMA.IN/PATH"
	else
#	    print_c 3 "$url_in --> il download richiede l'uso di RTMPDump, che non è installato" | tee -a $file_log
	    print_c 3 "$url_in --> $(gettext "the download requires the use of RTMPDump, which is not installed")" | tee -a $file_log
	    set_link - "$url_in"
	    break_loop=true
	fi
    fi
    
}

function check_axel {
    unset result_ck
    rm -f "$path_tmp"/axel_*_test

    axel -U "$user_agent" -n $axel_parts $headers -o "$path_tmp"/axel_o_test "$url_in_file" -v 2>&1 >> "$path_tmp"/axel_stdout_test &
    pid_axel_test=$!

    test -f "$path_tmp"/axel_stdout_test &&
	read axel_stdout_test < "$path_tmp"/axel_stdout_test

    while [[ ! "$axel_stdout_test" =~ (Starting download|HTTP/[0-9.]+ [0-9]{3} ) ]] &&
	      check_pid $pid_prog
    do
	if ! check_pid $pid_axel_test ||
		(( $loops>40 ))
	then
	    unset loops
	    (( $loops>40 )) && result_ck=1
	    break
	fi
	sleep 0.5
	(( loops++ ))
	
	test -f "$path_tmp"/axel_stdout_test &&
	    read axel_stdout_test < "$path_tmp"/axel_stdout_test
    done
    
    kill -9 $pid_axel_test 2>/dev/null

    test -f "$path_tmp"/axel_stdout_test &&
	read axel_stdout_test < "$path_tmp"/axel_stdout_test

    if [[ "$axel_stdout_test" =~ (Connection gone.|Unable to connect to server|Server unsupported|400 Bad Request|403 Forbidden|Too many redirects) ]] &&
	   [ -z "$result_ck" ]
    then
	result_ck="1"
    else 
	result_ck="0"
    fi

    rm -f "$path_tmp"/axel_stdout_test
    return "$result_ck"
}

function check_wget {
    local pid_countdown
    countdown- 30 &
    pid_countdown=$!

    wget -t3 -T10 -S --spider --user-agent="$user_agent" "$url_in_file" -o "$path_tmp"/wget_checked
    kill -9 $pid_countdown

    test -f "$path_tmp"/wget_checked &&
	read url_checked < "$path_tmp"/wget_checked

    if grep -P '(Remote file does not exist|failed: Connection refused)' "$path_tmp"/wget_checked &>/dev/null
    then
	rm -rf "$path_tmp"/wget_checked 
	return 1
    else
	rm -rf "$path_tmp"/wget_checked 
	return 0
    fi
}

function check_curl {
    local pid_countdown
    countdown- 30 &
    pid_countdown=$!

    url_checked=$(curl -is -U "$user_agent" "$url_in_file" | head -n1)
    kill -9 $pid_countdown
    
    if [[ ! "$url_checked" =~ (HTTP/[0-9.]+ 200) ]]
    then
	return 1
    else
	return 0
    fi
}

function download {
    downwait=6
    if [[ "$downwait_extra" =~ ^[0-9]+$ ]]
    then
	downwait=$((downwait+downwait_extra))
	unset downwait_extra
    fi
    
    get_language_prog

    if ! dler_type "no-check" "$url_in" &&
	    [ -z "$debrided" ]
    then
	if [ "$downloader_in" != "FFMpeg" ] &&
	       ! dler_type "no-resume" "$url_in" &&
	       ! dler_type "rtmp" "$url_in" &&
	       ! dler_type "wget" "$url_in" &&
	       ! dler_type "youtube-dl" "$url_in" &&
               ! check_curl
	then
	    if [[ ! "$url_checked" =~ (HTTP/[0-9.]+ 503) ]]
	    then
                _log 2
		return 1
	    fi
	    if [[ "$url_checked" =~ (HTTP/[0-9.]+ 404) ]]
	    then
		_log 3
		return 1
	    fi
	fi

	if [ "$downloader_in" == "Axel" ] &&
	       ! check_axel
	then
	    force_dler "Wget"
	fi

	if dler_type "no-resume" "$url_in"
	then
	    set_link - "$url_in"
	    _log 18
	fi

    else
	unset debrided
    fi

    case "$downloader_in" in
	DCC_Xfer)
	    unset irc ctcp
	    declare -A ctcp
	    declare -A irc
	    if [[ "$url_in" =~ ^irc:\/\/([^/]+)\/([^/]+)\/([^/]+$) ]]
	    then
		MSG=$(urldecode "${BASH_REMATCH[3]}")
		MSG="${MSG#ctcp}"
		MSG="${MSG#msg}"
		MSG=$(trim "$MSG")
		
		irc=(
		    [host]="${BASH_REMATCH[1]}"
		    [port]=6667
		    [chan]="${BASH_REMATCH[2]}"
		    [msg]="${MSG}"
		    [nick]=$(obfuscate_user) #$(obfuscate "$USER")
		)
	    fi

	    [[ "${irc[host]}" =~ ^(.+)\:([0-9]+)$ ]] &&
		{
		    irc[host]="${BASH_REMATCH[1]}"
		    irc[port]="${BASH_REMATCH[2]}"
		}

            local test_xfer="${irc[msg]##*\|}"
            test_xfer="${test_xfer%% *}"
            test_xfer="$path_tmp/${irc[nick]}${test_xfer}${irc[msg]##*\#}" 
	    rm -f "$test_xfer"
            
	    stdbuf -i0 -o0 -e0 \
		   $path_usr/irc_client.sh "${irc[host]}" "${irc[port]}" "${irc[chan]}" "${irc[msg]}" "${irc[nick]}" "$url_in" "$this_tty" &
	    pid_in=$!
	    echo "$pid_in" >>"$path_tmp/external-dl_pids.txt"

	    while [ ! -f "$test_xfer" ]
	    do
                sleep 0.1
	    done

	    downwait=10
	    file_in=$(head -n1 "$test_xfer")
	    url_in_file=$(tail -n1 "$test_xfer")

	    if [ "$url_in_file" != "${url_in_file#\/}" ]
	    then
		echo -e "____PID_IN____
$url_in
DCC_Xfer
${pid_prog}
$file_in
$url_in_file" >"$path_tmp/${file_in}_stdout.tmp"

	    else
		downwait=0
	    fi

            add_pid_url "$pid_in" "$url_in" "irc-wait"
            
            while check_pid_url "$pid_in" "$url_in" "irc-wait" ||
                    check_pid_url "$(head -n1 "$path_tmp/${file_in}_stdout.tmp")" "$url_in" "irc-wait" #|| ! test -f "$path_tmp/${file_in}_stdout.tmp"
            do
                sleep 0.1
            done

            local wait_lines=7
	;;

	Aria2)
	    if [[ "$url_in_file" =~ ^(magnet:) ]] ||
		   [ -f "$url_in_file" ]
	    then
	    	[ -n "$tcp_port" ] &&
		    opts+=( "--listen-port=$tcp_port" )

		[ -n "$udp_port" ] &&
		    opts+=( '--enable-dht=true' "--dht-listen-port=$udp_port" )

                opts+=( "--seed-time=0" )
                file_in="${file_in%.mkv}"
                file_in="${file_in%.mp4}"
                file_in="${file_in%.mp3}"
                file_in="${file_in%.avi}"
                fileout=( -d "$file_in" )
                
	    elif [ -n "$file_in" ]
	    then		
		fileout=( -o "$file_in" )
		
		if [ -f "$path_tmp"/cookies.zdl ]
		then
		    opts+=( --load-cookies="$path_tmp/cookies.zdl" )
		    
		elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
		then
		    read COOKIES < "$path_tmp"/flashgot_cookie.zdl
		    if [ -n "$COOKIES" ]
		    then
			headers+=( "Cookie:$COOKIES" )
		    fi
		fi

		if [ -n "${headers[*]}" ]
		then
		    for header in "${headers[@]}"
		    do
			opts+=( --header="$header" )
		    done
		fi
		
		opts+=(
		    -U "$user_agent"
		    -k 1M
		    -x $aria2_connections
		    --continue=true
		    --auto-file-renaming=false
		    --allow-overwrite=true              
		    --follow-torrent=false 
		    --human-readable=false
		    --check-certificate=false
		)
	    fi

	    ##################
	    ## -s $aria2_parts
	    ## -j $aria2_parts
	    ##################

	    stdbuf -oL -eL                                   \
		   aria2c                                    \
		   "${opts[@]}"                              \
		   "${fileout[@]}"                           \
		   "$url_in_file"                            \
		   &>>"$path_tmp/${file_in}_stdout.tmp" &

	    pid_in=$!    
		    
	    echo -e "${pid_in}
$url_in
Aria2
${pid_prog}
$file_in
$url_in_file
$aria2_parts" >"$path_tmp/${file_in}_stdout.tmp"
	    ;;

        MegaDL)
            opts=(
                --debug api
                --path "$file_in"
            )
            [ -f "$file_in" ] &&
                rm -f "$file_in"
            mkdir -p "$file_in"

            stdbuf -oL -eL                                   \
		   megadl                                    \
		   "${opts[@]}"                              \
		   "$url_in_file"   2>&1 |
                stdbuf -i0 -o0 -e0 tr -d "\r" &>>"$path_tmp/${file_in}_stdout.tmp" &

            get_command_pid pid_in "megadl.+$file_in"

	    echo -e "${pid_in}
$url_in
MegaDL
${pid_prog}
$file_in
$url_in_file
$file_in_encoded
$(date +%s)
$length_in" >"$path_tmp/${file_in}_stdout.tmp"
            ;;
        
	Axel)
	    [ -n "$file_in" ] &&
		fileout+=( -o "$file_in" )
	
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		export AXEL_COOKIES="$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
	    then
		read COOKIES < "$path_tmp"/flashgot_cookie.zdl
		if [ -n "$COOKIES" ]
		then
		    headers+=( "Cookie:$COOKIES" )
		fi
	    fi

	    if [ -n "${headers[*]}" ]
	    then
		for header in "${headers[@]}"
		do
		    opts+=( -H "$header" )
		done
	    fi

	    opts+=(
		-U "$user_agent"
		-n $axel_parts
	    )

	    
	    stdbuf -oL -eL                                  \
		   axel                                     \
		   "${opts[@]}"                             \
		   "$url_in_file"                           \
		   "${fileout[@]}"                          \
		   >> "$path_tmp/${file_in}_stdout.tmp" &

	    pid_in=$!
	    echo -e "${pid_in}
$url_in
Axel
${pid_prog}
$file_in
$url_in_file
$axel_parts" > "$path_tmp/${file_in}_stdout.tmp"
	    ;;
	
	Wget)
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		COOKIES="$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cfile.zdl ]
	    then
		COOKIES="$path_tmp/flashgot_cfile.zdl"
	    fi

	    if [ -n "$COOKIES" ]
	    then
	    	opts+=( --load-cookies="$COOKIES" )
	    fi

	    if [ -n "${post_data}" ]
	    then
		opts+=( --post-data="${post_data}" )
	    fi

	    if [ -n "$file_in" ]
	    then
		fileout+=( -O "$file_in" )
	    else
		fileout+=( "--trust-server-names" )
	    fi

	    opts+=(
		--user-agent="$user_agent"
		--no-check-certificate
		--retry-connrefused
		-c -nc -k -S       
	    )
	    
            ## -t 1 -T $max_waiting
	    stdbuf -oL -eL                               \
		   wget                                  \
		   "${opts[@]}"                          \
		   "$url_in_file"                        \
		   "${fileout[@]}"                       \
		   -a "$path_tmp/${file_in}_stdout.tmp" &
	    pid_in=$!

	    echo -e "${pid_in}
$url_in
Wget
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"
	    ;;
	
	RTMPDump)
	    if [ -z "$downloader_cmd" ]
	    then
		downloader_cmd="rtmpdump -r \"$streamer\" --playpath=\"$playpath\""
	    fi

	    pid_list_0="$(pid_list_for_prog "rtmpdump")"

	    eval $downloader_cmd -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp" &
	    
	    ## pid_in=$!
	    pid_list_1="$(pid_list_for_prog "rtmpdump")"

	    if [ -z "$pid_list_0" ]
	    then
		pid_in="$pid_list_1"
	    else
		pid_in=$(grep -v "$pid_list_0" <<< "$pid_list_1")
	    fi

	    echo -e "${pid_in}
$url_in
RTMPDump
${pid_prog}
$file_in
$streamer
$playpath
$(date +%s)" > "$path_tmp/${file_in}_stdout.tmp"
	    
	    downwait=10
	    unset downloader_cmd
	    ;;
	
	cURL)
	    if [ -z "$downloader_cmd" ]
	    then
		downloader_cmd="curl \"$streamer playpath=$playpath\""
	    fi

	    pid_list_0="$(pid_list_for_prog "curl")"

	    (
		eval $downloader_cmd -o "$file_in" 2>> "$path_tmp/${file_in}_stdout.tmp" 
		set_link - "$url_in"
	      
	    ) 2>/dev/null &

	    pid_list_1="$(pid_list_for_prog "curl")"

	    if [ -z "$pid_list_0" ]
	    then
		pid_in="$pid_list_1"
	    else
		pid_in=$(grep -v "$pid_list_0" <<< "$pid_list_1")
	    fi

	    echo -e "${pid_in}
$url_in
cURL
${pid_prog}
$file_in
$streamer
$playpath" > "$path_tmp/${file_in}_stdout.tmp"

	    unset downloader_cmd
	    ;;

	FFMpeg)
	    ## URL-FILE.M3U8
	    rm -f "$path_tmp/${file_in}_stdout.tmp"

	    if [ "$livestream_m3u8" == "$url_in" ] ||
                   [ "$livestream_m3u8" == "$url_in_file" ]
	    then
		local livestream_time
		get_livestream_duration_time "$url_in" livestream_time

                nohup $ffmpeg -loglevel info \
		      -i "$url_in_file" \
		      -c copy \
		      -t "$livestream_time" \
		      "${file_in}" \
		      -y &> >( 
		    stdbuf -i0 -o0 -e0 tr '\r' '\n' |
	    	        stdbuf -i0 -o0 -e0 grep -P '(Duration|bitrate=|time=|muxing)' >> "$path_tmp/${file_in}_stdout.tmp" ) &
                pid_in=$!

                # get_command_pid pid_in $ffmpeg ".+$url_in_file.+$file_in"
                
	    elif [ "$youtubedl_m3u8" == "$url_in" ] ||
                     [ "$youtubedl_m3u8" == "$url_in_file" ]
	    then
		# --external-downloader $ffmpeg \
		# --external-downloader-args "-loglevel info" \
                file_in="${file_in%.???}"
                file_in="${file_in%.mp4}"
                file_in="${file_in}.mp4"
		nohup $youtube_dl \
                      --continue \
		      -f best \
		      --hls-prefer-ffmpeg \
		      "$youtubedl_m3u8" -o "${file_in}" &> >(
		    stdbuf -i0 -o0 -e0 tr '\r' '\n' |
	    	        stdbuf -i0 -o0 -e0 grep -P '(Duration|bitrate=|time=|muxing)' >> "$path_tmp/${file_in}_stdout.tmp" ) &
		pid_in=$!
                #old_ffmpeg="$ffmpeg"
                #ffmpeg=youtube-dl
                
	    else
		nohup $ffmpeg -loglevel info -i "$url_in_file" -c copy "${file_in}" -y &> >( 
		    stdbuf -i0 -o0 -e0 tr '\r' '\n' |
	    	        stdbuf -i0 -o0 -e0 grep -P '(Duration|bitrate=|time=|muxing)' >> "$path_tmp/${file_in}_stdout.tmp" ) &
                pid_in=$!
	    fi
            
	    echo -e "$pid_in
$url_in
FFMpeg
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"

	    downwait=$((downwait+10))

            local wait_lines=10
	    ;;

	youtube-dl)
	    ## provvisorio per youtube-dl non gestito	    
	    _log 21
	    echo
	    header_dl "youtube-dl in $PWD"

	    if [ -n "$DISPLAY" ] &&
		   [ ! -e /cygdrive ]
	    then
		xterm -tn "xterm-256color"                                              \
		      -xrm "XTerm*faceName: xft:Dejavu Sans Mono:pixelsize=12" +bdc      \
		      -fg grey -bg black -title "ZigzagDownLoader in $PWD"              \
		      -e "$youtube_dl \"$url_in_file\"" &
		
	    else
		if [ -f "$path_tmp/external-dl_pids.txt" ]
		then
		    while read line_pid
		    do
			kill $line_pid
		    done < "$path_tmp/external-dl_pids.txt" 
		fi
		$youtube_dl "$url_in_file" --newline &>> "$path_tmp/${file_in}_stdout.ytdl" &
 		pid_ytdl=$!
		
		echo -e "${pid_in}
$url_in
youtube-dl
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.ytdl"
		
		echo "$pid_ytdl" >> "$path_tmp/external-dl_pids.txt"
		
		while check_pid $pid_ytdl
		do
		    sleep 2
		    [[ "$this_mode" =~ ^(daemon|lite)$ ]] ||
			print_r 0 "$(tail -n1 "$path_tmp/${file_in}_stdout.ytdl")                                                                        "
		done
		rm -f "$path_tmp/${file_in}_stdout.ytdl"
	    fi
	    ;;
    esac
    
    if [ -n "$user" ] && [ -n "$host" ]
    then
	accounts_alive[${#accounts_alive[*]}]="${user}@${host}:${pid_in}"
	unset user host
    fi
    unset post_data checked headers opts fileout COOKIES header

    get_language
    rm -f "$path_tmp/._stdout.tmp" "$path_tmp/_stdout.tmp"
    
    ## è necessario aspettare qualche secondo
    # countdown- $downwait
    local tmp_lines=0 loop_lines=0
    local connecting="$(gettext "Connecting")"
    ((wait_lines)) || wait_lines=15
    print_c 0 "                      "
    while ((tmp_lines < wait_lines))
    do
        tmp_lines=$(wc -l "$path_tmp/${file_in}_stdout.tmp" | cut -d' ' -f1)
        sleep 1
        check_wait_connecting &&
	    print_r 2 " $connecting ...       "  ||
	        print_r 1 " $connecting . . .     "
        if ((loop_lines >= 30)) ||
               [ ! -f "$path_tmp/${file_in}_stdout.tmp" ]
        then
            kill -9 "$pid_in"
            break
        fi
        check_pid "$pid_prog" || break
        ((loop_lines++))
    done
    print_c 0 "                      "
            
}

