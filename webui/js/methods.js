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

/**
 *	DOWNLOADS :: Tab 1
 */
var downloads = {
    // Delete progressbar of completed downloads
    clean: function () {
        myZDL.cleanCompleted().then( function () {
            var uibar;
            $( ".download" ).each( function () {
                uibar = $( this ).find( ".ui-progressbar" );
                if ( uibar.attr( "aria-valuenow" ) === "100" ) {
                    client.remove( "list", uibar.attr( "id" ).substring( 4 ) );
                    $( this ).remove();
                }
            } );
            utils.updateCounters();
            utils.log( "downloads-completed-cleaned" );
        } );
    },

    // Toggle view of download Info
    toggleInfo: function ( elem ) {
        $( "#" + elem.data( "toggle" ) ).toggle( "blind", null, 500, function () {
            if ( $( this ).is( ":visible" ) ) {
                elem.button( "option", "label", $.i18n( "button-close" ) );
            } else {
                elem.button( "option", "label", $.i18n( "button-info" ) );
            }
        } );
    },

    // Manage download acting in the right path
    manage: function ( elem ) {
        var path = elem.data( "path" );
        if ( path !== myZDL.path ) {
            myZDL.initClient( path ).then( function () {
                utils.log( "client-init", path );
            } ).catch( function ( e ) {
                utils.log( "client-init-error", e, true );
            } );
        }
        utils.switchToTab( 1 );
    },

    // Add file downloaded to the playlist
    toPlaylist: function ( elem ) {
        var filePath = elem.data( "file" );
        myZDL.playlistAdd( filePath ).then( function ( res ) {
            var response = res.trim();
            if ( response === "Non è un file audio/video" ) {
                utils.log( "playlist-file-incorrect", filePath, true );
            } else if ( response === "Errore durante l'analisi del json della playlist" ) {
                utils.log( "playlist-json-corrupted", null, true );
            } else {
                utils.addToPlaylist( filePath );
                utils.log( "playlist-file-added", filePath );
                elem.button( "option", {
            		label: $.i18n( "button-playlist-added" ),
            		classes: {
                		"ui-button": "ui-corner-all button-action-done"
            		}
        		} );
            }
        } );
    },

    // Stop download
    stop: function ( elem ) {
        var link = elem.data( "link" );
        myZDL.stopLink( encodeURIComponent( link ) ).then( function () {
            utils.log( "download-stopped", link );
        } );
    },

    // Delete download
    delete: function ( elem ) {
        var path = elem.data( "path" ),
            link = elem.data( "link" ),
            fileName = elem.data( "file" );
        myZDL.deleteLink( encodeURIComponent( link ), path ).then( function () {
            elem.closest( ".download" ).remove();
            if ( client.exist( "active", fileName ) ) {
                client.remove( "active", fileName );
            }
            client.remove( "list", $.md5( link ) );
            utils.updateCounters();
            utils.log( "download-deleted", fileName );
        } );
    }
};

/**
 *	MANAGE :: Tab 2
 */
