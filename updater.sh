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
set +o history

## Axel - Cygwin
function install_axel-cygwin {
    ## source: http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    cygaxel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" 
    
    if ! command -v axel &>/dev/null
    then
        cd /
        wget "$cygaxel_url"
        tar -xvjf "${cygaxel_url##*'/'}"
        cd -
    fi
}

##############

function install_phpcomposer {
    cd /tmp
    try php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

    if [ -f composer-setup.php ]
    then
        local signature=$(curl -s https://composer.github.io/installer.sig)
        try php -r "if (hash_file('SHA384', 'composer-setup.php') === '$signature') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

        try php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer
        try php -r "unlink('composer-setup.php');"
    fi
    cd -
}

function update_zdl-wise {
    if [ ! -e "/cygdrive" ]
    then
        print_c 1 "$(gettext "Automatic compilation of zdl-wise.c")"
        gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null 
    fi
}


function update_zdl-conkeror {
    [ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"

    if [ -e /cygdrive ]
    then
        rc_path="${win_home}/.conkerorrc"
    else
        rc_path="$HOME/.conkerorrc"
    fi

    if [ -f "$rc_path" ]
    then
        mv "$rc_path" conkerorrc.js
        mkdir -p "$rc_path"
        code_conkerorrc="$(cat conkerorrc.js)"
        code_conkerorrc="${code_conkerorrc//require(\"conkerorrc.zdl\");}"
        code_conkerorrc="${code_conkerorrc//require(\"$path_conf\/conkerorrc.zdl\");}"
        code_conkerorrc="${code_conkerorrc//require(\"$SHARE\/extensions\/conkerorrc.zdl\");}"
        code_conkerorrc="${code_conkerorrc//\/\/ ZigzagDownLoader}"
        echo "${code_conkerorrc}" > "$rc_path"/conkerorrc.js
    else
        mkdir -p "$rc_path"
    fi
    code_zdlmod="$(cat $SHARE/extensions/conkerorrc.zdl)"
    echo "${code_zdlmod//'{{{CYGDRIVE}}}'/$cygdrive}" > "$rc_path"/zdl.js
}


function try {
    cmdline=( "$@" )
    
    if ! "${cmdline[@]}" 2>/dev/null 
    then        
        if ! sudo "${cmdline[@]}" #2>/dev/null 
        then
            if [ "$real_mode" == gui ]
            then
                yad --title="$(gettext "ZDL update")" \
                    --text="$(gettext "The root user password is required.\nRepeat the ZDL update using the terminal.")" \
                    --image="dialog-error" \
                    "${YAD_ZDL[@]}"
                
                set -o history
                exit 1
            fi
            su -c "${cmdline[@]}" || (
                print_c 3 "$failure: ${cmdline[@]}"
                return 1
            )
        fi
    fi
}

function install_dep {
    local dep="$1"
    
    declare -A alert_msg
    alert_msg['axel']="$PROG $(gettext "can download with Wget but strongly recommends Axel, because:
- can significantly speed up the download
- allows the recovery of downloads in case of interruption

For more information on Axel: http://alioth.debian.org/projects/axel/
")"
    
    alert_msg['xterm']="$PROG $(gettext "uses XTerm if launched from a graphical application such as Firefox/Iceweasel/Icecat (via Flashgot), Chrome/Chromium (via Download Assistant or Simple Get), XXXTerm/Xombrero and Conkeror:")"
    
    for cmd in "${!deps[@]}"
    do
        [ "$dep" == "${deps[$cmd]}" ] && break
    done

    while ! command -v $cmd &>/dev/null
    do
        print_c 3 "$(eval_gettext "WARNING: \$dep is not installed on your system")"

        local depmsg="${alert_msg[$dep]}$(eval_gettext "
1) Automatically install \$dep from packages (RECOMMENDED)
2) Automatically installs \$dep from sources
3) Skip the \$dep installation and continue with the installation of \$PROG and its other dependencies
4) Exit \$PROG to install dep manually (you can find it here: http://pkgs.org/search/?keyword=\$dep)")"

        echo -e "$depmsg"
        print_c 2 "$(gettext "Choose what to do (1-4):")"
        cursor on
        read -e input
        cursor off
        
        case $input in
            1) install_pk $dep ;;
            2) install_src $dep ;;
            3) break ;;
            4) set -o history; exit 1 ;;
        esac
    done
}

