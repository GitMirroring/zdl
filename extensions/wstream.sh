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

## ZDL add-on
## zdl-extension types: streaming download
## zdl-extension name: WStream (HD)

if [[ "$url_in" =~ wstream\. ]] 
then
    if [[ "$url_in" =~ fastredirect ]]
    then
        location=$(curl -v "$url_in" 2>&1 |grep ocation|awk '(NR == 2){print $3}')
        location=$(trim "$location")
        url "$location" &&
            replace_url_in "$location"
        html=$(wget -SO- "$url_in" -o /dev/null)
        input_hidden "$html"
        post_data="${post_data##*=}"

        replace_url_in "https://video.wstream.video/$post_data"
    fi

    if [[ "$url_in" =~ file_code ]]
    then
        replace_url_in "${url_in//'video.php?file_code='}"
    fi
       
    if [[ "$url_in" =~ http[s]*://[w.]*wstream ]]
    then
        wstream_link="${url_in//\/\/wstream/\/\/download.wstream}"
        wstream_link="${wstream_link//\/video\//\/}"
        wstream_link="${wstream_link//https/http}"
        
    elif [[ "$url_in" =~ download\.wstream ]]
    then
        wstream_link="${url_in//\/\/download.wstream/\/\/video.wstream}"
        wstream_link="$wstream_link"

    else
        wstream_link="$url_in"
    fi

    if url "$wstream_link"
    then
        get_language
        [ "$url_in" == "$wstream_link" ] ||
            print_c 4 "$(gettext "Redirection"): $url_in -> $wstream_link"

        get_language_prog
        html=$(wget -qO- \
                    -o /dev/null \
                    --keep-session-cookies \
                    --save-cookies="$path_tmp"/cookies.zdl \
                    --user-agent="$user_agent" \
                    "$wstream_link")
        get_language

        input_hidden "$html"

        if [[ "$html" =~ (forcecaptcha|form.*autocomplete\=\'off\') ]]
        then
            if [[ "$html" =~ (form.*autocomplete\=\'off\') ]]
            then
                if [[ "$html" =~ '>'([^>]+)'</span>' ]]
                then
                    post_data="forcecaptcha=${BASH_REMATCH[1]}"

                elif [[ "$html" =~ (imgdc\.php\?txt\=[0-9]+) ]]
                then
                    captcha_url="${BASH_REMATCH[1]}"

                    wget https://video.wstream.video/"$captcha_url" \
                         -O "$path_tmp"/wstream_captcha.png \
                         -o /dev/null
                    
                    recaptcha_name=$(grep -P "input type='text'" <<< "$html")
                    recaptcha_name=$(sed -r "s|.+name='([^']+)'.+|\1|g" <<< "$recaptcha_name")                   
                    recaptcha_value=$(simple_captcha "$path_tmp"/wstream_captcha.png)
                    print_c 4 "Captcha: $recaptcha_value"

                else
                    recaptcha_name=$(grep -P "form autocomplete='off'" -A1 <<< "$html" |
                                     tail -n1)
                    recaptcha_value=$(sed -r "s|.+>\ *([^<\ ]+)\ *<.+|\1|g" <<< "$recaptcha_name")
                    recaptcha_name=$(sed -r "s|.+name='([^']+)'.+|\1|g" <<< "$recaptcha_name")
                fi
                post_data="${recaptcha_name}=${recaptcha_value}"

            fi
            html=$(wget -qO- \
                        -o /dev/null \
                        --post-data="$post_data" \
                        --keep-session-cookies \
                        --save-cookies="$path_tmp"/cookies.zdl \
                        --user-agent="$user_agent" \
                        "$wstream_link")            
        fi

        ##### per ora è solo client, quindi è commentato:
        countdown- 6

        file_in=$(get_title "$html" |head -n1)
        file_in="${file_in#Download Free }"

        file_filter "$file_in"
            
        #### 
        # for wstream_exp in downloadlink dwn
        # do
        #     wstream_req=$(grep -oP "$wstream_exp.php?[^\"]+" <<< "$html")
        #     [ -n "$wstream_req" ] && break
        # done
        ## sostituisce il codice commentato sopra:
        wstream_req=$(grep -oP "[^\"\']+.php\?[^\"\']+" <<< "$html" | grep -v '\/' |tail -n1)
        
        if [[ ! "$html" =~ (Siamo spiacenti ma come utente non premium puoi scaricare solamente 2 file ogni ora\.\<br\>\<br\>\<br\>\<h1\>\<a href\=\'https\:\/\/wstream\.video\/premium\.html\'\> Per favore diventa nostro supporter \<\/\a>\<\/h1\>) ]] &&
               [ -n "$wstream_req" ] &&
               [[ ! "$wstream_req" =~ imgx ]] &&
               [[ "${recaptcha_value}" =~ ([0-9]{6}) ]]
        then
            for proto in https http
            do
                #wstream_url_req="$proto://download.wstream.video/$wstream_req"
                wstream_url_req="$proto://video.wstream.video/$wstream_req"
                print_c 4 "$(gettext "Redirection"): $wstream_link -> $wstream_url_req"
                get_language_prog
                
                __cfduid=$(tail -n1 "$path_tmp"/cookies.zdl | sed -r 's|.+\t(.+)$|\1|g')

                html=$(curl -v \
                            -H 'Accept: */*' \
                            -H 'Accept-Language: it,en-US;q=0.7,en;q=0.3' \
                            -H 'Cache-Control: no-cache' \
                            -H 'Connection: keep-alive' \
                            -H "Cookie: __cfduid=$__cfduid; dw=1" \
                            -A "$user_agent" \
                            -H 'Pragma: no-cache' \
                            -H "Referer: $wstream_link" \
                            -H "TE: Trailers" \
                            -H "X-Requested-With: XMLHttpRequest" \
                            "$wstream_url_req" 2>&1)
                get_language

                if [[ "$html" =~ (Server problem.. please contact our support) ]]
                then
                    _log 3
                    break

                else
                    url_in_file=$(grep "class='bbkkff" <<< "$html")
                    url_in_file="${url_in_file#*bbkkff}"
                    url_in_file="${url_in_file#*href=\'}"
                    url_in_file="${url_in_file%%\'*}"

                    url "$url_in_file" && break
                fi
            done
        else
            _log 44
            continue
        fi

        if url "$url_in_file" &&
                test -z "$file_in"
        then
            file_in="${url_in_file##*\/}"
        fi

        check_wget || {
            # echo "Elite" >> "$path_tmp"/proxy
            # echo "Anonymous" >> "$path_tmp"/proxy
            print_c 3 "$(gettext "The bandwidth limit set by the server has been exceeded"):" 
            print_c 1 "$(gettext "a proxy will be used (to use more band, perhaps, you can change IP address by reconnecting the modem/router)")"
            
            set_temp_proxy
        }
    fi

    end_extension
fi