var manage = {
    // Change the webui action path
    changePath: function ( elem ) {
        var path = elem.prev().val();
        if ( utils.validateInput( path, "path" ) ) {
            myZDL.initClient( path ).then( function () {
                utils.log( "client-init-new", path );
                $( "#action-path-toggle" ).trigger( "click" );
            } ).catch( function ( e ) {
                utils.log( "client-init-error", e, true );
            } );
        } else {
            utils.log( "path-incorrect", path, true );
        }
    },

    // Select an active action path
    selectPath: function ( value ) {
        if ( value !== myZDL.path ) {
            myZDL.initClient( value ).then( function () {
                utils.log( "client-init", value );
            } ).catch( function ( e ) {
                utils.log( "client-init-error", e, true );
            } );
        }
    },

    // Get and display free space in the path
    updateSpace: function ( elem ) {
        myZDL.getFreeSpace().then( function ( res ) {
            elem.prev().text( res );
            utils.log( "free-space-updated", res );
        } );
    },

    // Send a new link
    addLink: function ( elem ) {
        var input = elem.prev(),
            link = input.val();
        if ( link ) {
            if ( utils.validateInput( link, "URL" ) ) {
                myZDL.addLink( link ).then( function () {
                    input.val( "" );
                    utils.log( "link-added", link );
                    utils.switchToTab( 0 );
                } );
            } else {
                input.val( "" );
                utils.log( "link-incorrect", link, true );
            }
        }
    },

    // Toggle view of links in the queue
    toggleLinks: function ( elem ) {
        $( "#" + elem.data( "toggle" ) ).toggle( "blind", null, 500, function () {
            if ( $( this ).is( ":visible" ) ) {
                elem.button( "option", "label", $.i18n( "button-close" ) );
                var textArea = $( this ).children( "textarea" );
                myZDL.getLinks().then( function ( links ) {
                    if ( links && links.length > 10 ) {
                        textArea.val( decodeURIComponent( links ).replace( /\n$/, "" ) );
                    } else {
                        textArea.val( "" );
                    }
                } );
            } else {
                elem.button( "option", "label", $.i18n( "button-open" ) );
            }
        } );
    },

    // Edit and save links in the queue
    saveLinks: function ( elem ) {
        var links = elem.prev().prev().val();
        if ( links ) {
            var splitted = links.split( "\n" ),
                pass = true;
            $.each( splitted, function ( index, item ) {
                if ( !utils.validateInput( item, "URL" ) ) {
                    utils.log( "links-edited-incorrect", item, true );
                    pass = false;
                }
            } );
            if ( pass ) {
                myZDL.command( "set-links", "links=" + encodeURIComponent( links ) ).then( function () {
                    utils.log( "links-edited" );
                    $( "#edit-links-toggle" ).trigger( "click" );
                } );
            }
        }
    },

    // Delete the queue
    deleteLinks: function ( elem ) {
        var links = elem.parent().children( ":first" ).val();
        if ( links ) {
            myZDL.command( "set-links", "links=" ).then( function () {
                utils.log( "links-deleted" );
            } );
            $( "#edit-links-toggle" ).trigger( "click" );
        }
    },

    // Send an xdcc command
    addXdcc: function () {
        var host = $( "#irc-host" ).val(),
            chan = $( "#irc-channel" ).val(),
            bot = $( "#irc-bot" ).val(),
            slot = $( "#irc-slot" ).val(),
            msg = "/msg " + bot + " xdcc send " + slot,
            xdcc = "irc://" + host + "/" + chan + msg;
        if ( utils.validateInput( xdcc, "URL" ) ) {
            var req = {
                host: host,
                channel: encodeURIComponent( chan ),
                msg: encodeURIComponent( msg )
            };
            myZDL.addXdcc( req ).then( function ( res ) {
                var response = res.trim();
                if ( response ) {
                    utils.log( "xdcc-exist", xdcc, true );
                } else {
                    utils.log( "xdcc-added", xdcc );
                }
                $( "#xdcc-clean-all" ).trigger( "click" );
            } );
        } else {
            utils.log( "xdcc-incorrect", xdcc, true );
        }
    },

    // Clean xdcc inputs
    cleanXdcc: function ( elem ) {
        if ( elem.hasClass( "clean-all" ) ) {
            $( ".xdcc" ).val( "" );
        } else {
            elem.prev().val( "" );
        }
    },

    // Send a torrent
    addTorrent: function ( elem ) {
        var input = elem.prev(),
            torrent = input.val();
        if ( torrent ) {
            if ( utils.validateInput( torrent, "path" ) ) {
                myZDL.addTorrent( torrent ).then( function () {
                    input.val( "" );
                    utils.log( "torrent-added", torrent );
                    $( "#add-torrent-toggle" ).trigger( "click" );
                } );
            } else {
                input.val( "" );
                utils.log( "path-incorrect", torrent, true );
            }
        }
    },

    // Set the max number of parallel downloads in the path
    maxDownload: function ( elem ) {
        var value = elem.prev().children().text();
        myZDL.command( "set-max-downloads", "number=" + value ).then( function () {
            utils.log( "set-local-max-dl", value );
            utils.success( elem.next() );
        } );
    },

    // Set the downloader to use in the path
    downloader: function ( val ) {
        myZDL.command( "set-downloader", "downloader=" + val ).then( function () {
            utils.log( "set-local-downloader", val );
        } );
    },

    // Set options for the modem reconnection
    reconnectionOption: function ( val ) {
        var option = "false";
        if ( val !== "disabled" ) {
            option = "true";
        }
        myZDL.command( "reconnect", "set=" + option ).then( function ( res ) {
            var response = res.trim();
            if ( response ) {
                if ( response === "Non hai ancora configurato ZDL per la riconnessione automatica" ) {
                    utils.log( "reconnecter-not-configured", null, true );
                } else {
                    utils.log( response, null, true );
                }
                $( "#reconnect" ).val( "disabled" );
                $( ".selectmenu" ).selectmenu( "refresh" );
            } else {
                utils.log( "set-modem-reconnection", val );
            }
        } );
    },

    // Reconnect modem
    reconnectModem: function () {
        myZDL.modemReconnect().then( function ( res ) {
            var response = res.trim();
            if ( response ) {
                if ( response === "Non hai ancora configurato ZDL per la riconnessione automatica" ) {
                    utils.log( "modem-reconnection-failure", null, true );
                } else {
                    utils.log( response, null, true );
                }
            } else {
                utils.log( "modem-reconnected" );
            }
        } );
    },

    // Get and display the IP address
    getIP: function ( elem ) {
        myZDL.getIP().then( function ( res ) {
            var match = res.match( /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ );
            if ( match ) {
                elem.next().val( match[ 0 ] );
                utils.log( "get-IP", match[ 0 ] );
            } else {
                elem.next().val( "---" );
                utils.log( "get-IP-failure", null, true );
            }
        } );
    },

    // Quit ZDL
    quitZDL: function ( elem ) {
        elem.siblings( ":last" ).removeClass( "hidden" );
        myZDL.quit().then( function () {
            utils.log( "zdl-stopped" );
        } );
    },

    // Quit ZDL and kill all downloads
    killallZDL: function ( elem ) {
        elem.siblings( ":last" ).removeClass( "hidden" );
        myZDL.kill().then( function () {
            utils.log( "zdl-killed" );
        } );
    },

    // Run ZDL
    runZDL: function ( elem ) {
        elem.next().removeClass( "hidden" );
        myZDL.run().then( function () {
            utils.log( "zdl-started" );
        } );
    }
};

