/** @format */

//  ZigzagDownLoader (ZDL)
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published
//  by the Free Software Foundation; either version 3 of the License,
//  or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/.
//
//  Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
//
//  For information or to collaborate on the project:
//  https://savannah.nongnu.org/projects/zdl

/* jshint esversion: 7 */

/* Handling the 'click' event of buttons */
function buttonHandler( e ) {
    var target = $( e.target ),
        id = e.target.id,
        obj = {
            "downloads-clean": downloads.clean,
            "action-path-toggle": common.browseFsToggle,
            "action-path-save": manage.changePath,
            "free-space-update": manage.updateSpace,
            "add-link-send": manage.addLink,
            "edit-links-toggle": manage.toggleLinks,
            "edit-links-save": manage.saveLinks,
            "edit-links-delete": manage.deleteLinks,
            "xdcc-send": manage.addXdcc,
            "irc-host-clean": manage.cleanXdcc,
            "irc-channel-clean": manage.cleanXdcc,
            "irc-bot-clean": manage.cleanXdcc,
            "irc-slot-clean": manage.cleanXdcc,
            "xdcc-clean-all": manage.cleanXdcc,
            "add-torrent-toggle": common.browseFsToggle,
            "add-torrent-send": manage.addTorrent,
            "links-file-toggle": common.readFileToggle,
            "links-file-delete": common.deleteFile,
            "local-max-downloads-save": manage.maxDownload,
            "reconnect-modem": manage.reconnectModem,
            "get-ip": manage.getIP,
            "zdl-quit": manage.quitZDL,
            "zdl-killall": manage.killallZDL,
            "zdl-run": manage.runZDL,
            "xdcc-search-exec": xdcc.search,
            "playlist-toggle": common.browseFsToggle,
            "playlist-play": playlist.play,
            "playlist-save": playlist.add,
            "new-socket-start": sockets.new,
            "socket-kill-this": sockets.kill,
            "downloads-killall": sockets.killDownloads,
            "axel-connections-save": common.setNumericValue,
            "aria2-connections-save": common.setNumericValue,
            "max-downloads-save": common.setNumericValue,
            "player-toggle": common.browseFsToggle,
            "player-save": common.setApplication,
            "editor-toggle": common.browseFsToggle,
            "editor-save": common.setApplication,
            "browser-toggle": common.browseFsToggle,
            "browser-save": common.setApplication,
            "launcher-toggle": common.browseFsToggle,
            "launcher-save": config.pathLauncher,
            "torrent-tcp-save": common.setNumericValue,
            "torrent-udp-save": common.setNumericValue,
            "socket-tcp-save": common.setNumericValue,
            "reconnecter-toggle": common.browseFsToggle,
            "reconnecter-save": common.setApplication,
            "account-reset": config.resetAccount,
            "zdl-log-toggle": common.readFileToggle,
            "zdl-log-delete": common.deleteFile,
            "console-clean": zdlconsole.clean,
            "webui-info-toggle": info.toggleWebuiInfo,
            "exit": exit.shutdown
        };

    if ( typeof obj[ id ] === "function" ) {
        obj[ id ]( target );
    } else {
        handleByClasses( target );
    }
}

/* Handling dynamically added buttons by checking for class name */
function handleByClasses( target ) {
    var obj = {
            "open-info": downloads.toggleInfo,
            "play-file": common.playFile,
            "dl-manage": downloads.manage,
            "dl-playlist": downloads.toPlaylist,
            "dl-stop": downloads.stop,
            "dl-delete": downloads.delete,
            "pl-remove": playlist.remove,
            "to-mp3": playlist.extractMp3,
            "xdcc-search-send": xdcc.add,
            "socket": sockets.manage
        },
        classes = target.attr( "class" ).split( " " ),
        classname;

    $.each( classes, function ( i, c ) {
        if ( obj.hasOwnProperty( c ) ) {
            classname = c;
        }
    } );

    if ( typeof obj[ classname ] === "function" ) {
        obj[ classname ]( target );
    } else {
        utils.log( "button-error", target[ 0 ].id, true );
    }
}

/* Handling the 'change' event of select menu */
function selectMenuHandler( id, value ) {
    var obj = {
        "local-downloader": manage.downloader,
        "reconnect": manage.reconnectionOption,
        "webui": config.webui,
        "language": config.language,
        "downloader": config.downloader,
        "bg-terminal": config.xtermBackground,
        "auto-update": config.autoUpdate,
        "resume": config.resume,
        "start-mode": config.startMode
    };

    if ( typeof obj[ id ] === "function" ) {
        obj[ id ]( value );
    } else {
        utils.log( "select-error", id, true );
    }
}

/* Handling the 'create' event of spinners setting the range of numeric values */
function spinnersSetRange( id, spinner ) {
    var obj = {
        "max-xdcc": [
            1, 100
        ],
        "new-socket": [
            8080, 65535
        ],
        "torrent-tcp": [
            1025, 65535
        ],
        "torrent-udp": [
            1025, 65535
        ],
        "socket-tcp": [ 8080, 65535 ]
    };

    if ( obj.hasOwnProperty( id ) && typeof obj[ id ] === "object" ) {
        spinner.spinner( {
            min: obj[ id ][ 0 ],
            max: obj[ id ][ 1 ]
        } );
    } else {
        utils.log( "set-spinner-error", id, true );
    }
}

/* Handling the 'create' event of sliders setting the range of numeric values */
function slidersSetRange( id, slider ) {
    var obj = {
        "local-max-downloads": [
            1, 50
        ],
        "axel-parts": [
            1, 48
        ],
        "aria2-connections": [
            1, 32
        ],
        "max-downloads": [ 1, 50 ]
    };

    if ( obj.hasOwnProperty( id ) && typeof obj[ id ] === "object" ) {
        slider.slider( {
            min: obj[ id ][ 0 ],
            max: obj[ id ][ 1 ]
        } );
    } else {
        utils.log( "set-slider-error", id, true );
    }
}