function install_test {
    local test_type installer dep cmd
    test_type=$1
    installer=$2
    dep=$3

    for cmd in "${!deps[@]}"
    do
        [ "$dep" == "${deps[$cmd]}" ] && break
    done

    if ! command -v $cmd &>/dev/null
    then
        print_c 3 "$(gettext "Automatic installation failed")"
        case $test_type in
            pk)
                echo "$installer $(gettext "did not find the following package:") $dep"
                ;;
            src)
                echo "$(gettext "Errors in compilation or installation")"
                ;;
        esac

        pause
        return 1
    else
        return 0
    fi
}

function install_pk {
    local dep="$1"
    
    print_c 1 "$(gettext "Installing") $dep"

    ## apt-get yum pacman zypper port

    if command -v apt-get &>/dev/null
    then
        DEBIAN_FRONTEND=noninteractive
        try apt-get --no-install-recommends -q -y install $dep
        install_test pk apt-get $dep &&
            return 0

    elif command -v yum &>/dev/null
    then
        try yum install $dep
        install_test pk yum $dep &&
            return 0

    elif command -v pacman &>/dev/null
    then
        try pacman -S $dep 2>/dev/null
        install_test pk pacman $dep &&
            return 0

    elif command -v zypper &>/dev/null
    then
        try zypper install $dep
        install_test pk zypper $dep &&
            return 0

    elif command -v port &>/dev/null
    then
        try port install $dep
        install_test pk port $dep &&
            return 0

    else
        return 1
    fi
}

function make_install {
    make
    sudo make install ||
        (
            echo "$(gettext "Enter the root password")" #"Digita la password di root"
            su -c "make install"
        )
    make clean
    install_test src $1
}


function install_src {
    local dep
    dep=$1
    
    case $dep in
        axel)
            cd /usr/src
            wget https://alioth.debian.org/frs/download.php/file/3015/axel-2.4.tar.gz

            tar -xzvf axel-2.4.tar.gz
            cd axel-2.4
            
            make_install $dep
            ;;

        xterm)
            cd /usr/src
            wget http://invisible-island.net/datafiles/release/xterm.tar.gz
            
            tar -xzvf xterm.tar.gz
            cd xterm-300

            make_install $dep
            ;;
    esac
}