/**
 *	SEARCH :: Tab 3
 */
var xdcc = {
    // Search xdcc on xdcc.eu
    search: function ( elem ) {
        var input = elem.prev(),
            term = input.val(),
            table = client.table();
        table.clear().draw();
        if ( term ) {
            myZDL.searchXdcc( term ).then( function ( res ) {
                if ( res !== "failure" ) {
                    var max = $( "#max-xdcc" ).val();
                    try {
                        var obj = JSON.parse( res ),
                            send = $.i18n( "button-send" );
                        $.each( obj, function ( i, o ) {
                            table.row.add( [
                                i + 1,
                                o.name,
                                o.length,
                                o.server,
                                o.channel,
                                o.bot,
                                o.slot,
                                o.gets,
                                "<button data-i18n='button-send' class='button xdcc-search-send'>" + send + "</button>"
                            ] ).draw( false );
                            if ( i === max - 1 ) {
                                return false;
                            }
                        } );
                    } catch ( error ) {
                        utils.log( "xdcc-search-error", error, true );
                    }
                    $( ".xdcc-search-send" ).button();
                    input.val( "" );
                    table.columns.adjust().responsive.recalc();
                } else {
                    input.val( $.i18n( "xdcc-search-no-results" ) );
                }
            } );
            utils.log( "xdcc-search", term );
            input.val( $.i18n( "xdcc-serching" ) );
        } else {
            input.val( $.i18n( "xdcc-search-no-term" ) );
        }
    },

    // Send found xdcc from the search table
    add: function ( elem ) {
        var tr = elem.closest( "tr" );
        var xdccreq = {
            host: tr.children().eq( 3 ).text(),
            channel: encodeURIComponent( tr.children().eq( 4 ).text() ),
            msg: encodeURIComponent( "/msg " + tr.children().eq( 5 ).text() + " xdcc send " + tr.children().eq( 6 ).text() )
        };
        elem.button( "option", {
            label: "",
            disabled: true,
            icon: "ui-icon-check",
            classes: {
                "ui-button": "ui-corner-all button-action-done"
            }
        } );
        myZDL.addXdcc( xdccreq ).then( function ( res ) {
            var response = res.trim();
            if ( response ) {
                utils.log( "xdcc-exist", response, true );
            } else {
                utils.log( "xdcc-added", "irc://" + xdccreq.host + "/" + decodeURIComponent( xdccreq.channel ) + decodeURIComponent( xdccreq.msg ) );
            }
        } );
    }
};

/**
 *	PLAYLIST :: Tab 4
 */
var playlist = {
    // Play all audio in the playlist
    play: function () {
        var files = $( "#playlist .audio" ),
            list = "";
        if ( files ) {
            $.each( files, function () {
                list += $( this ).data( "file" ) + "€€€";
            } );
            if ( list ) {
                list = list.slice( 0, -3 );
                myZDL.playPlaylist( list ).then( function ( res ) {
                    var response = res.trim();
                    if ( /^\d+$/.test( response ) ) {
                        utils.log( "play-playlist", response );
                        if ( files.length > parseInt( response ) ) {
                            utils.log( "play-playlist-audio-not-played", files.length - parseInt( response ), true );
                        }
                    } else {
                        if ( response === "Nessun file audio trovato" ) {
                            utils.log( "play-playlist-audio-not-found", null, true );
                        } else if ( response === "Player non trovato" ) {
                            utils.log( "player-not-found", null, true );
                        } else {
                            utils.log( "player-not-configured", null, true );
                        }
                    }
                } );
            } else {
                utils.log( "play-playlist-no-audio", null, true );
            }
        } else {
            utils.log( "play-playlist-empty" );
        }
    },

    // Add file to the playlist
    add: function ( elem ) {
        var filePath = elem.prev().val();
        if ( utils.validateInput( filePath, "path" ) ) {
            myZDL.playlistAdd( filePath ).then( function ( res ) {
                var response = res.trim();
                if ( response === "Non è un file audio/video" ) {
                    utils.log( "playlist-file-incorrect", filePath, true );
                } else if ( response === "Errore durante l'analisi del json della playlist" ) {
                    utils.log( "playlist-json-corrupted", null, true );
                } else {
                    utils.addToPlaylist( filePath );
                    utils.log( "playlist-file-added", filePath );
                    utils.success( elem.next() );
                }
            } );
        } else {
            utils.log( "playlist-path-incorrect", filePath, true );
        }
    },

    // Remove file from playlist
    remove: function ( elem ) {
        var filePath = elem.data( "file" );
        myZDL.playlistDelete( filePath ).then( function ( res ) {
            $( "#playlist" ).empty();
            if ( utils.parseJson( res ) ) {
                utils.buildPlaylist( JSON.parse( res ) );
                utils.log( "playlist-file-removed", filePath );
            } else {
                utils.log( "playlist-json-corrupted", null, true );
            }
        } );
    },

    // Extract audio from video
    extractAudio: function ( elem ) {
        var filePath = elem.data( "file" ),
            format = client.get( "audio" );
        elem.button( {
            label: $.i18n( "wait" ),
            disabled: true
        } );
        myZDL.extractAudio( filePath, format ).then( function ( res ) {
            var response = res.trim();
            if ( response === "success" ) {
                utils.log( "playlist-video-to-audio", filePath );
                elem.remove();
                var audio = filePath.substr( 0, filePath.lastIndexOf( "." ) ) + "." + format;
                myZDL.playlistAdd( audio ).then( function ( res ) {
                    response = res.trim();
                    if ( response === "Non è un file audio/video" ) {
                        utils.log( "playlist-file-incorrect", audio, true );
                    } else {
                        utils.addToPlaylist( audio );
                        utils.log( "playlist-file-added", audio );
                    }
                } );
            } else {
                if ( response === "ffmpeg non trovato" ) {
                    utils.log( "playlist-video-ffmpeg-not-found", null, true );
                } else {
                    utils.log( "playlist-video-to-audio-not-found", filePath, true );
                }
                elem.button( {
                    label: "Audio",
                    disabled: false
                } );
            }
        } );
    }
};

