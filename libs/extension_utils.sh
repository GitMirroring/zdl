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

#### hacking web pages

function get_tmps {
    wget -t 1 -T $max_waiting                    \
         --no-check-certificate                  \
         --retry-connrefused                     \
         --save-cookies="$path_tmp"/cookies.zdl  \
         --user-agent="$user_agent"              \
         -qO "$path_tmp/zdl.tmp"                 \
         "$url_in"  
}

function input_hidden {
    if [ -n "$1" ]
    then
        unset post_data datatmp data value name post
        if [ -f "$1" ]
        then
            datatmp=$(grep -P "input.+type\=.+hidden" < "$1")
        else
            datatmp=$(grep -P "input.+type\=.+hidden" <<< "$1")
        fi

        for ((i=1; i<=$(wc -l <<< "$datatmp"); i++))
        do
            data=$(head -n"${i}" <<< "$datatmp" |tail -n1 |grep name)
            name=${data#*name=}
            name=${name#\"}
            name=${name#\'}
            name=${name%%\"*}
            name=${name%%\'*}

            value=${data#*value=}
            value=${value#\"}
            value=${value#\'}
            value=${value%%\"*}
            value=${value%%\'*}

            value=$(htmldecode "$value")
            
            value="${value//'&'/%26}"

            value="${value//'&#x27;'/\'}"
            
            [ -n "$name" ] && eval postdata_$name=\"${value}\"
            
            if [ "$name" == "realname" ] || [ "$name" == "fname" ] ## <--easybytez , sharpfile , uload , glumbouploads
            then 
                file_in="${value}"
            fi

            if [ -z "$post_data" ]
            then
                post_data="${name}=${value}"
            else
                post_data="${post_data}&${name}=${value}"
            fi
        done
    fi
}

function pseudo_captcha { ## modello d'uso in ../extensions/rockfile.sh
    while read line
    do
        i=$(sed -r 's|.*POSITION:([0-9]+)px.+|\1|g' <<< "$line")
        captcha[$i]=$(htmldecode_regular "$(sed -r 's|[^>]+>&#([^;]+);.+|\1|' <<< "$line")")
    done <<< "$(grep '&#' <<< "$1" |
            sed -r 's|padding-left|\nPOSITION|g' |
            grep POSITION)"

    tr -d ' ' <<< "${captcha[*]}"
}

function simple_captcha {
    local fout=$(mktemp) out

    for degree in $(seq 5 20)
    do    
        convert -monochrome -rotate $degree "$1" "$fout"
        out=$(tesseract "$fout" stdout | head -n1)

        if [[ "$out" =~ ^([0-9]{6})$ ]]
        then
            echo "$out"
            return 0
        fi
    done
    return 1
}

function tags2vars {
    if [[ -n $1 ]]
    then
         eval $(sed -r 's|<([^/<>]+)>([^/<>]+)</([^<>]+)>|\1=\2; |g' <<< "$1")
    fi
}


function base64_decode {
    arg1=$1
    arg2=$2
    var_4=${arg1:0:$arg2}
    var_5=${arg1:$(( $arg2+10 ))} 
    arg1="$var_4$var_5"
    var_6='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    var_f=0
    var_10=0
    while true
    do
        var_a=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 ))
        (( var_f++ ))
        var_b=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
        (( var_f++ ))
        var_c=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
        (( var_f++ ))
        var_d=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
        (( var_f++ ))
        var_e=$(( $var_a << 18 | $var_b << 12 | $var_c << 6 | $var_d ))
        var_7=$(( $var_e >> 16 & 0xff ))
        var_8=$(( $var_e >> 8 & 0xff ))
        var_9=$(( $var_e & 0xff ))
        if (( $var_c == 64 ))
        then
            var_12[$(( var_10++ ))]=$(code2char $var_7)
        else
            if (( $var_d == 64 ))
            then
                var_12[$(( var_10++ ))]=$(code2char $var_7)$(code2char $var_8)
            else
                var_12[$(( var_10++ ))]=$(code2char $var_7)$(code2char $var_8)$(code2char $var_9)
            fi
        fi
        (( $var_f>=${#arg1} )) && break
    done
    sed -r 's| ||g' <<< "${var_12[*]}"
}

function simply_debrid {
    local url="$1"

    print_c 2 "$(gettext "Extracting the URL of the file using https://simply-debrid.com ...")"
    
    local html=$(wget --keep-session-cookies                                 \
                      --save-cookies="$path_tmp/cookies.zdl"                 \
                      --post-data="link=$url&submit=GENERATE TEXT LINKS"     \
                      "https://simply-debrid.com/generate#show"              \
                      -qO- -o /dev/null)

    local html_url='http://simply-debrid.com/'$(grep -Po 'inc/generate/name.php[^"]+' <<< "$html")
    
    url "$html_url" &&
        print_c 4 "... $html_url ..."

    wget -qO /dev/null 'https://simply-debrid.com/inc/generate/adb.php?nok=1' \
         --keep-session-cookies --save-cookies="$path_tmp/cookies.zdl"
    
    json_data=$(curl -b "$path_tmp/cookies.zdl"     \
                     "$html_url"                 |
                       sed -r 's|\\\/|/|g')
    
    if [[ "$json_data" =~ '"error":0' ]]
    then
        file_in=$(sed -r 's|.+\"name\":\"([^"]+)\".+|\1|' <<< "$json_data")
        url_in_file=$(sed -r 's|.+\"generated\":\"([^"]+)\".+|\1|' <<< "$json_data")
        url_in_file=$(sanitize_url "$url_in_file")

        if url "$url_in_file" &&
                [ -n "$file_in" ]
        then
            (( axel_parts>4 )) && axel_parts=4
            debrided=true
        fi

    elif [[ "$url_in" =~ (nowdownload) ]]
    then
        print_c 3 "$PROG $(gettext "failed to acquire the URL of the file using simply-debrid: try it manually from the page https://simply-debrid.com/generate#show")\n"
        set_link - "$url_in"
        break_loop=true
        breakloop=true
    
    else
        _log 11
        print_c 3 "$(gettext "Please try again by changing the IP address (it will be extracted using https://simply-debrid.com)\\nYou can use the --reconnect or --proxy options")" |
            tee -a $file_log

        breakloop=true
    fi              
}


function php_aadecode {
    php $path_usr/libs/aadecoder.php "$1"
}

function aaextract {
    ## codificato con php-aaencoder, ma non lo usiamo per decodificarlo

    encoded="window = this;"
    encoded+=$(grep '\^' <<< "$1" |
                      sed -r 's|<\/script>||g') 

    encoded+='for(var index in window){window[index];}'

    if [ -d /cygdrive ]
    then
        $nodejs -e "console.log($encoded)"

    else
        $nodejs $evaljs "$encoded"
    fi
}

function nodejs_eval {
    local jscode
    
    if [ -f "$1" ]
    then
        jscode="$(cat "$1")"

    else
        jscode="$1"
    fi

    result=$($nodejs $evaljs "eval($jscode)"  2>&1)

    if [ -z "$result" ]
    then
        result=$($nodejs $evaljs "$jscode" 2>&1)
    fi
       
    if [ -d /cygdrive ] &&
           [ -z "$result" ]
    then
        result=$($nodejs -e "console.log($jscode)") 
    fi

    echo "$result"
}

function unpack {
    local jscode

    jscode=$(grep -P 'eval.+p,a,c,k,e' <<< "$1" |
             sed -r 's|.*eval||g')

    nodejs_eval "${jscode}"    
}

function packed {
    if [ "$#" == 1 ]
    then
        ## accetta come parametro il pezzo di codice "eval...packed..."
        packed_args "$1"
        p=$(sed -r 's@(.+)@\U\1@g' <<< "$code_p") ## <-- va convertito con base36, quindi servono le lettere maiuscole
        a="$code_a"
        c="$code_c"

        IFS="|"
        k=( "$code_k" )
        unset IFS

    else
        p=$(sed -r 's@(.+)@\U\1@g' <<< "$1") ## <-- va convertito con base36, quindi servono le lettere maiuscole
        a=$2
        c=$3

        IFS="|"
        k=( $4 )
        unset IFS

        e=$5 #non esiste
        d=$6 #non esiste
    fi

    while [ "$c" != 0 ]
    do
         (( c-- ))
         int=$(base36 $c)
         if [ -n "${k[$c]}" ] &&
                [ "${k[$c]}" != 0 ]
         then
             p=$(sed "s@\\b$int\\b@${k[$c]}@g" <<< "$p")
             unset int
         fi
    done
    echo "$p"
}

function packed_args {
    code="${1#*\}\(\'}"
    code="${code%%\'.split*}"
    code_p=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\1@g" <<< "$code") 
    code_a=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\2@g" <<< "$code") 
    code_c=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\3@g" <<< "$code") 
    code_k=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\4@g" <<< "$code") 
}

function get_title {
    html="$1"
    if [ -f "$html" ]
    then
        html=$(cat "$html")
    fi

    grep -P '<[Tt]{1}itle[^>]*>' <<< "$html" |
        sed -r 's|.*<[Tt]{1}itle[^>]*>([^<]+)<.+|\1|g'
}

function set_try_counter {
    (( try_counter[$1]++ ))
}

function get_try_counter {
    if [ -z "${try_counter[$1]}" ]
    then
        try_counter[$1]=0
        echo 0

    else
        echo ${try_counter[$1]}
    fi
}


function end_extension {
    local count

    url_in_file=$(sanitize_url "$url_in_file")
    
    if ( ! url "$url_in_file" || [ -z "$file_in" ] ) &&
           ( [ -z "$streamer" ] || [ -z "$playpath" ] )
    then
        count=$(get_try_counter "$url_in")

        if ((count < try_end))
        then
            set_try_counter "$url_in"
            _log 2

        elif check_connection
        then
            _log 30

        else
            _log 31
            set_exit
            break_loop=true
        fi
        return 1

    else
        set_try_counter "$url_in" reset
        return 0
    fi
}

function anydownload {
    ## http://anydownload.altervista.org
    local url_in="$1"
    local URL_IN
    local irc_host irc_chan irc_msg
    
    if [[ "$url_in" =~ xweaseldownload\.php ]]
    then
        url_in=$(urldecode "${url_in#*url=}")
        url_in=$(sed -r 's|\s{1}|%20|g' <<< "$url_in")

        URL_IN=$(curl "$url_in" -s 2>/dev/null     |
                        grep 'xdcc' 2>/dev/null    |
                        head -n1                   |
                        sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

    elif [[ "$url_in" =~ IRCdownload\.php ]] &&
         [[ ! "$url_in" =~ adfly ]]
    then
        html=$(curl "$url_in" -s)
        echo "$html" >OUT
        
        irc_host=$(grep server0 <<< "$html" |
                             sed -r 's|.+\"([^"]+)\"[^"]+|\1|g')

        irc_chan=$(grep canale0 <<< "$html" |
                          sed -r 's|.+\"\#([^"]+)\"[^"]+|\1|g')

        irc_msg="msg "$(grep 'nome_bot0' <<< "$html" | sed -r 's,.+value=\"([^"]+)\"[^"]+,\1,g')" xdcc send "$(grep numero_pack0 <<< "$html" | sed -r 's,.+\"([^"]+)\"[^"]+$,\1,g')
        
        URL_IN="irc://${irc_host}/${irc_chan}/${irc_msg}"
    fi

    if url "$URL_IN"
    then
        echo "$URL_IN"
        return 0

    else
        echo "$url_in"
        return 1        
    fi    
}

function extension_clicknupload {
    local url_in="$1"
    local html post_data

    if [ "$url_in" != "${url_in//clicknupload.}" ]
    then
        html=$(wget -t1 -T$max_waiting                               \
                    "$url_in"                                        \
                    --user-agent="Firefox"                           \
                    --keep-session-cookies="$path_tmp/cookies.zdl"   \
                    -qO- -o /dev/null)
        
        [ -z "$html" ] &&
            command -v curl >/dev/null && 
            html=$(curl "$url_in" -s) 

        if [[ "$html" =~ (File Not Found) ]]
        then
            _log 3

        else
            input_hidden "$html"
            post_data+="&method_free=Free Download >>"

            html=$(wget "$url_in"                       \
                        --post-data="$post_data"        \
                        -qO- -o /dev/null)

            input_hidden "$html"

            html=$(wget "$url_in"                       \
                        --post-data="$post_data"        \
                        -qO- -o /dev/null)

            url_in_file=$(grep downloadbtn <<< "$html" |
                                 sed -r "s|.+open\('([^']+)'\).+|\1|g")

            url "$url_in_file" &&
                return 0
        fi
    fi
    return 1
}

function extension_uptobox {
    local url_in="$1"
    local html post_data
    
    html=$(curl -s                             \
                -c "$path_tmp"/cookies0.zdl    \
                -A "$user_agent"               \
                "$url_in")

    file_in=$(get_title "$html")

    if [[ "$html" =~ (File not found) ]]
    then
        _log 3
        return 1
    fi

    if [[ "$html" =~ 'you can wait '([0-9]+)' hours '([0-9]+)' minutes '([0-9]+)' seconds' ]]
    then
        url_in_timer=$((${BASH_REMATCH[1]} * 60 * 60 + ${BASH_REMATCH[2]} * 60 + ${BASH_REMATCH[3]}))
        set_link_timer "$url_in" $url_in_timer
        _log 33 $url_in_timer
        return 1

    elif [[ "$html" =~ 'you can wait '([0-9]+)' minutes '([0-9]+)' seconds' ]]
    then
        url_in_timer=$((${BASH_REMATCH[1]} * 60 + ${BASH_REMATCH[2]}))
        set_link_timer "$url_in" $url_in_timer
        _log 33 $url_in_timer
        return 1

    elif [[ "$html" =~ 'you can wait '([0-9]+)' seconds' ]]
    then
        url_in_timer=${BASH_REMATCH[1]}
        set_link_timer "$url_in" $url_in_timer
        _log 33 $url_in_timer
        return 1
    fi

    unset post_data
    input_hidden "$html" #### $file_in == POST[fname]

    if [ "$post_data" != '=' ]
    then
        countdown- 30

        html=$(curl -s                              \
                    -b "$path_tmp"/cookies0.zdl     \
                    -c "$path_tmp"/cookies.zdl      \
                    -d "$post_data"                 \
                    -A "$user_agent"                \
                    "$url_in")
    fi

    url_in_file=$(grep "Click here to start your download" -B1 <<< "$html" |
                         head -n1                                          |
                         sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

    unset post_data
    return 0
}

function run_megadl {
    local link="$1"
    _log 3

    if hash megadl
    then
        get_language
        local msg1=$(header_dl 'ZigzagDownLoader --> MegaDL (megatools package):')
        local msg2=$(pause_msg)
        xterm -tn "xterm-256color"                                       \
	      -xrm "XTerm*faceName: xft:Dejavu Sans Mono:size=9:antialiasing=true:hinting=true:hintstyle=hintsfull"    \
	      +bdc -fg grey -bg black -title "MegaDL in $PWD"            \
	      -e "/bin/bash -i -c \"echo -e \\\"$msg1\n\\\"; megadl \\\"$link\\\"; echo -e \\\"$msg2\\\"; read\"" &
        print_c 1 "$(gettext 'Downloading with "megadl" from "megatools" package')"
        return 0
    else
        print_c 3 "$(gettext 'To download from Mega, install the "megatools" package')"
        return 1
    fi
}

function extension_mega {
    local url_in="$1"
    
    if [[ "$url_in" =~ (^https\:\/\/mega\.co\.nz\/|^https\:\/\/mega\.nz\/) ]]
    then
        [ "$url_in" == "${url_in//mega.co.nz/mega.nz}" ] ||
            replace_url_in "${url_in//mega.co.nz/mega.nz}"
        
        id=$(awk -F '!' '{print $2}' <<< "$url_in")

        key=$(awk -F '!' '{print $3}' <<< "$url_in" | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g')
        b64_hex_key=$(echo -n $key | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n')
        key[0]=$(( 0x${b64_hex_key:00:16} ^ 0x${b64_hex_key:32:16} ))
        key[1]=$(( 0x${b64_hex_key:16:16} ^ 0x${b64_hex_key:48:16} ))
        key=$(printf "%016x" ${key[*]})

        iv="${b64_hex_key:32:16}0000000000000000"

        json_data=$(wget -qO- --post-data='[{"a":"g","g":1,"p":"'$id'"}]' https://eu.api.mega.co.nz/cs -o /dev/null)

        [ "$json_data" == '[-2]' ] && return 1
            
        url_in_file="${json_data%\"*}"
        url_in_file="${url_in_file##*\"}"
        
        ##    file_in="$key".MEGAenc
        awk -F '"' '{print $6}' <<< "$json_data"             |
            sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g'       |
            base64 --decode --ignore-garbage 2> /dev/null    |
            xxd -p                                           |
            tr -d '\n' > "$path_tmp"/enc_attr.mdtmp
        
        xxd -p -r "$path_tmp"/enc_attr.mdtmp > "$path_tmp"/enc_attr2.mdtmp
        openssl enc -d -aes-128-cbc -K $key -iv 0 -nopad -in "$path_tmp"/enc_attr2.mdtmp -out "$path_tmp"/dec_attr.mdtmp
        ##file_in=$(awk -F '"' '{print $4}' "$path_tmp"/dec_attr.mdtmp).MEGAenc
        file_in=$(cat "$path_tmp"/dec_attr.mdtmp)
        file_in="${file_in#*\"n\"\:\"}"
        file_in="${file_in%%\"*}".MEGAenc
        sanitize_file_in

        if [ -z "$url_in_file" ] ||
               [ -z "$file_in" ]
        then
            _log 2
            
        elif ! url "$url_in_file"
        then
            _log 3
            
        else
            #### for POST-PROCESSING:
            ## openssl enc -d -aes-128-ctr -K $key -iv $iv -in $enc_file -out $out_file
            echo -e "$key\n$iv" > "$path_tmp"/"$file_in".tmp

            axel_parts=1

            rm -f "$path_tmp"/mega.log
            wget -SO /dev/null -o "$path_tmp"/mega.log "$url_in_file" &
            local pid=$!
            
            # (( $(wc -l < "$path_tmp"/mega.log) <5 ))
            while [ ! -s "$path_tmp"/mega.log ] ||
                      ! grep -q 'Content-Length' "$path_tmp"/mega.log
            do
                sleep 0.1
            done
            kill $pid 2>/dev/null

            if grep -q 'Bandwidth Limit Exceeded' "$path_tmp"/mega.log
            then
                print_c 3 "$(gettext "The bandwidth limit set by the server has been exceeded:")"
                print_c 1 "$(gettext "A proxy will be activated (to use more band, perhaps, you can change IP address by reconnecting the modem/router)")"

                # touch "$path_tmp"/proxy
                # check_ip

                set_temp_proxy
            fi
        fi
    fi
}


function extension_openload {
    local url_in="$1"
    local stream_id

    if curl "$url_in" -A "$user_agent" 2>&1 |
           grep "Sorry" &>/dev/null
    then
        _log 3
        return 1
    fi

    if command -v phantomjs &>/dev/null
    then
        html=$(curl -s "$url_in")
        # stream_id=$(grep 'id="streamur' <<< "$html")
        stream_id=$(grep 'style="" class="" id="' <<< "$html")
        stream_id="${stream_id%\"*}"
        stream_id="${stream_id##*\"}"
        
        openload_data=$(/usr/bin/phantomjs "$path_usr"/extensions/openload-phantomjs.js "$url_in" "$stream_id")

        url_in_file=$(trim "$(head -n1 <<< "$openload_data")")
        #file_in=$(trim "$(tail -n1 <<< "$openload_data")")
        file_in=$(grep 'og:title' <<< "$html" |
                      head -n1 |
                      sed -r 's|.+content=\"([^"]+)\".+|\1|g')

        if [ -z "$file_in" ]
        then
            file_in=$(get_title "$html")
            sanitize_file_in
            file_in="${file_in%__openload*}"
            sanitize_file_in
        fi
        
    else
        _log 35
    fi
}

function get_location { # 1=url 2=variable_to_new_url
    local location

    wget --spider -S "$1" \
         --keep-session-cookies \
         --load-cookies="$path_tmp/cookies.zdl" \
         --save-cookies="$path_tmp/cookies_location.zdl" \
         -o "$path_tmp"/get_location.txt
    location=$(awk '/ocation:/{print $2}' "$path_tmp"/get_location.txt | tail -n1)
    rm -f "$path_tmp"/get_location.txt
    mv "$path_tmp/cookies_location.zdl" "$path_tmp/cookies.zdl"

    if ! url "$location"
    then
        location=$(curl -v                          \
                        "$1"                        \
                        -c "$path_tmp"/cookies.zdl  \
                        2>&1                          |
                       awk '/ocation:/{print $3}'     |
                       head -n1)
    fi
    
    sanitize_url "$location" location
    
    if [ -n "$2" ]
    then
        declare -n ref="$2"
        ref="$location"

    else
        echo "$location"
    fi
        
    if url "$location"
    then
        return 0

    else
        return 1
    fi
}

function check_cloudflare {
    local target="$1" html

    if url "$target"
    then
        html=$(curl -s                   \
                    -A "$user_agent"     \
                    "$target")

    elif [ -f "$target" ]
    then
        html=$(cat "$target")

    elif [ -z "$target" ]
    then
        return 1
    fi

    if grep jschl_answer <<< "$html" &>/dev/null
    then
        print_c 2 "$(gettext "Detected Cloudflare")"

        ######################
        _log 38
        ######################
        
        return 0
    else
        return 1
    fi
}

function get_by_cloudflare {
    local url_in="$1" result
    declare -n ref="$2"
    local post_data="$3"
    local domain="${url_in#*\/\/}"
    domain="${domain%%\/*}"
    local proto="${url_in%${domain}*}"
    
    result=$(php "$path_usr"/extensions/cloudflare-bypass.php "$url_in" "$post_data")
    ref="$result"
    
    return
}

function get_location_by_cloudflare {
    local url_in="$1" result
    declare -n ref="$2"
    local post_data="$3"
    local domain="${url_in#*\/\/}"
    domain="${domain%%\/*}"
    local proto="${url_in%${domain}*}"
    
    result=$(php "$path_usr"/extensions/cloudflare-bypass.php "$url_in" "$post_data")
    result=$(tail -n1 <<< "$result")
    ref="$result"
    
    return
}

function update_tubeoffline {
    local hosts n

    hosts=$(curl -s "https://www.tubeoffline.com/sitemap.php"  |
                   grep -Po '>[^<>]+</a'                       |
                   sed -r 's|>(.+)<.+|\1|g'                    |
                   tr '[:upper:]' '[:lower:]'                  |
                   tr -d ' ')

    n=$(wc -l <<< "$hosts")
    hosts=$(head -n $((n - 6)) <<< "$hosts")
    tail -n $((n - 6 - 7)) <<< "$hosts" > "$path_conf"/tubeoffline-hosts.txt
}

function check_tubeoffline {
    local result

    if [ -s "$path_conf"/tubeoffline-hosts.txt ]
    then
        link_parser "$1"
        grep -q "${parser_domain%.*}" "$path_conf"/tubeoffline-hosts.txt &&
            return 0 ||
                return 1
    else
        ## se ancora non esiste un elenco degli host di tubeoffline, tenta ugualmente
        return 0
    fi
}

function get_data_xdcc_eu {
    link_xdcc_eu=()
    length_xdcc_eu=()
    file_xdcc_eu=()
    local data_s data_c data_p filename length
    
    html=$(curl -s "$1" |
                  sed -r 's|<tr>|\n|g' |
                  grep data-c)

    while read line
    do
        unset data_s data_c data_p filename length
        data_s="${line##*data-s=\"}"
        data_s="${data_s%%\"*}"

        data_c="${line##*data-c=\"\#}"
        data_c="${data_c%%\"*}"

        data_p="${line##*data-p=\"}"
        data_p="${data_p%%\"*}"

        line="${line##*delete.png}"

        line="${line#*</td><td>}"
        line="${line#*</td><td>}"
        line="${line#*</td><td>}"
        line="${line#*</td><td>}"
        length="${line%%</td><td>*}"
        
        line="${line#*</td><td>}"
        line="${line%*</td>*}"
        filename=$(sed -r 's|<[^>]*span[^>]*>||g' <<< "$line")

        if [ -z "$data_s" ] || [ -z "$data_c" ] || [ -z "$data_p" ] || [ -z "$length" ] || [ -z "$filename" ] 
        then
            return 1
        fi

        #link_xdcc_eu+=( "irc://$data_s"/"$data_c"/"msg%20${data_p// /%20}" )
        link_xdcc_eu+=( "$(sanitize_url "irc://$data_s"/"$data_c"/"msg $data_p" )" )
        length_xdcc_eu+=( "$length" )
        file_xdcc_eu+=( "${filename// /_}" )
        
    done <<< "$html"

    return 0    
}

function check_livestream {
    if [[ "$1" =~ youtube.+watch.+list ]]
    then
        test_livestream_boolean=false
    fi
    
    if [ "$test_livestream_boolean" == true ] ||
           set_line_in_file in "$1" "$path_tmp/livestream-links.txt"   
    then
        return 0
        
    elif [ "$test_livestream_boolean" == false ] ||
             set_line_in_file in "$1" "$path_tmp/not-livestream-links.txt"   
    then
        return 1
        
    else
        local link="$1"
    fi

    if [[ "$link" =~ (youtube\.|dailymotion\.com\/video) ]] &&
           [[ ! "$link" =~ youtube\.com(\/playlist|.+\/(videos|featured|playlists|community|channels)$) ]]
    then
        if [[ "$link" =~ google ]]
        then
            local location=$(grep -P "url=[^&]+" <<< "$link")
            location="${location#*url=}"
            location="${location%%&*}"
            
            if url "$location" &&
                    [ "$location" != "$link" ]
            then
                location=$(urldecode "$location")
            fi
        fi

        print_c 4 "Checking livestream link: %s" "$link"
        link=$($youtube_dl -f b --get-url "$link" 2>/dev/null | tail -n1)
    fi

    if [[ "$link" =~ (raiplay.+\/dirette\/|la7.it\/dirette-tv|yt_live_broadcast.+m3u8|dailymotion.+live.+m3u8) ]]
    then
        test_livestream_boolean=true
        set_line_in_file + "$1" "$path_tmp/livestream-links.txt"

        url "$location" &&
            set_line_in_file + "$location" "$path_tmp/livestream-links.txt"
        return 0
    else
        test_livestream_boolean=false
        set_line_in_file + "$1" "$path_tmp/not-livestream-links.txt"
        url "$location" &&
            set_line_in_file + "$location" "$path_tmp/not-livestream-links.txt"
        return 1
    fi
}

function run_livestream_timer {
    local link="$1"                                                \
          start_time="$2"                                          \
          duration_time                                            \
          stop_time_in_sec                                         \
          start_time_in_sec                                        \
          now_in_sec=$(human_to_seconds $(date +%H\ %M\ %S))

    if [ "$start_time" != "${start_time//tomorrow}" ]
    then
        start_time="${start_time//\:tomorrow}"
        start_time_in_sec=$(human_to_seconds ${start_time//\:/ })       
        start_time_in_sec=$((start_time_in_sec + 86400))

    else
        start_time_in_sec=$(human_to_seconds ${start_time//\:/ })
    fi

    if [[ "$start_time" =~ ([0-9]+\:[0-9]+\:[0-9]+) ]] &&
           ! set_line_in_file in "$link" "$path_tmp"/livestream_run.txt
    then
        {
            set_line_in_file + "$link" "$path_tmp"/livestream_run.txt
            
            while (( start_time_in_sec > now_in_sec ))
            do
                sleep 1
                now_in_sec=$(human_to_seconds $(date +%H\ %M\ %S))
            done

            if (( start_time_in_sec <= now_in_sec )) &&
                   check_livestream_link_time "$link"
            then
                set_line_in_file + "$link" "$path_tmp"/livestream_start.txt
            fi
        } & disown
    else
        return 1
    fi
    return 0
}

function set_livestream_time {
    local link="$1" \
          start_time="$2" \
          duration_time="$3"

    [ -s "$path_tmp"/livestream_time.txt ] &&
        sed -r "s|$link\ .+||g" -i "$path_tmp"/livestream_time.txt
    
    set_line_in_file + "$link $start_time $duration_time" "$path_tmp"/livestream_time.txt &&
        return 0 || return 1
}

function remove_livestream_link_start {
    local link="$1"
    link="${link//\%3[aA]/:}"
    link="${link//\%2[fF]//}"
    
    if [ -s "$path_tmp"/livestream_start.txt ]
    then
        awk -v link="$link" '{if ($1 != link && $0) print $0}' "$path_tmp"/livestream_start.txt >> "$path_tmp"/livestream_start2.txt
        mv "$path_tmp"/livestream_start2.txt "$path_tmp"/livestream_start.txt
        
        test -z "$(<"$path_tmp"/livestream_start.txt)" &&
            rm -f "$path_tmp"/livestream_start.txt
    fi
}

function remove_livestream_link_time {
    local link="$1"
    link="${link//\%3[aA]/:}"
    link="${link//\%2[fF]//}"

    if [ -s "$path_tmp"/livestream_time.txt ]
    then
        awk -v link="$link" '{if ($1 != link && $0) print $0}' "$path_tmp"/livestream_time.txt >> "$path_tmp"/livestream_time2.txt
        mv "$path_tmp"/livestream_time2.txt "$path_tmp"/livestream_time.txt
        
        test -z "$(<"$path_tmp"/livestream_time.txt)" &&
            rm -f "$path_tmp"/livestream_time.txt
    fi
}

function get_livestream_duration_time {
    local link="$1"
    declare -n ref="$2"

    if [ -s "$path_tmp"/livestream_time.txt ]
    then
        local line=$(awk -v link="$link" '{if (link == $1) print $3}' "$path_tmp"/livestream_time.txt)
    fi
    
    if [[ "$line" =~ ([0-9]+\:[0-9]+\:[0-9]+) ]]
    then
        ref="$line"
        return 0
    else
        return 1
    fi
}

function get_livestream_start_time {
    local link="$1" 
    declare -n ref="$2"

    if [ -s "$path_tmp"/livestream_time.txt ]
    then
        local line=$(awk -v link="$link" '{if (link == $1) print $2}' "$path_tmp"/livestream_time.txt)
    fi    

    if [[ "$line" =~ ([0-9]+\:[0-9]+\:[0-9]+) ]]
    then
        ref="$line"
        return 0
    else
        return 1
    fi
}

function check_livestream_link_time {
    local link="$1"
    
    if [ -s "$path_tmp"/livestream_time.txt ]
    then
        local test=$(awk -v link="$link" '{split($0,items,/\s/); if (link == items[1]) print items[1]}' "$path_tmp"/livestream_time.txt | head -n1)
        [ -n "$test" ] && return 0
    fi
    return 1
}

function check_livestream_link_start {
    local link="$1"

    if [ -s "$path_tmp"/livestream_start.txt ]
    then
        local test=$(awk -v link="$link" '{split($0,items,/\s/); if (link == items[1]) print items[1]}' "$path_tmp"/livestream_start.txt | head -n1)
        [ -n "$test" ] && return 0
    fi
    return 1
}

function get_livestream_links_start {
    if [ -s "$path_tmp"/livestream_start.txt ]
    then
        cat "$path_tmp"/livestream_start.txt
        return 0
    else
        return 1
    fi
}

function clean_livestream {
    local line
    declare -a lines

    if [ ! -f "$path_tmp"/links_loop.txt ] ||
           test -z "$(<"$path_tmp"/links_loop.txt)"
    then
        rm -f "$path_tmp"/livestream_time.txt "$path_tmp"/livestream_start.txt
    fi

    if test -f "$path_tmp"/livestream_time.txt
    then
        while [ -f "$path_tmp"/live-rewriting ]
        do
            sleeping 0.1
        done
        touch "$path_tmp"/live-rewriting

        while read -a lines
        do
            if ! set_link in "${lines[0]}"
            then
                sed -r "s|^${lines[0]}\ [0-9]{2}.+$||g" -i "$path_tmp"/livestream_time.txt
            fi

        done < "$path_tmp"/livestream_time.txt
        
        {
            [ -e "$path_tmp"/livestream_time.txt ] &&
                line=$(awk '!($0 in a){a[$0]; if ($0) print}' "$path_tmp"/livestream_time.txt)
            
            if [ -n "$line" ]
            then
                echo "$line" >"$path_tmp"/livestream_time.txt
            else
                rm -f "$path_tmp"/livestream_time.txt
            fi
        }
    fi

    [ ! -s "$path_tmp"/livestream_time.txt ] &&
        rm -f "$path_tmp"/livestream_start.txt

    if [ -s "$path_tmp"/links_loop.txt ] &&
           [ -s "$path_tmp"/livestream_start.txt ]
    then
        while read line
        do
            grep -q "$line" "$path_tmp"/links_loop.txt ||
                sed -e "s|$line||g" -i "$path_tmp"/livestream_start.txt
            
        done < "$path_tmp"/livestream_start.txt
        
        clean_file "$path_tmp"/livestream_start.txt
    fi

    rm -f "$path_tmp/live-rewriting"
}

function check_linksloop_livestream {
    clean_livestream
    local oIFS="$IFS"
    
    if [ -s "$path_tmp"/links_loop.txt ]
    then
        declare -a list=()
        read -d '' -a list < "$path_tmp"/links_loop.txt
        
        local line start_time i gui_alive
        
        for line in "${list[@]}"
        do
            if check_livestream "$line"
            then
                # if [ ! -s "$path_tmp"/livestream_time.txt ] ||
                #         ( [ -s "$path_tmp"/livestream_time.txt ] &&
                #               ! check_livestream_link_time "$line" )
                # then                
                #     for i in $(ls "$path_tmp"/yad_multiprogress_pid.* 2>/dev/null)
                #     do
                #         check_pid $(cat "$i") && gui_alive=true && break
                #     done
                    
                #     if [ -n "$gui_alive" ]
                #     then
                #         for ((i=0; i<${#live_streaming_url[@]}; i++))
                #         do
                #             if [ "$line" == "${live_streaming_url[i]}" ] &&
                #                    ! check_livestream_link_time "$line"
                #             then
                #                 ICON="$path_usr"/gui/icon-32x32.png
                #                 TEXT="<b>ZigzagDownLoader</b>\n\n<b>Path:</b> $PWD"
                #                 IMAGE="$path_usr"/gui/zdl-64x64.png
                #                 IMAGE2="$path_usr"/gui/zdl.png
                #                 YAD_ZDL=(
                #                     --window-icon="$ICON"
                #                     --borders=5
                #                 )

                #                 display_livestream_gui "${live_streaming_chan[i]}" "$line"
                #                 break
                #             fi
                #         done
                        
                #     elif [ "$this_mode" != daemon ]
                #     then
                #         #                        display_set_livestream "$line"
                #         :
                #     fi
                    
                # el
                if [ -s "$path_tmp"/livestream_time.txt ] &&
                         check_livestream_link_time "$line"  
                then
                    get_livestream_start_time "$line" start_time
                    run_livestream_timer "$line" "$start_time"
                fi
                
            else
                set_line_in_file + "$line" "$path_tmp/not-livestream-links.txt"
            fi            
        done
    fi
    IFS="$oIFS"
}

function check_linksloop_livestream_lite {
    local oIFS="$IFS"
    
    if [ -s "$path_tmp"/links_loop.txt ]
    then
        declare -a list=()
        read -d '' -a list < "$path_tmp"/links_loop.txt
        
        local line start_time i gui_alive

        for line in "${list[@]}"
        do
            if check_livestream "$line" &&
                    [ -s "$path_tmp"/livestream_time.txt ] &&
                    check_livestream_link_time "$line"
            then
                get_livestream_start_time "$line" start_time
                run_livestream_timer "$line" "$start_time"
            fi
        done
    fi
    IFS="$oIFS"
}

function check_livestream_twice {
    local link="$1" x

    if check_livestream "$link" &&
            data_stdout
    then
        for ((x=0; x<${#pid_out[@]}; x++))
        do
            if [ "$link" == "${url_out[x]}" ] &&
                   ! check_pid "${pid_out[x]}"
            then
                [ "${percent_out[x]}" != 100 ] &&
                    rm -f "${file_out[x]}" 
                rm -f "$path_tmp"/"${file_out[x]}"_stdout.*
                break
            fi
        done
    fi
}

function check_xdcc_links {
    local link
    test -s "$start_file" &&
        while read link
        do
            if grep -q "${XDCC_EU_SEARCHKEY_URL}" <<< "$link"
            then
                display_xdcc_eu_gui "${link##*=}"
            fi
            
        done < "$start_file"
}

function tag_link { ## 1=link 2=name_variable_to_assign_link
    local url="$1"
    local tag=$(date +%s)

    if [ -n "$2" ]
    then
        declare -n ref="$2"
        ref="${url}#$tag"
    else
        echo "${url}#$tag"
    fi
}

function open_relink {
    rm -f $path_tmp/links_loop.txt
    if [ -d "$path_usr/extensions/" ]
    then
        shopt -s nullglob                   
        for srcfile in "$path_usr"/extensions/[0-9]*.sh
        do
            if [ -f "$srcfile" ]
            then
                source "$srcfile"
                #echo "$url_in" >/dev/tty1
            fi
        done
        shopt -u nullglob
    fi

    #echo "url: $url_in"
    #$browser "$url_in"
    $browser $(cat $path_tmp/links_loop.txt)
}

function test_url_in_file {
    local result=1
    
    for i in $(seq 0 3)
    do
        if wget -q -o /dev/null \
                --spider "$url_in_file" \
                -t1 -T 20
        then
            result=0
            break
        fi
        sleep 1
    done
    return $result
}

## youtube-dl embedded
function youtube-dl {
    local cmd=$(hash -t youtube-dl 2>/dev/null | head -n1)
    
    if [ -e /cygdrive ]
    then
        test -n "$cmd" &&
            $cmd "$@"
        
    else
        "$youtube_dl" "$@"
    fi
}

function check_youtube-dl {    
    if [ -e /cygdrive ]
    then
        hash youtube-dl &>/dev/null &&
            return 0 ||
                return 1
    else
        hash $youtube_dl &>/dev/null &&
            return 0 ||
                return 1
    fi
}