function update {
    PROG=ZigzagDownLoader
    prog=zdl
    BIN="/usr/local/bin"
    SHARE="/usr/local/share/zdl"
    ## sources: http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    axel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" 
    success="$(gettext "Update completed")"
    failure="$(gettext "Update failed")"
    path_conf="$HOME/.$prog"
    file_conf="$path_conf/$prog.conf"

    if [[ -z "$(grep 'shopt -s checkwinsize' $HOME/.bashrc)" ]]
    then
        echo "shopt -s checkwinsize" >> ~/.bashrc 
    fi

    mkdir -p "$path_conf/extensions"

    if [ ! -f "$path_conf"/.zdl-counter ]
    then
        curl -sd 'op=set' http://zoninoz.altervista.org/zdl/zdl-counter.php &>/dev/null &&
            touch "$path_conf"/.zdl-counter
    fi
    
    if [ ! -f "$file_conf" ]
    then
        echo "# ZigzagDownLoader configuration file" > "$file_conf"
    fi

    if [ -e /cygdrive ]
    then
        win_home=$(cygpath -u "$HOMEPATH")
        win_progfiles=$(cygpath -u "$PROGRAMFILES")

        cygdrive=$(realpath /cygdrive/?/cygwin 2>/dev/null)
        [ -z "$cygdrive" ] && cygdrive=$(realpath /cygdrive/?/Cygwin 2>/dev/null)
        cygdrive="${cygdrive#*cygdrive\/}"
        cygdrive="${cygdrive%%\/*}"
        [ -z "$cygdrive" ] && cygdrive="C"
    fi
    # update_zdl-wise

    chmod +rx -R .

    setterm --cursor on
    if ! try mv -f zdl zdl-xterm zdl-sockets $BIN
    then
        print_c 3 "$BIN: $(gettext "failed. Please try again")"
        set -o history
        exit 1
    else
        print_c 1 "$BIN: $(gettext "saved successfully")"
    fi

    [ "$?" != 0 ] && return
    cd ..

    [ ! -e "$SHARE" ] && try mkdir -p "$SHARE"

    try rm -rf "$SHARE"
    # try mkdir -p /usr/share/info
    # try mkdir -p /usr/share/man/it/man1
    # try install zdl/docs/zdl.1 /usr/share/man/it/man1/
    # try rm -f /usr/share/man/man1/zdl.1
    # try ln -s /usr/share/man/it/man1/zdl.1 /usr/share/man/man1/zdl.1
    # try mandb -q
    # try install -m 644 zdl/docs/zdl.info /usr/share/info/
    # try install-info --info-dir=/usr/share/info /usr/share/info/zdl.info &>/dev/null
    for lang in it en
    do
        ## info zdl
        try rm -f /usr/share/info/zdl.info
        try mkdir -p /usr/share/info/$lang/
        try install -m 644 zdl/docs/$lang/zdl.info /usr/share/info/$lang/
        try install-info --info-dir=/usr/share/info/$lang/ /usr/share/info/$lang/zdl.info &>/dev/null
        
        ## man zdl
        try mkdir -p /usr/share/man/$lang/man1/
        try install zdl/docs/$lang/zdl.1 /usr/share/man/$lang/man1/
        try rm -f /usr/share/man/man1/zdl.1
        #try ln -s /usr/share/man/it/man1/zdl.1 /usr/share/man/man1/zdl.1
    done
    try rm -f /usr/share/info/zdl.info
    try ln -s /usr/share/info/en/zdl.info /usr/share/info/zdl.info
    try mandb -q

    ## bash completion
    try mkdir -p /etc/bash_completion.d/
    try install -T zdl/docs/zdl.completion /etc/bash_completion.d/zdl

    ## software locale
    for dir in zdl/locale/*
    do
        if [ -d "$dir" ]
        then
            try mkdir -p /usr/local/share/locale/"${dir##*\/}"/LC_MESSAGES/
            try install "$dir"/LC_MESSAGES/zdl.mo /usr/local/share/locale/"${dir##*\/}"/LC_MESSAGES/
        fi
    done

    try mv "$prog" "$SHARE"
    
    if [ $? != 0 ]
    then
        print_c 3 "$SHARE: $(gettext "failed. Please try again")"
        set -o history
        exit 1
    else
        print_c 1 "$SHARE: $(gettext "saved successfully")"
    fi

    if [ -e /cygdrive ]
    then
        code_batch=$(cat $SHARE/zdl.bat)
        echo "${code_batch//'{{{CYGDRIVE}}}'/$cygdrive}" > /${prog}.bat && print_c 1 "\n$(gettext "Startup batch script installed:") $(cygpath -m /)/zdl.bat " 
        chmod +x /${prog}.bat
    fi

    update_zdl-conkeror

    cp *.sig "$path_conf"/zdl.sig 2>/dev/null
    rm -fr *.gz *.sig "$prog"
    cd ..
    dir_dest=$PWD

    source $SHARE/config.sh
    set_default_conf

    echo -e "$(eval_gettext "Below, the existing ZigzagDownLoader extensions,
in \$SHARE/extensions/
NB:
- any homonymous extensions will be ignored
- you can control the process flow by assigning
  extension file names:
  ZDL will read the files in lexicographic order
  (also to replace or enrich existing extensions)
- new user extensions must be connected in
  \$SHARE/extensions/
  (you can automatically link them with: zdl -fu)

EXTENSIONS:
")" > "$path_conf"/extensions/$(gettext "README").txt

    find $SHARE/extensions/ -type f |
        grep -P extensions/[^/]+.sh$  >> "$path_conf"/extensions/$(gettext "README").txt
    
    if [[ $(ls "$path_conf"/extensions/*.sh 2>/dev/null) ]]
    then
        for extension in "$path_conf"/extensions/*.sh 
        do
            if [ ! -f $SHARE/extensions/"${extension##*\/}" ]
            then
                try ln -s "$extension" $SHARE/extensions/"${extension##*\/}"
            fi
        done
    fi

    if [ -e /cygdrive ]
    then
        ## DIPENDENZE
        #
        ## CYGWIN
        
        mirrors=(
            "http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/"
            "http://bo.mirror.garr.it/mirrors/sourceware.org/cygwinports/"
        )
        
        install_axel-cygwin
        cd /tmp
        
        if ! command -v apt-cyg &>/dev/null
        then
            print_c 1 "$(gettext "Installing") apt-cyg"

            wget http://rawgit.com/transcode-open/apt-cyg/master/apt-cyg
            install apt-cyg /bin
        fi

        if ! command -v node &>/dev/null
        then
            print_c 1 "$(gettext "Installing") Nodejs.exe in $SHARE"
            wget -O $SHARE/node.exe https://nodejs.org/dist/v4.4.4/win-x86/node.exe
        fi

        if ! command -v ffmpeg &>/dev/null
        then
            print_c 1 "$(gettext "Installing") FFMpeg"
            
            rm -f /tmp/list-pkts.txt
            apt-cyg mirror "${mirrors[1]}"
            apt-cyg install ffmpeg | tee -a /tmp/list-pkts.txt
            
            unset pkts
            mapfile pkts <<< "$(grep Unable /tmp/list-pkts.txt | sed -r 's|.+ ([^\ ]+)$|\1|g')"
            print_c 1 "\n$(gettext "Recovery packages not found:")\n${pkts[*]}\n"
            apt-cyg mirror "${mirrors[0]}"
            apt-cyg install ${pkts[*]} 
        fi
        
        if ! command -v rtmpdump &>/dev/null
        then
            print_c 1 "$(gettext "Installing") RTMPDump"
            
            apt-cyg mirror "${mirrors[1]}"
            apt-cyg install rtmpdump
        fi

        declare -A deps
        deps['gettext']=gettext
        deps['aria2c']=aria2
        deps['nano']=nano
        # deps['cmp']=diffutils
        deps['base64']=coreutils
        deps['xxd']=vim-common
        deps['pinfo']=pinfo
        deps['openssl']=openssl
        deps['php']=php
        deps['socat']=socat
        deps['gawk']=gawk
        deps['rlwrap']=rlwrap
        deps['setterm']=util-linux
        deps['fuser']=psmisc
        deps['openssl']=openssl
        deps['curl']=curl
        deps['convert']=imagemagick
        deps['tesseract']=tesseract-ocr
        ## deps['tput']=ncurses-bin

        for cmd in "${!deps[@]}"
        do
            if ! command -v $cmd &>/dev/null 
            then
                apt-cyg mirror "${mirrors[0]}"
                print_c 1 "$(gettext "Installing") ${deps[$cmd]}"
                apt-cyg install ${deps[$cmd]}
            fi
        done

        ## funzione necessaria per php-aaencoder: 
        if ! php -r 'echo mb_strpos("", "")' 2>/dev/null
        then
            apt-cyg mirror "${mirrors[0]}"
            apt-cyg install php-mbstring
        fi

        ## per installare COMPOSER (installatore di pacchetti php: vedi funzione in alto) 
        #
        # apt-cyg apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
        #
        # for pack in php php-json php-phar php-iconv
        # do
        #     if ! command -v "$pack" &>/dev/null
        #     then
        #       apt-cyg install "$pack"
        #     fi
        # done
        #
        # if ! command -v composer &>/dev/null
        # then
        #     install_phpcomposer
        # fi
        
        apt-cyg mirror "${mirrors[0]}"
        apt-cyg install bash-completion 2>/dev/null

    else
        ## DIPENDENZE
        #
        ## GNU/LINUX
        
        declare -A deps
        deps['gettext']=gettext
        deps['pinfo']=pinfo
        deps['aria2c']=aria2
        deps['axel']=axel
        deps['node']=nodejs
        deps['php']=php-cli
        ## deps['cmp']=diffutils
        deps['socat']=socat
        deps['gawk']=gawk
        deps['rlwrap']=rlwrap
        deps['setterm']=util-linux
        deps['fuser']=psmisc    
        deps['openssl']=openssl
        deps['desktop-file-install']=desktop-file-utils
        deps['curl']=curl
        deps['phantomjs']=phantomjs
        deps['yad']=yad
        deps['notify-send']=libnotify-bin
        deps['wmctrl']=wmctrl
        deps['mimeopen']=libfile-mimeinfo-perl
        deps['youtube-dl']=youtube-dl
        ## deps['tput']=ncurses-bin
        deps['ffmpeg']=ffmpeg
        deps['convert']=imagemagick
        deps['tesseract']=tesseract-ocr
        ## deps['composer']=composer
        ## php-mbstring
        
        command -v X &>/dev/null &&
            deps['xterm']=xterm

        for cmd in "${!deps[@]}"
        do
            if ! command -v $cmd  &>/dev/null
            then
                if [ "$cmd" != node ] || ( [ "$cmd" == node ] && ! command -v nodejs &>/dev/null )
                then
                    print_c 1 "$(gettext "Installing") ${deps[$cmd]}"
                    install_dep ${deps[$cmd]}
                fi
            fi
        done

        ## cloudflare:
        # hash composer 2>/dev/null || install_phpcomposer
        # composer require kyranrana/cloudflare-bypass
        
        try mkdir -p "$HOME"/.local/share/applications/

        if [ -f "$HOME"/.local/share/applications/zdl-web-ui.desktop ]     
        then
            eval line_cmd=( $(grep Exec "$HOME"/.local/share/applications/zdl-web-ui.desktop) )

            for dir in "${line_cmd[@]}"
            do
                if [ -d "$dir" ]
                then
                    break

                else
                    unset dir
                fi
            done
        fi

        [ -z "$dir" ] &&
            dir="$HOME"
            
        sed -r "s|^Exec=.+$|Exec=zdl --web-ui \"$dir\"|g" \
            -i /usr/local/share/zdl/webui/zdl-web-ui.desktop
        
        try cp /usr/local/share/zdl/webui/zdl-web-ui.desktop "$HOME"/.local/share/applications/
        try desktop-file-install "$HOME"/.local/share/applications/zdl-web-ui.desktop

        try cp /usr/local/share/zdl/gui/zdl-gui.desktop "$HOME"/.local/share/applications/
        try desktop-file-install "$HOME"/.local/share/applications/zdl-gui.desktop
    fi
    
    check_default_downloader

    #### aggiornamento versione da URL_ROOT
    echo "$remote_version" >"$path_conf"/version
    
    print_c 1 "$(gettext "Successfully completed")"
    
    if [ -z "$installer_zdl" ]
    then
        if [ "$real_mode" == gui ]
        then
            this_mode=gui
            yad --title="$(gettext "ZigzagDownLoader update")" \
                --text="$(gettext "ZigzagDownLoader updated with success")" \
                --image="$IMAGE2" \
                --center \
                --on-top \
                "${YAD_ZDL[@]}" \
                --button="$(gettext "Close")!gtk-close:1" \
                --button="$(gettext "Restart ZDL")!gtk-execute:0"

            case $? in
                0)
                    kill -9 $pid_console_gui
                    cd $dir_dest

                    stop_daemon_gui
                    kill_yad_multiprogress

                    source "$path_usr"/source_all.sh
                    run_gui &>/dev/null &
                    disown

                    set -o history                    
                    exit
                    ;;
                1)
                    kill -9 $pid_console_gui
                    set -o history
                    exit 1
                    ;;
            esac
            
        else
            pause
            cd $dir_dest
            $prog "${args[@]}"
            
            set -o history
            exit
        fi
    fi
    set -o history
}