/**
 *	LIVESTREAM :: Tab 5
 */
var livestream = {
    // Schedule a new download
    set: function () {
        var channel = null;
        $( ".livestream-channels > input" ).each( function () {
            if ( $( this ).prop( "checked" ) ) {
                channel = $( this ).val();
            }
        } );
        // #zoninoz
        if ( $( "#link-livestream" ).is( ":visible" ) ) {
            var link = $( "#add-link-livestream" ).val();
            if ( utils.validateInput( link, "URL" ) ) {
                channel = link;
                utils.log( "link-added", link );
            } else {
                $( "#add-link-livestream" ).val( "" );
                utils.log( "link-incorrect", link, true );
            }
        }
        // #zoninoz-end
        if ( channel ) {
            var start = $( "#start-rec" ).val(),
                duration = $( "#duration-rec" ).val(),
                channels = client.get( "channels" );

            if ( $( "#tomorrow-time" ).prop( "checked" ) ) {
                start += "tomorrow";
            }
            myZDL.setLivestream( myZDL.path, channel, start, duration ).then( function ( res ) {
                var response = res.trim();
                if ( response ) {
                    var sched = channels[ channel ] + " | " + start + " | " + duration;
                    utils.log( "livestream-scheduled", sched );
                } else {
                    utils.log( "livestream-scheduled-failure", null, true );
                }
            } );
        } else {
            utils.log( "livestream-scheduled-no-channel", null, true );
        }
    },

    // Delete scheduled download
    delete: function ( elem ) {
        var link = elem.data( "link" ),
            path = elem.data( "path" ),
            channels = client.get( "channels" );
        myZDL.deleteLink( encodeURIComponent( link ), path ).then( function () {
            var elem = $( "button.dl-delete[data-link='" + link + "']" );
            if ( elem.length ) {
                downloads.delete( elem );
            }
            utils.log( "livestream-delete", channels[ link.slice( 0, link.lastIndexOf( "#" ) ) ] );
        } );
    },

    /* #zoninoz: get livestream link of Youtube/Dailymotion channels */
    getLivestreamLink: function () {
        $( ".livestream-channels > input" ).each( function () {
            if ( $( this ).prop( "checked" ) ) {
                channel = $( this ).val();
            }
        } );
        var pattern = /(youtube|dailymotion)/;
        if (pattern.exec ( channel ) === null &&
            $( "#link-livestream" ).is( ":visible" ) ) {            
            $( "#link-livestream" ).toggle( "blind", null, 500, function () {
                if ( $( this ).is( ":hidden" ) ) {
                    $( "#link-livestream" ).html( "" );
                }
            });
        }
        else if (pattern.exec ( channel ) !== null &&
            $( "#link-livestream" ).is( ":hidden" ) ) {

            $( "#link-livestream" ).toggle( "blind", null, 500, function () {
                if ( $( this ).is( ":visible" ) ) {
                    var content = `<div class="inline-group" style="width: 100%; margin: 0px;">
                    <div data-i18n="tab-2-label-url" class="label">Add URL:</div><input id="add-link-livestream" type="text" placeholder="http(s)://(youtube|dailimotion).com/path/params"></div>`;                    
                    $( this ).html( content );
                    $( this ).i18n( "tab-5-label-url" );
                } else {
                    $( this ).html( "" );
                    alert ("else");
                }
            } );
        }
    }   
};

/**
 *	SOCKETS :: Tab 6
 */
