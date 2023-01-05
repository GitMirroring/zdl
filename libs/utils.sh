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

function check_value_in_array {
    local value="$1"
    shift
    declare -a array=( "$@" )
    grep -q --line-regexp "$value" < <(printf "%s\n" "${array[@]}") &&
	return 0 || return 1
}

function get_mime {
    file -b --mime-type "$1"
}

function size_file {
    stat -c '%s' "$1" 2>/dev/null
}

function trim {
    tr -d '\r' <<< $1
}

function urldecode {
    printf '%b' "${1//%/\\x}" 2>/dev/null
}

function htmldecode {
    entity=( '&#232;' '&quot;' '&amp;' '&lt;' '&gt;' '&OElig;' '&oelig;' '&Scaron;' '&scaron;' '&Yuml;' '&circ;' '&tilde;' '&ensp;' '&emsp;' '&thinsp;' '&zwnj;' '&zwj;' '&lrm;' '&rlm;' '&ndash;' '&mdash;' '&lsquo;' '&rsquo;' '&sbquo;' '&ldquo;' '&rdquo;' '&bdquo;' '&dagger;' '&Dagger;' '&permil;' '&lsaquo;' '&rsaquo;' '&euro;' '&#x27;' )

    entity_decoded=( 'è' '"' '&' '<' '>' 'Œ' 'œ' 'Š' 'š' 'Ÿ' '^' '~' ' ' '  ' '' '' '' '' '' '–' '—' '‘' '’' '‚' '“' '”' '„' '†' '‡' '‰' '‹' '›' '€' '_' )

    decoded_expr="$1"
    for i in $(seq 0 $(( ${#entity[*]}-1 )) )
    do
	decoded_expr="${decoded_expr//${entity[$i]}/${entity_decoded[$i]}}"
    done
    echo "$decoded_expr"
}

function htmldecode_regular {
    for cod in $@
    do 
    	printf "\x$(printf %x $cod)"
    done
}

function urlencode {
    char=( '+' '/' '=' ' ' )
    encoded=( '%2B' '%2F' '%3D' '%20' )

    text="$1"
    for i in $(seq 0 $(( ${#char[*]}-1 )) )
    do
	text="${text//${char[$i]}/${encoded[$i]}}"
    done
    echo -n "$text"
}

function urlencode_query {
    local var val t i text
    declare -a char=( '+' '/' '=' ' ' )
    declare -a encoded=( '%2B' '%2F' '%3D' '%20' )
    declare -a text_splitted=( $(split "$1" '&') )

    for t in "${text_splitted[@]}"
    do
        var="${t%%\=*}"
        val="${t#*\=}"
        [ -n "$text" ] && text+="&"
        
        for i in $(seq 0 $(( ${#char[*]}-1 )) )
        do
	    val="${val//${char[$i]}/${encoded[$i]}}"
        done
        text+="${var}=${val}"
    done
    echo "${text%\&}"
}

function add_container {
    local new
    unset new
    container=$(urlencode "$1")
    URLlist=$(curl "http://dcrypt.it/decrypt/paste"  \
		   -d "content=${container}"        |
		     egrep -e "http" -e "://")

    while read line
    do
	new=$(sed -r "s|.*\"(.+)\".*|\\1|g" <<< "$line")
	new=$(sanitize_url "$new")
	
	(( i == 1 )) && url_in="$new"

	echo "$new" >> "$path_tmp"/links_loop.txt &&
	    print_c 1 "$(gettext "New link:") $new" #"Aggiunto URL: $new"

    done <<< "$URLlist"
}

function base36 {
    b36arr=( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
    for i in $(echo "obase=36; $1"| bc)
    do
        echo -n "${b36arr[${i#0}]}"
    done
}

function split {
    local oIFS="$IFS"
    if [[ "$2" ]]
    then
	IFS="$2"
	declare -a splitted=($1)
	for i in ${splitted[*]}
	do echo $i
	done
	IFS="$oIFS"

    else
	sed -r "s|(.{1})|\1\n|g" <<< "$1" 2>/dev/null
    fi
}

function obfuscate {
    local obfs res
    for i in $(split "$1")
    do
	 obfs+=$(char2code "$i")
    done
    obfs=$(( (obfs + obfs - RANDOM) * RANDOM + $(date +%s) ))

    for i in $(split "$obfs")
    do
	res+=$(code2char "10$i")
    done
    printf "%s" "$res"
}

function countdown+ {
    local max=$1
    print_c 2 "$(gettext "Wait %s seconds")" $max
    #"Attendi $max secondi:"
    local k=`date +"%s"`
    local s=0

    while (( $s<$max ))
    do
	if ! check_pid $pid_prog
	then
	    exit
	fi
	sleeping 1
	s=`date +"%s"`
	s=$(( $s-$k ))
	[[ "$this_mode" =~ ^(daemon|lite)$ ]] ||
	    print_c 0 "%d\r" $s
    done 
}

function countdown- {
    local max=$1
    local start=`date +"%s"`
    local stop=$(( $start+$max ))
    local diff=$max
    local this
    
    while (( $diff>0 ))
    do
	if ! check_pid $pid_prog
	then
	    exit
	fi
	this=`date +"%s"`
	diff=$(( $stop-$this ))
	[[ "$this_mode" =~ ^(daemon|lite)$ ]] || {
	    sprint_c 0 "           \r"
	    sprint_c 0 "%d\r" $diff
	}
	sleeping 1
    done
}

function clean_countdown {
    rm -f "$path_tmp"/.wise-code
}

function char2code {
    printf "%d" "'$1"
}

function code2char {
    printf \\$(printf "%03o" "$1" )
}

function parse_int {
    num_based="${1%% *}"
    base=$2
    echo $(( $base#${num_based##0} )) #conversione di $int da base 36 a base decimale
}

function make_index {
    string="$1"
    sed -e s,[^a-zA-Z0-9],,g <<< "$string" 2>/dev/null
}

function scrape_url {
    url_page="$1" 
    
    if url "$url_page"
    then
	print_c 1 "[--scrape-url] $(gettext "connecting"): $url_page" #connessione in corso

	baseURL="${url_page%'/'*}"

	if check_cloudflare "$url_page"
	then
	    get_by_cloudflare "$url_page" html
	    
	else
	    html=$(curl -s -A "$user_agent" "$url_page")
	fi

	if [ -n "$html" ]
	then
	    html=$(tr "\t\r\n'" '   "' <<< "$html"            | 
	     	       grep -Po 'href[\ ]*=[\ ]*[^<>\ #]+'    |
		       grep -Pv "href[\ ]*=[\ ]*[\"\']*\/"    |
		       sed -r "s|href=[\"\']*([^\"]+)[\"\']*.*$|\1|g" 2>/dev/null)
	else
	    return 1
	fi

	while read line
	do
	    [[ ! "$line" =~ ^(ht|f)tp[s]*\:\/\/ ]] &&
		line="${baseURL}/$line"

	    if [[ "$line" =~ "$url_regex" ]]
	    then
		echo "$line"
		if [ -z "$links" ]
		then
		    links="$line"
		else
		    links="${links}\n$line"
		fi
		start_file="$path_tmp/links_loop.txt"
		set_link + "$line"
	    fi
	done <<< "$html" 

	print_c 1 "$(gettext "URL extraction from the web page %s completed")" "$url_page"
	countdown- 3
    fi
}

function check_ext {
    local file_ext="$1"
    file_ext=".${filename##*.}"
    
    if grep -qP "^${file_ext}\s" $path_usr/mimetypes.txt
    then
        return 0

    else
        return 1
    fi
}

function set_ext {
    local filename="$1"
    local ext item
    local url_ext=".${url_in_file##*.}"
    url_ext="${url_ext%%\?*}"    
    
    if grep -qP "^${url_ext}\s" $path_usr/mimetypes.txt
    then
        echo "${url_ext}"
        return 0
    fi
    
    for item in "$filename" "$url_in_file"
    do
	url "$item" &&
	    item="${item%?*}"
	
	test_ext=".${item##*.}"
        test_ext=$(tr '[:upper:]' '[:lower:]' <<< "$test_ext")
    
	if [ -n "$test_ext" ] &&
	       grep -P "^$test_ext\s" $path_usr/mimetypes.txt &>/dev/null
	then
	    echo $test_ext 
	    return 0
	fi
    done

    rm -f "$path_tmp/test_mime"
    
    if [ ! -f "$filename" ] &&
	   url "$url_in_file" &&
	   ! dler_type "rtmp" "$url_in" &&
	   ! dler_type "youtube-dl" "$url_in"
    then
	if [ -f "$path_tmp"/cookies.zdl ]
	then
	    COOKIES="--load-cookies=$path_tmp/cookies.zdl"

	elif [ -f "$path_tmp"/flashgot_cfile.zdl ]
	then
	    COOKIES="--load-cookies=$path_tmp/flashgot_cfile.zdl"
	fi

	if [ -n "${post_data}" ]
	then
	    method_post="--post-data=${post_data}"
	fi

	wget --user-agent="$user_agent"            \
	     -t 3 -T 40                            \
	     $COOKIES                              \
	     $method_post                          \
	     -qO "$path_tmp/test_mime" "$url_in_file" &
	mime_pid=$!

	counter=0
	while ( [ ! -f "$path_tmp/test_mime" ] &&
		    (( counter<10 )) ||
			[[ "$(file --mime-type "$path_tmp/test_mime")" =~ empty ]] ) &&
		  check_pid $mime_pid
	do
	    sleep 0.5
	    ((counter++))
	done
	kill -9 $mime_pid
	mime_type=$(file -b --mime-type "$path_tmp/test_mime")
	rm -f "$path_tmp/test_mime" 
        
    elif [ -f "$filename" ]
    then
	mime_type=$(file -b --mime-type "$filename")
    fi

    if [ -n "$mime_type" ]
    then
	grep "$mime_type" $path_usr/mimetypes.txt | awk '{print $1}' | head -n1
	return 0
	
    else
	return 1
    fi
}

function check_captcha {    
    if [[ "$1" =~ $captcha_services ]] 
    then
	_log 36
	return 1
    fi
}

function replace_url_in {
    local url2chk=$(trim "$1")

    if url "$url2chk"
    then
	if [ "$url2chk" != "$url_in" ]
	then
	    _log 34 "$url2chk"
	    
	    set_link - "$url_in"
	    url_in="$url2chk"
	    set_link + "$url_in"

	    check_captcha "$url_in" ||
		return 1
	fi
	
	return 0
	
    else
	_log 12 "$url2chk"
	return 1
    fi
}

function sanitize_url {
    [[ $2 ]] &&
	declare -n ref="$2"
    data=$(anydownload "$1")
    
    data="${data%%'?'}"
    data="${data%%'+'}"
    data="${data## }"
    data="${data%% }"
    data="${data%'#20%'}"
    data="${data%'#'}"
    data="${data// /%20}"
    data="${data//'('/%28}"
    data="${data//')'/%29}"
    data="${data//'['/%5B}"
    data="${data//']'/%5D}"
    data="${data//'...'/%2E%2E%2E}"

    data="${data//$'\200'}"
    data="${data//$'\223'}"

    data="${data//$'\340'/à}"
    data="${data//$'\341'/á}"
    data="${data//$'\342'/â}"
    data="${data//$'\343'/ã}"
    data="${data//$'\344'/ä}"
    data="${data//$'\345'/å}"
    data="${data//$'\346'/æ}"
    data="${data//$'\347'/ç}"

    data="${data//$'\350'/è}"
    
    data="${data//$'\351'/é}"
    data="${data//$'\352'/ê}"
    data="${data//$'\353'/ë}"
    data="${data//$'\354'/ì}"
    data="${data//$'\355'/í}"
    data="${data//$'\356'/î}"
    data="${data//$'\357'/ï}"

    data="${data//$'\360'/ð}"
    data="${data//$'\361'/ñ}"
    data="${data//$'\362'/ò}"
    data="${data//$'\363'/ó}"
    data="${data//$'\364'/ô}"
    data="${data//$'\365'/õ}"
    data="${data//$'\366'/ö}"
    data="${data//$'\367'/÷}"

    data="${data//$'\370'/ø}"
    data="${data//$'\371'/ù}"
    data="${data//$'\372'/ú}"
    data="${data//$'\373'/û}"
    data="${data//$'\374'/ü}"
    data="${data//$'\375'/ý}"
    data="${data//$'\376'/þ}"
    data="${data//$'\377'/ÿ}"

    if [[ $2 ]]
    then
	ref="$data"
    else
	echo "$data"
    fi
}

function sanitize_file_in {
    local ext ext0

    if [ -z "$file_in" ] &&
	   url "$url_in_file"
    then
	file_in="${url_in_file%%\/}"
	file_in="${file_in##*\/}"
    fi

    file_in="${file_in//$'\200'}"
    file_in="${file_in//$'\223'}"
    file_in="${file_in//$'\340'/à}"
    file_in="${file_in//$'\341'/á}"
    file_in="${file_in//$'\342'/â}"
    file_in="${file_in//$'\343'/ã}"
    file_in="${file_in//$'\344'/ä}"
    file_in="${file_in//$'\345'/å}"
    file_in="${file_in//$'\346'/æ}"
    file_in="${file_in//$'\347'/ç}"

    file_in="${file_in//$'\350'/è}"
    
    file_in="${file_in//$'\351'/é}"
    file_in="${file_in//$'\352'/ê}"
    file_in="${file_in//$'\353'/ë}"
    file_in="${file_in//$'\354'/ì}"
    file_in="${file_in//$'\355'/í}"
    file_in="${file_in//$'\356'/î}"
    file_in="${file_in//$'\357'/ï}"

    file_in="${file_in//$'\360'/ð}"
    file_in="${file_in//$'\361'/ñ}"
    file_in="${file_in//$'\362'/ò}"
    file_in="${file_in//$'\363'/ó}"
    file_in="${file_in//$'\364'/ô}"
    file_in="${file_in//$'\365'/õ}"
    file_in="${file_in//$'\366'/ö}"
    file_in="${file_in//$'\367'/÷}"

    file_in="${file_in//$'\370'/ø}"
    file_in="${file_in//$'\371'/ù}"
    file_in="${file_in//$'\372'/ú}"
    file_in="${file_in//$'\373'/û}"
    file_in="${file_in//$'\374'/ü}"
    file_in="${file_in//$'\375'/ý}"
    file_in="${file_in//$'\376'/þ}"
    file_in="${file_in//$'\377'/ÿ}"
    
    file_in="${file_in## }"
    file_in="${file_in%% }"
    file_in="${file_in// /_}"
    file_in="${file_in//\\}"
    file_in="${file_in//\*}"
    file_in="${file_in//+/_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in//\"/_}"
    file_in="${file_in//[\[\]\(\)]/-}"
    file_in="${file_in//\/}"
    file_in="${file_in##-}"
    file_in="$(htmldecode "$file_in")"
    file_in="${file_in//'&'/and}"
    file_in="${file_in//'#'}"
    file_in="${file_in//';'}"
    file_in="${file_in//\,/_}"
    file_in="${file_in//\:/-}"
    file_in="${file_in//'?'}"
    file_in="${file_in//'!'}"
    file_in="${file_in//'$'}"
    file_in="${file_in//'%20'/_}"
    file_in="$(urldecode "$file_in")"
    file_in="${file_in//'%'}"
    file_in="${file_in//\|}"
    file_in="${file_in//\`}"
    file_in="${file_in//[<>]}"
    file_in="${file_in::180}"
    file_in=$(sed -r 's|^[^0-9a-zA-Z\[\]()]*([0-9a-zA-Z\[\]()]+)[^0-9a-zA-Z\[\]()]*$|\1|g' <<< "$file_in" 2>/dev/null)
    file_in=$(trim "$file_in")

    if ! dler_type "no-check-ext" "$url_in" &&
	    [[ ! "$url_in_file" =~ \.m3u8 ]] &&
            ! check_ext "$file_in"
    then
	ext=$(set_ext "$file_in")

	if [ -z "$ext" ] &&
	       url "$url_in_file" &&
	       [[ "$url_in_file" =~ (\.flv|\.mp4|\.mp3|\.mkv|\.avi)$ ]]
	then
	    ext=${BASH_REMATCH[1]}
	fi               
	
	file_in="${file_in%$ext}$ext"
    fi
}

function link_parser {
    local _domain userpass ext item param
    param="$1"

    # extract the protocol
    parser_proto=$(echo "$param" | grep '://' | sed -r 's,^([^:\/]+\:\/\/).+,\1,g' 2>/dev/null)

    # remove the protocol
    parser_url="${param#$parser_proto}"

    # extract domain
    _domain="${parser_url#*'@'}"
    _domain="${_domain%%\/*}"
    [ "${_domain}" != "${_domain#*:}" ] && parser_port="${_domain#*:}"
    _domain="${_domain%:*}"

    if [ -n "${_domain//[0-9.]}" ]
    then
	[ "${_domain}" != "${_domain%'.'*}" ] && parser_domain="${_domain}"
    else 
	parser_ip="${_domain}"
    fi

    # extract the user and password (if any)
    userpass=`echo "$parser_url" | grep @ | cut -d@ -f1`
    parser_pass=`echo "$userpass" | grep : | cut -d: -f2`
    if [ -n "$pass" ]
    then
	parser_user=`echo $userpass | grep : | cut -d: -f1 `
    else
	parser_user="$userpass"
    fi

    # extract the path (if any)
    parser_path="$(echo $parser_url | grep / | cut -d/ -f2-)"

    if [[ "${parser_proto}" =~ ^(ftp|http) ]]
    then
	if ( [ -n "$parser_domain" ] || [ -n "$parser_ip" ] ) &&
	       [ -n "$parser_path" ]
	then
	    return 0
	fi
    fi
    return 1
}

function url {
    if grep_urls "$1" &>/dev/null
    then
	return 0
    else
	return 1
    fi
}

function grep_urls {
    local input result
    unset input
    result=1
    
    if [ -f "$1" ] &&
	   [ "$(file -b --mime-type "$1")" == 'text/plain' ]
    then
	if [[ "$1" =~ (.+\.m3u8)$ ]]
	then
	    return 0
	fi
	
	input=$(< "$1")

    else
	input="$1"
    fi

    while read line
    do
        if [ -f "$line" ] &&
	       [[ "$line" =~ \.torrent$ ]]
	then
	    echo "$line" 
	    result=0
	fi

    done <<< "$input"

#    grep -P '^(xdcc|magnet|http|https|ftp):\/\/.+$' <<< "$input" &&
    grep -P '(^xdcc://.+|^irc://.+|^magnet:.+|^\b(((http|https|ftp)://?|www[.]*)[^\s()<>]+(?:\([\w\d()]+\)|([^[:punct:]\s]|/)))[-_=.]*)$' <<< "$input" &&
        result=0

    return $result    
}

function file_filter {
    [ -z "$1" ] && return 0
    ## opzioni filtro
    filtered=true
    if [ -n "$no_file_regex" ] &&
	   [[ "$1" =~ $no_file_regex ]]
    then
	_log 13
	return 1
    fi
    if [ -n "$file_regex" ] &&
	   [[ ! "$1" =~ $file_regex ]]
    then
	_log 14
	return 1
    fi
}

function join {
    tr " " "$2" <<< "$1"
}

function dotless2ip {
    local k
    local dotless=$1
    local i=$2
    [ -z "$i" ] && i=3
    
    if ((i == 0))
    then
	ip+=( $dotless )
	join "${ip[*]}" '.'
	return

    else
	k=$((256**i))
	
	ip+=( $((dotless / k)) )
	((i--))
	dotless2ip $((dotless - ip[-1] * k )) $i
    fi
}

function equal_file_size {
    ls -l $1 $2 |
	  awk 'NR==1{a=$5} NR==2{b=$5} 
       END{val=(a==b)?0 :1; exit( val) }'

    [ $? -eq 0 ] &&
	return 0 || return 1
}

function cmp_file {    
    local file1 file2
    read -d '' file1 < "$1"
    read -d '' file2 < "$2"
    if [ "$file1" == "$file2" ]
    then
	return 0
    else
	return 1
    fi
}

function parse_int {
    declare -n ref="$1"
    local val="$2"
    if [[ "$val" =~ [^0-9]*([0-9]+)[^0-9]* ]]
    then
	ref="${BASH_REMATCH[1]}"
	return 0
	
    else
	ref=""
	return 1
    fi
}

function length_to_human {
    local length_K=$(($1/1024))
    local length_M=$((length_K/1024))
    if ((length_M > 0))
    then
	printf "%.2fMB" $length_M
	
    elif ((length_K > 0))
    then
	printf "%.2fKB" $length_K
	
    else
	echo "$length_B B"
    fi
}

function seconds_to_human {
    if [[ "$1" =~ ^([0-9]+)$ ]]
    then
	local seconds="$1"
	local minutes=$((seconds/60))
	local hours=$((minutes/60))
	minutes=$((minutes - (hours * 60) ))
	seconds=$((seconds - (minutes * 60) - (hours * 60 * 60) ))

	if ((hours > 0))
	then
	    echo -n "$hours ore, "
	fi

	if ((hours > 0)) || ((minutes > 0))
	then
	    echo -n "$minutes minuti e "
	fi

	echo -n "$seconds secondi"
	
	return 0 
    else
	echo -n "tempo indefinito"
	return 1
    fi
}

function human_to_seconds {
    local hours="${1##0}" \
	  minutes="${2##0}" \
	  seconds="${3##0}"
	  
    if [[ "$1" =~ ^([0-9]+)$ &&
	      "$2" =~ ^([0-9]+)$ &&
	      "$3" =~ ^([0-9.]+)$ ]]
    then
	echo $(( seconds + (minutes * 60) + (hours * 3600) ))
	return 0
	
    else
	return 1
    fi
}

function sanitize_text {
    if [[ $1 ]]
    then
	sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" <<< "$1" |
	    sed -r "s|([─]+)|\n|g"
    else
	stdbuf -i0 -o0 -e0 sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" |
	    stdbuf -i0 -o0 -e0 sed -r "s|([─]+)|\n|g"
    fi
}