var sockets = {
    // Start a new socket
    new: function ( elem ) {
        var port = elem.prev().children( ".spinner" ).spinner( "value" );
        myZDL.startSocket( port ).then( function ( res ) {
            var response = res.trim();
            if ( response === "already-in-use" ) {
                utils.log( "socket-port-unavailable", port, true );
            } else {
                utils.log( "socket-started", port );
            }
        } );
    },

    // Open a webui to a new socket address or kill running socket
    manage: function ( elem ) {
        var port = elem.text();
        if ( elem.parent().hasClass( "sockets-go" ) ) {
            utils.log( "webui-new-port", port );
            window.open( document.location.protocol + "//" + document.location.hostname + ":" + port );
        } else {
            myZDL.killSocket( port ).then( function () {
                utils.log( "socket-killed", port );
                if ( port === document.location.port ) {
                    window.setTimeout( function () {
                        $( "body" ).empty().append( "<p class='centered'>ZDL web UI is turned off. See you later :)</p>" );
                    }, 2000 );
                }
            } );
        }
    },

    // Kill active socket
    kill: function () {
        var port = document.location.port;
        myZDL.killSocket( port ).then( function () {
            window.setTimeout( function () {
                window.location.href = window.location.pathname;
            }, 2000 );
        } );
    },

    // Kill all downloads
    killDownloads: function () {
        myZDL.killAll().then( function () {
            utils.log( "downloads-terminated" );
        } );
    }
};

/*
 *	CONFIGURATION :: Tab 7
 */
var config = {
    // Set and change the webUI
    webui: function ( val ) {
        $( "#refresh" ).removeClass( "hidden" );
        myZDL.setConf( "web_ui", val ).then( function () {
            window.setTimeout( function () {
                window.location.href = window.location.pathname;
            }, 2000 );
        } );
    },

    // Set and change the webUI language
    language: function ( val ) {
        myZDL.setConf( "language", val ).then( function () {
            $.i18n().locale = val;
            $( "body" ).i18n();
            utils.localizeHard();
            client.tableInit( val );
            client.set( "locale", val );
            utils.log( "set-language", val.toUpperCase() );
        } );
    },

    // Set default downloader
    downloader: function ( val ) {
        myZDL.setConf( "downloader", val ).then( function () {
            utils.log( "set-downloader", val );
        } );
    },

    // Set the background color of virtual terminal
    xtermBackground: function ( val ) {
        myZDL.setConf( "background", val ).then( function () {
            utils.log( "set-terminal-bg", val );
        } );
    },

    // Set path in the command of ZDL launcher
    pathLauncher: function ( elem ) {
        var path = elem.prev().val();
        if ( utils.validateInput( path, "path" ) ) {
            myZDL.setDesktopPath( path ).then( function () {
                utils.log( "set-path-launcher", path );
                $( "#launcher-toggle" ).trigger( "click" ).prev().val( path );
            } );
        } else {
            utils.log( "path-incorrect", path, true );
        }
    },

    // Set automatic update
    autoUpdate: function ( val ) {
        myZDL.setConf( "autoupdate", val ).then( function () {
            utils.log( "set-auto-update", $.i18n( "option-" + val ) );
        } );
    },

    // Set files overwriting
    resume: function ( val ) {
        myZDL.setConf( "resume", val ).then( function () {
            utils.log( "set-file-overwrite", $.i18n( "option-" + val ) );
        } );
    },

    // Set start mode
    startMode: function ( val ) {
        myZDL.setConf( "zdl_mode", val ).then( function () {
            utils.log( "set-zdl-start-mode", val );
        } );
    },

    // Reset webui account
    resetAccount: function () {
        myZDL.reset().then( function () {
            window.location.href = "login.html";
        } );
    }
};

/**
 *	CONSOLE :: Tab 8
 */
var zdlconsole = {
    // Set active path
    startDownloadLog: function ( val ) {
        $( "#console-path" ).val( val );
        utils.log( "console-download-log-start" );
        zdlconsole.getDownloadLog( val, false );
    },

    // Display the download log flow
    getDownloadLog( path, loop ) {
        var inDialog = $( "#log-dialog" ).prop( "checked" ),
            textArea;
        if ( inDialog ) {
            textArea = $( "#dialog-download-log" );
        } else {
            textArea = $( "#download-log" );
        }
        if ( path === $( "#console-path" ).val() ) {
            myZDL.getConsoleLog( path, loop ).then( function ( res ) {
                var content = textArea.val() + res;
                textArea.val( content ).animate( {
                    scrollTop: textArea.prop( "scrollHeight" ) - textArea.height()
                }, 1000 );
                zdlconsole.getDownloadLog( path, true );
            } );
        }
    },

    // Clean the download log
    cleanDownloadLog( elem ) {
        elem.prev().val( "" );
    },

    // Stop the download log flow
    stopDownloadLog( elem ) {
        var path = $( "#console-path" );
        if ( path.val() ) {
            path.val( "" );
            myZDL.stopConsoleLog().then( function () {
                $( "#console-path-select option" ).first().prop( "selected", true );
                $( "#console-path-select" ).selectmenu( "refresh" );
                utils.log( "console-download-log-stop" );
            } );
        }
    },

    // Clean all console entries
    cleanEvents: function ( elem ) {
        elem.parent().prev().text( "" );
        utils.log( "console-events-cleaned" );
    }
};

/**
 *	INFO :: Tab 9
 */
var info = {
    // Toggle info on webui
    toggleWebuiInfo: function ( elem ) {
        $( "#" + elem.data( "toggle" ) ).toggle( "blind", null, 500, function () {
            if ( $( this ).is( ":visible" ) ) {
                elem.button( "option", "label", $.i18n( "button-close" ) );
                var textArea = $( this ).children( "textarea" ),
                    lang = client.get( "locale" ),
                    read = $.get( "webui-" + lang + ".txt" );
                read.done( function ( res ) {
                        textArea.val( res );
                    } )
                    .fail( function () {
                        utils.log( "webui-info-error" );
                    } );
            } else {
                elem.button( "option", "label", $.i18n( "button-open" ) );
            }
        } );
    }
};

/**
 *	EXIT :: Tab 10
 */
var exit = {
    // Terminate all and shutdown the server
    shutdown: function ( elem ) {
        elem.button( "option", {
            classes: {
                "ui-button": "ui-corner-all button-state-exiting"
            },
            disabled: true
        } );
        myZDL.exitAll().then( function () {
            var wrapper = $( ".wrapper" ).addClass( "exit" ),
                lang = client.get( "locale" );
            setTimeout( function () {
                wrapper.prepend( "<div class='ring-container'><progress-ring stroke='6' radius='100' progress='100'></progress-ring></div>" ).hide().fadeIn(2000);
                animateRing( lang );
            }, 400 );
            console.log( "ZDL web UI closed" );
        } );
    }
};

/**
 *	COMMON
 */
var common = {
    /*
     *	Set numeric configuration values from spinners/sliders
     *	Tab: 7
     *  Sliders: Axel parts, Aria2 connections, Max parallel download
     *	Spinners: torrent TCP/UDP port, socket TCP port
     */
    setNumericValue: function ( elem ) {
        var supplier = elem.prev().children(),
            value = supplier.val() || supplier.text();
        if ( value && !isNaN( value ) ) {
            var key = elem.data( "key" ),
                msg = "set-" + key.replace( "_", "-" );
            myZDL.setConf( key, value ).then( function () {
                utils.log( msg, value );
                utils.success( elem.next() );
            } );
        }
    },

    /*
     *	Set applications
     *	Tab: 7
     *	App: player, editor, browser, reconnecter
     */
    setApplication: function ( elem ) {
        var input = elem.prev(),
            filepath = input.val();
        if ( filepath ) {
            if ( utils.validateInput( filepath, "path" ) ) {
                var key = elem.data( "key" ),
                    toggle = key + "-toggle";
                myZDL.setConf( key, filepath ).then( function () {
                    input.val( "" );
                    utils.log( "set-" + key, filepath );
                    $( "#" + toggle ).trigger( "click" );
                } );
            } else {
                utils.log( "path-incorrect", filepath, true );
            }
        }
    },

    /*
     *	Toggle view of directory tree
     *	Tab: 2, 4, 7
     *	Views: action path, torrent, playlist, player, editor, browser, launcher, reconnecter
     */
    browseFsToggle: function ( elem ) {
        var toggle = elem.data( "toggle" );
        $( "#" + toggle ).toggle( "blind", null, 500, function () {
            if ( $( this ).is( ":visible" ) ) {
                elem.button( "option", "label", $.i18n( "button-close" ) );
                var path = function () {
                        return toggle === "path-launcher-browse" ?
                            elem.prev().val() :
                            myZDL.path;
                    },
                    id = toggle.slice( 0, -7 ),
                    type = elem.data( "type" );
                utils.browseFs( path(), id, type );
            } else {
                elem.button( "option", "label", $.i18n( "button-select" ) );
            }
        } );
    },

    /*
     *  Toggle view of txt files
     *  Tab: 2, 8
     *  Files: links.txt, zdl_log.txt
     */
    readFileToggle: function ( elem ) {
        var toggle = elem.data( "toggle" );
        $( "#" + toggle ).toggle( "blind", null, 500, function () {
            if ( $( this ).is( ":visible" ) ) {
                elem.button( "option", "label", $.i18n( "button-close" ) );
                var textArea = $( this ).children( "textarea" ),
                    fileName = elem.data( "file" );
                myZDL.getFile( fileName ).then( function ( res ) {
                    if ( res ) {
                        textArea.val( res.replace( /(<br>)/gi, "" ) ).animate( {
                            scrollTop: textArea.prop( "scrollHeight" ) - textArea.height()
                        }, 1000 );
                    } else {
                        textArea.val( $.i18n( "file-not-found" ) );
                    }
                    textArea.scrollTop = textArea.scrollHeight;
                } );
            } else {
                elem.button( "option", "label", $.i18n( "button-open" ) );
            }
        } );
    },

    /*
     *  Delete text files
     *  Tab: 2, 8
     *  Files: links.txt, zdl_log.txt
     */
    deleteFile: function ( elem ) {
        var textArea = elem.prev(),
            content = textArea.val();
        if ( content && content !== $.i18n( "file-not-found" ) ) {
            var fileName = elem.data( "file" ),
                toggle = elem.data( "trigger" );
            myZDL.deleteFile( fileName ).then( function () {
                textArea.val( "" );
                utils.log( "file-deleted", fileName );
                $( "#" + toggle ).trigger( "click" );
            } );
        }
    },

    /*
     *  Play files
     *  Tab: 1, 4
     *  Files: audio/video
     */
    playFile: function ( elem ) {
        var filePath = elem.data( "file" );
        myZDL.playMedia( filePath ).then( function ( res ) {
            var response = res.trim();
            if ( response === "running" ) {
                utils.log( "play-file", filePath );
            } else {
                if ( response === "Player non trovato" ) {
                    utils.log( "player-not-found", null, true );
                } else if ( response === "Non è un file audio/video" ) {
                    utils.log( "play-file-incorrect", filePath, true );
                } else if ( response === "File non trovato" ) {
                    utils.log( "play-file-not-found", filePath, true );
                } else {
                    utils.log( "player-not-configured", null, true );
                }
            }
        } );
    }
};

/**
 *	UTILS
 */
var utils = {
    /* Logging events and errors to the Console tab */
    log: function ( key, param, error = false ) {
        if ( client.get( "log" ) === "all" || error ) {
            var to2 = function ( i ) {
                    if ( i < 10 ) {
                        return "0" + i;
                    }
                    return i;
                },
                date = new Date(),
                time = to2( date.getHours() ) + ":" + to2( date.getMinutes() ) + ":" + to2( date.getSeconds() ),
                row = "row",
                msg,
                node,
                dialog = client.get( "dialog" );

            if ( param ) {
                msg = $.i18n( key, param );
            } else {
                msg = $.i18n( key );
            }

            if ( error ) {
                row += " error";
                utils.switchToTab( 7 );
            }

            node = "<div class='" + row + "'><div class='time'>" + time + "</div><div>" + msg + "</div></div>";
            if ( dialog.open && dialog.service === "events" ) {
                $( "#dialog #dialog-events" ).prepend( node );
            } else {
                $( "#events" ).prepend( node );
            }
        }
    },

    /* Validate json */
    parseJson: function ( str ) {
        try {
            JSON.parse( str );
        } catch ( e ) {
            return false;
        }
        return true;
    },

    /* Browse file and directory tree of the path */
    browseFs: function ( path, id, type ) {
        if ( type === "folders" ) {
            $( "#" + id + "-path" ).val( path );
        }
        myZDL.browseFS( path, type ).then( function ( res ) {
            if ( res ) {
                var items = res.replace( /;?\n?$/, "" ).split( ";" ),
                    parent = path.substring( 0, path.lastIndexOf( "/" ) ),
                    fix = function ( p ) {
                        return p.replace( /\s/g, "%20" );
                    },
                    tree,
                    node = "";
                if ( !parent ) {
                    parent = "/";
                }
                tree = $( "#" + id + "-tree" ).empty();
                if ( path !== "/" ) {
                    node += "<li class='folder'><a href=javascript:utils.browseFs('" + fix( parent ) + "','" + id + "','" + type + "');>..</a></li>";
                } else {
                    path = "";
                }
                $.each( items, function ( index, item ) {
                    if ( item ) {
                        if ( type === "folders" || /^\[.+\]$/.test( item ) ) {
                            item = item.slice( 1, -1 );
                            node += "<li class='folder'><a href=javascript:utils.browseFs('" + fix( path + "/" + item ) + "','" + id + "','" + type + "');>" + item + "</a></li>";
                        } else {
                            node += "<li class='" + type + "'><a href=javascript:utils.selectFile('" + fix( path + "/" + item ) + "','" + id + "');>" + item + "</a></li>";
                        }
                    }
                } );
                tree.append( node );
            }
        } );
    },

    /* Show file selected */
    selectFile: function ( path, id ) {
        $( "#" + id + "-path" ).val( path );
    },

    /* Build the playlist */
    buildPlaylist: function ( data ) {
        var playlist = $( "#playlist" ),
            node = "",
            fileName,
            fileAudio,
            audioAttr,
            audioButton;
        $.each( data, function ( index, filePath ) {
            audioAttr = "'";
            audioButton = "";
            fileName = filePath.replace( /^.*(\/)/, "" );
            if ( /(.mp3|.flac)$/.test( fileName ) ) {
                audioAttr = " audio' data-file='" + filePath + "'";
            } else {
                fileAudio = filePath.substr( 0, filePath.lastIndexOf( "." ) );
                if ( !data.includes( fileAudio + ".mp3" ) && !data.includes( fileAudio + ".flac" ) ) {
                    audioButton = "<button data-i18n='button-audio' class='button to-audio' data-file='" + filePath + "'>Audio</button>";
                }
            }
            node += "<div class='pl-item'><div class='pl-file" + audioAttr + ">" + fileName + "</div><div class='pl-buttons'><button data-i18n='button-play' class='button play-file' data-file='" + filePath + "'>Play</button><button data-i18n='button-remove' class='button pl-remove' data-file='" + filePath + "'>Delete</button>" + audioButton + "</div></div>";
        } );
        playlist.prepend( node );
        $( "#playlist > .pl-item > .pl-buttons > .button" ).button().i18n();
    },

    /* Append new item to the playlist */
    addToPlaylist: function ( filePath ) {
        var playlist = $( "#playlist" ),
            node,
            fileName = filePath.replace( /^.*(\/)/, "" ),
            audioAttr = "'",
            audioButton = "";
        if ( /(.mp3|.flac)$/.test( fileName ) ) {
            audioAttr = " audio' data-file='" + filePath + "'";
        } else {
            var list = $( ".pl-file" ).text(),
                fileAudio = filePath.substr( 0, filePath.lastIndexOf( "." ) );
            if ( !list.includes( fileAudio + ".mp3" ) && !list.includes( fileAudio + ".flac" ) ) {
                audioButton = "<button data-i18n='button-audio' class='button to-audio' data-file='" + filePath + "'>Audio</button>";
            }
        }
        node = "<div class='pl-item'><div class='pl-file" + audioAttr + ">" + fileName + "</div><div class='pl-buttons'><button data-i18n='button-play' class='button play-file' data-file='" + filePath + "'>Play</button><button data-i18n='button-remove' class='button pl-remove' data-file='" + filePath + "'>Delete</button>" + audioButton + "</div></div>";
        playlist.prepend( node );
        $( "#playlist > .pl-item:first-child > .pl-buttons > .button" ).button().i18n();
    },

    /* Build the livestream */
    buildLivestream: function ( data ) {
        var channels = "",
            dataChannels = {},
            id = "channel-",
            n = 1;
        $.each( data, function ( index, item ) {
            n += index;
            dataChannels[ item.url ] = item.chan;
            channels += "<label for='" + id + n + "'>" + item.chan + "</label><input class='radio-stream' type='radio' name='channel-radio' id='" + id + n + "' value='" + item.url + "'>";
        } );
        $( ".livestream-channels" ).append( channels );
        client.set( "channels", dataChannels );
        // #zoninoz
        var divInputLivestream = `<div class="toggle" style="width: 100%;"><div id="link-livestream" class="content read ui-widget-content ui-corner-all" style="width: 98%; background: none;"></div></div>`;
        $( ".livestream-channels" ).append( divInputLivestream );
        $( ".livestream-channels" ).change( livestream.getLivestreamLink );
    },

    /* Update download counters */
    updateCounters: function ( ...args ) {
        var counters = [];
        if ( args.length ) {
            counters = args;
        } else {
            counters = client.getCount();
        }
        $( "#counters .total" ).text( counters[ 0 ] );
        $( "#counters .active" ).text( counters[ 1 ] );
        $( "#counters .completed" ).text( counters[ 0 ] - counters[ 1 ] );
    },

    /* Check and delete a download progressbar removed by an external action */
    checkBars: function ( links ) {
        var bars = client.get( "list" ),
            barId,
            link,
            file;
        $.each( bars, function ( index, item ) {
            barId = $( "#bar-" + item );
            file = barId.children( ".label" ).text();
            link = $( "#info-" + item + " button:last-child" ).data( "link" );
            if ( link && !links.includes( link ) ) {
                barId.closest( ".download" ).remove();
                client.remove( "list", item );
                utils.updateCounters();
                utils.log( "progressbar-inexistent-deleted", file );
            }
        } );
    },

    /* Force localization in problematic areas */
    localizeHard: function () {
        $( "#console-only-errors" ).checkboxradio( "option", "label", $.i18n( "radio-log-label" ) );
        $( ".input-editable" ).checkboxradio( "option", "label", $.i18n( "radio-edit-label" ) );
        $( "#tomorrow-time" ).checkboxradio( "option", "label", $.i18n( "radio-tomorrow-label" ) );
        $( "#edit-links-delete" ).attr( "title", $.i18n( "delete-queue-tooltip" ) );
        $( ".dl-delete" ).attr( "title", $.i18n( "delete-download-tooltip" ) );
    },

    /* Change tab */
    switchToTab: function ( num ) {
        $( "#tabs" ).tabs( "option", "active", num );
    },

    /* Display OK to inform that command was successful */
    success: function ( elem ) {
        elem.removeClass( "hidden" );
        window.setTimeout( function () {
            elem.addClass( "hidden" );
        }, 1000 );
    },

    /* Validate url and path */
    validateInput: function ( str, type ) {
        var pattern = {
            URL: /^(?:(irc|https?):\/\/)?[\w\.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+(\/msg\s.+\sxdcc\ssend\s#\d+)?$/,
            path: /^((\/([\w\.\-\(\)\]\[\?\\@\$\^#&=|:;, ])+)+)|([\w\-]+)$/
        };
        return pattern[ type ].test( str );
    }
};
