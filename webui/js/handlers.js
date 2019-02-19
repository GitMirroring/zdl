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

/*jshint esversion: 6*/

function UIbuttons( e ) {
    var pass;
    switch ( e.target.id ) {
        case "clean-downloaded":
            myZDL.cleanCompleted().then( function() {
                $( ".progressbar" ).each( function() {
                    var fname = $( this ).find( ".label" ).text();
                    if ( isDownloading.indexOf( fname ) < 0 ) {
                        var index = fileList.indexOf( fname );
                        if ( index >= 0 ) {
                            fileList.splice( index, 1 );
                        }
                        $( this ).next( ".toggler" ).remove();
                        $( this ).remove();
                    }
                } );
                ZDLconsole( "downloads-completed-delete" );
            } );
            break;
        case "path-toggler":
            var pathToggler = $( this );
            $( "#path-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    pathToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "path", "folders" );
                } else {
                    pathToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "path-save":
            var newPathVal = $( this ).prev().val();
            if ( validateInput( newPathVal, "path" ) ) {
                myZDL = new ZDL( newPathVal, "index.html" );
                myZDL.initClient().then( function() {
                    actionPATH = newPathVal;
                    ZDLconsole( "new-path", newPathVal );
                    $( "#path-toggler" ).trigger( "click" );
                } ).catch( function( e ) {
                    ZDLconsole( "client-init-error", e, true );
                } );
            } else {
                ZDLconsole( "new-path-incorrect", newPathVal, true );
            }
            break;
        case "free-space-update":
            var freeSpace = $( this ).prev();
            myZDL.getFreeSpace().then( function( space ) {
                freeSpace.text( space );
                ZDLconsole( "free-space-update", freeSpace.text() );
            } );
            break;
        case "add-link-send":
            var addLink = $( this ).prev(),
                addLinkVal = addLink.val();
            if ( validateInput( addLinkVal, "URL" ) ) {
                myZDL.addLink( addLinkVal ).then( function() {
                    addLink.val( "" );
                    ZDLconsole( "send-link", addLinkVal );
                    $( "#tabs" ).tabs( "option", "active", 0 );
                } );
            } else {
                addLink.val( "" );
				if ( !addLinkVal ) addLinkVal = " ";
				ZDLconsole( "send-link-incorrect", addLinkVal, true );
            }
            break;
        case "edit-links-toggler":
            var editLinksToggler = $( this );
            $( "#links-editor" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    editLinksToggler.text( $.i18n( "button-close" ) );
                    myZDL.getLinks().then( function( links ) {
                        if ( links && links.length > 10 ) {
                            $( "#edit-links" ).val( decodeURIComponent( links ).replace( /\n$/, "" ) );
                        } else {
                            $( "#edit-links" ).val( "" );
                        }
                    } );
                } else {
                    editLinksToggler.text( $.i18n( "button-open" ) );
                }
            } );
            break;
        case "edit-links-save":
            var editLinksVal = $( this ).prev().val();
            if ( editLinksVal ) {
                var linksItems = editLinksVal.split( "\n" ),
                    pattern;
                pass = true;
                $.each( linksItems, function( index, link ) {
                    if ( /^https?:\/\//i.test( link ) ) {
                        pattern = "URL";
                    } else {
                        pattern = "irc";
                    }
                    if ( !validateInput( link, "URL" ) ) {
                        ZDLconsole( "links-edit-incorrect", link, true );
                        pass = false;
                    }
                } );
                if ( pass ) {
                    myZDL.command( "set-links", "links=" + encodeURIComponent( editLinksVal ) ).then( function() {
                        ZDLconsole( "links-edit" );
                        $( "#edit-links-toggler" ).trigger( "click" );
                    } );
                }
            }
            break;
        case "edit-links-delete":
            var editLinks = $( "#edit-links" ),
                linksEditVal = editLinks.val(),
                links = linksEditVal.split( "\n" ),
                activeLinks = "";
            $.each( links, function( index, link ) {
                if ( isDownloading.indexOf( link ) >= 0 ) {
                    activeLinks += ( link + "\n" );
                }
            } );
            activeLinks = activeLinks.replace( /(\n)+$/, "" ); // remove any newline at end
            myZDL.command( "set-links", "links=" + activeLinks ).then( function() {
                editLinks.val( activeLinks );
                ZDLconsole( "links-delete" );
                $( "#edit-links-toggler" ).trigger( "click" );
            } );
            break;
        case "irc-host-clean":
        case "irc-channel-clean":
        case "irc-bot-clean":
        case "irc-slot-clean":
            $( this ).prev().val( "" );
            break;
        case "xdcc-send":
            var host = $( "#irc-host" ).val(),
                chan = $( "#irc-channel" ).val(),
                bot = $( "#irc-bot" ).val(),
                slot = $( "#irc-slot" ).val(),
                msg = "/msg " + bot + " xdcc send " + slot,
                xdcc = "irc://" + host + "/" + chan + msg;
            pass = true;
            if ( !validateInput( xdcc, "URL" ) ) {
                ZDLconsole( "send-xdcc-incorrect", xdcc, true );
                pass = false;
            }
            if ( pass ) {
                var req = {
                    host: host,
                    channel: encodeURIComponent( chan ),
                    msg: encodeURIComponent( msg )
                };
                myZDL.addXdcc( req ).then( function( res ) {
                    ZDLconsole( "send-xdcc", xdcc );
                    if ( res && res.length > 5 ) {
                        ZDLconsole( res, null, true );
                    }
                    $( "#xdcc-clean" ).trigger( "click" );
                } );
            }
            break;
        case "xdcc-clean":
            $( "#irc-host-clean, #irc-channel-clean, #irc-bot-clean, #irc-slot-clean" ).trigger( "click" );
            break;
        case "torrent-toggler":
            var torrentToggler = $( this );
            $( "#torrent-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    torrentToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "torrent", "torrent" );
                } else {
                    torrentToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "torrent-save":
            var torrentVal = $( this ).prev().val();
            if ( validateInput( torrentVal, "path" ) ) {
                myZDL.addTorrent( torrentVal ).then( function() {
                    ZDLconsole( "send-torrent", torrentVal );
                    $( "#torrent-toggler" ).trigger( "click" );
                } );
            } else {
                ZDLconsole( "send-torrent-path-incorrect", torrentVal, true );
            }
            break;
        case "links-txt-toggler":
            var linksTxtToggler = $( this );
            $( "#links-txt-read" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    linksTxtToggler.text( $.i18n( "button-close" ) );
                    var linksTxt = $( this ).children( "textarea" );
                    myZDL.getFile( "links.txt" ).then( function( content ) {
                        if ( content ) {
                            content = content.replace( /(<br>\n){1,2}/gi, "\n" );
                            linksTxt.val( content )
                                .animate( {
                                    scrollTop: linksTxt.prop( "scrollHeight" ) - linksTxt.height()
                                }, 1000 );
                        } else {
                            linksTxt.val( "links.txt empty or not found" );
                        }
                        linksTxt.scrollTop = linksTxt.scrollHeight;
                    } );
                } else {
                    linksTxtToggler.text( $.i18n( "button-open" ) );
                }
            } );
            break;
        case "links-txt-delete":
            var linksTxt = $( this ).prev(),
                linksTxtVal = linksTxt.val();
            if ( linksTxtVal && linksTxtVal !== "links.txt empty or not found" ) {
                myZDL.deleteFile( "links.txt" ).then( function() {
                    linksTxt.val( "" );
                    ZDLconsole( "queue-delete" );
                    $( "#links-txt-toggler" ).trigger( "click" );
                } );
            }
            break;
        case "max-downloads-change":
            var maxDownloadsVal = $( this ).prev().children().val();
            myZDL.command( "set-max-downloads", "number=" + maxDownloadsVal ).then( function() {
                ZDLconsole( "path-parallel-download", maxDownloadsVal );
            } );
            break;
        case "reconnect-now":
            myZDL.modemReconnect().then( function( res ) {
                if ( res && res.length > 5 ) {
                    if ( /Non hai ancora configurato ZDL/.test( res ) ) {
                        ZDLconsole( "modem-reconnect-failure", null, true );
                    } else {
                        ZDLconsole( res, null, true );
                    }
                } else {
                    ZDLconsole( "modem-reconnect" );
                }
            } );
            break;
        case "get-ip":
            var getIP = $( this );
            myZDL.getIP().then( function( ip ) {
                var match = ip.match( /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ );
                if ( match ) {
                    getIP.next().val( match[ 0 ] );
                    ZDLconsole( "get-IP", match[ 0 ] );
                } else {
                    getIP.next().val( "---" );
                    ZDLconsole( "get-IP-failure", null, true );
                }
            } );
            break;
        case "zdl-quit":
            $( "#wait" ).removeClass( "hide" );
            myZDL.quit().then( function() {
                ZDLconsole( "zdl-quit" );
            } );
            break;
        case "zdl-killall":
            $( "#wait" ).removeClass( "hide" );
            myZDL.kill().then( function() {
                ZDLconsole( "zdl-killall" );
            } );
            break;
        case "zdl-run":
            $( "#wait" ).removeClass( "hide" );
            myZDL.run().then( function() {
                ZDLconsole( "zdl-run" );
            } );
            break;
        case "xdcc-search-exec":
            var xdccSearch = $( this ).prev(),
                term = xdccSearch.val(),
				table = initTable();
			table.clear().draw();
            if ( term ) {
                myZDL.searchXdcc( term ).then( function( res ) {
                    if ( res !== "failure" ) {
                        var max = $( "#max-xdcc" ).val();
    					try {
      						var obj = $.parseJSON( res ),
                                send = $.i18n( "button-send" );
    						$.each(obj, function(i, o) {
                                table.row.add( [o.server,o.channel,o.bot,o.slot,o.gets,o.length,o.name,"<button class=\"button xdcc-search\">"+send+"</button>"] ).draw( false );
                                if ( i === (max-1) ) return false;
                        	});
    					}
    					catch(error) {
      						ZDLconsole( "xdcc-search-error", error, true );
    					}
                        $( ".button" ).button();
						xdccSearch.val( "" );
                    } else {
						xdccSearch.val( $.i18n( "xdcc-search-no-results" ) );
					}
                } );
                ZDLconsole( "xdcc-search", term );
                xdccSearch.val( $.i18n( "xdcc-serching" ) );
            } else {
				xdccSearch.val( $.i18n( "xdcc-search-no-term" ) );
            }
            break;
        case "playlist-toggler":
            var playlistToggler = $( this );
            $( "#playlist-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    playlistToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "playlist", "media" );
                } else {
                    playlistToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "playlist-save":
            var playlistVal = $( this ).prev().val();
            if ( validateInput( playlistVal, "path" ) ) {
                myZDL.addPlaylist( playlistVal ).then( function( res ) {
                    if ( /Non è un file audio\/video/.test( res ) ) {
                        ZDLconsole( "playlist-file-path-incorrect", playlistVal, true );
                    } else {
                        addToPlaylist( playlistVal );
                        ZDLconsole( "playlist-file-added", playlistVal );
                    }
                } );
            } else {
                ZDLconsole( "playlist-path-incorrect", playlistVal, true );
            }
            break;
        case "new-socket-run":
            var port = $( "#new-socket" ).spinner( "value" );
            myZDL.startSocket( port ).then( function( res ) {
                if ( /already-in-use/.test( res ) ) {
                    ZDLconsole( "new-socket-port-unavailable", port, true );
                } else {
                    ZDLconsole( "new-socket", port );
                }
            } );
            break;
        case "socket-kill-this":
            var thisPort = document.location.port;
            myZDL.killSocket( thisPort ).then( function() {
                window.setTimeout( function() {
                    window.location.href = window.location.pathname;
                }, 2000 );
            } );
            break;
        case "downloads-killall":
            myZDL.killAll().then( function() {
                ZDLconsole( "downloads-killall" );
            } );
            break;
        case "conf-axel-parts-change":
            var axelPartsVal = $( this ).prev().children().val();
            myZDL.setConf( "axel_parts", axelPartsVal ).then( function() {
                ZDLconsole( "conf-axel-parts", axelPartsVal );
            } );
            break;
        case "conf-aria2-parts-change":
            var aria2PartsVal = $( this ).prev().children().val();
            myZDL.setConf( "aria2_connections", aria2PartsVal ).then( function() {
                ZDLconsole( "conf-aria2-parts", aria2PartsVal );
            } );
            break;
        case "conf-max-downloads-change":
            var confMaxDownloadsVal = $( this ).prev().children().val();
            myZDL.setConf( "max_dl", confMaxDownloadsVal ).then( function() {
                ZDLconsole( "conf-parallel-downloads", confMaxDownloadsVal );
            } );
            break;
        case "conf-reconnecter-toggler":
            var reconnecterToggler = $( this );
            $( "#conf-reconnecter-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    reconnecterToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "conf-reconnecter", "executable" );
                } else {
                    reconnecterToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "conf-reconnecter-save":
            var reconnecterVal = $( this ).prev().val();
            if ( validateInput( reconnecterVal, "path" ) ) {
                myZDL.setConf( "reconnecter", reconnecterVal ).then( function() {
                    ZDLconsole( "conf-modem-reconnect", reconnecterVal );
                    $( "#conf-reconnecter-toggler" ).trigger( "click" );
                } );
            } else {
                ZDLconsole( "conf-modem-reconnect-incorrect", reconnecterVal, true );
            }
            break;
        case "conf-player-toggler":
            var playerToggler = $( this );
            $( "#conf-player-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    playerToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "conf-player", "executable" );
                } else {
                    playerToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "conf-player-save":
            var playerVal = $( this ).prev().val();
            if ( validateInput( playerVal, "path" ) ) {
                myZDL.setConf( "player", playerVal ).then( function() {
                    ZDLconsole( "conf-player", playerVal );
                    $( "#conf-player-toggler" ).trigger( "click" );
                } );
            } else {
                ZDLconsole( "conf-player-path-incorrect", playerVal, true );
            }
            break;
        case "conf-editor-toggler":
            var editorToggler = $( this );
            $( "#conf-editor-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    editorToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "conf-editor", "executable" );
                } else {
                    editorToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "conf-editor-save":
            var editorVal = $( this ).prev().val();
            if ( validateInput( editorVal, "path" ) ) {
                myZDL.setConf( "editor", editorVal ).then( function() {
                    ZDLconsole( "conf-editor", editorVal );
                    $( "#conf-editor-toggler" ).trigger( "click" );
                } );
            } else {
                ZDLconsole( "conf-editor-path-incorrect", editorVal, true );
            }
            break;
        case "conf-torrent-tcp-change":
            var tcpTorrentVal = $( this ).prev().children().val();
            myZDL.setConf( "tcp_port", tcpTorrentVal ).then( function() {
                ZDLconsole( "conf-tcp-torrent", tcpTorrentVal );
            } );
            break;
        case "conf-torrent-udp-change":
            var udpTorrentVal = $( this ).prev().children().val();
            myZDL.setConf( "udp_port", udpTorrentVal ).then( function() {
                ZDLconsole( "conf-udp-torrent", udpTorrentVal );
            } );
            break;
        case "conf-socket-tcp-change":
            var tcpSocketVal = $( this ).prev().children().val();
            myZDL.setConf( "socket_port", tcpSocketVal ).then( function() {
                ZDLconsole( "conf-tcp-socket", tcpSocketVal );
            } );
            break;
        case "conf-browser-toggler":
            var browserToggler = $( this );
            $( "#conf-browser-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    browserToggler.text( $.i18n( "button-close" ) );
                    browseFs( actionPATH, "conf-browser", "executable" );
                } else {
                    browserToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "conf-browser-save":
            var browserVal = $( this ).prev().val();
            if ( validateInput( browserVal, "path" ) ) {
                myZDL.setConf( "browser", browserVal ).then( function() {
                    ZDLconsole( "conf-browser", browserVal );
                    $( "#conf-browser-toggler" ).trigger( "click" );
                } );
            } else {
                ZDLconsole( "conf-browser-path-incorrect", browserVal, true );
            }
            break;
        case "account-reset":
            myZDL.reset().then( function() {
                window.location.href = "login.html";
            } );
            break;
        case "conf-desktop-toggler":
            var desktopPathToggler = $( this );
            desktopPathCurrentVal = desktopPathToggler.prev().val();
            $( "#conf-desktop-browse" ).toggle( "blind", null, 500, function() {
                if ( $( this ).is( ":visible" ) ) {
                    desktopPathToggler.text( $.i18n( "button-close" ) );
                    browseFs( desktopPathCurrentVal, "conf-desktop", "folders" );
                } else {
                    desktopPathToggler.text( $.i18n( "button-select" ) );
                }
            } );
            break;
        case "conf-desktop-save":
            var desktopPathVal = $( this ).prev().val();
            if ( validateInput( desktopPathVal, "path" ) ) {
                myZDL.setDesktopPath( desktopPathVal ).then( function() {
                    ZDLconsole( "conf-icon-path", desktopPathVal );
                    $( "#conf-desktop-toggler" ).trigger( "click" ).prev().val( desktopPathVal );
                } );
            } else {
                ZDLconsole( "conf-icon-path-incorrect", desktopPathVal, true );
            }
            break;
        case "console-zdl-log-toggler":
            var zdlLogToggler = $( this );
            $( "#zdl-log" ).toggle( "blind", null, 500, function() {
                var zdlLog = $( this );
                if ( $( this ).is( ":visible" ) ) {
                    zdlLogToggler.text( $.i18n( "console-close-zdl-log" ) );
                    myZDL.getFile( "zdl_log.txt" ).then( function( content ) {
                        if ( content ) {
                            zdlLog.html( decodeURIComponent( content.replace( /\n\n/g, "<br>" ) ) )
                                .animate( {
                                    scrollTop: zdlLog.prop( "scrollHeight" ) - zdlLog.height()
                                }, 1000 );
                        } else {
                            zdlLog.text( $.i18n( "console-zdl-log-empty" ) );
                        }
                        zdlLog.scrollTop = zdlLog.scrollHeight;
                    } );
                } else {
                    zdlLogToggler.text( $.i18n( "console-open-zdl-log" ) );
                    $( this ).text( "loading ..." );
                }
            } );
            break;
        case "console-clean":
            $( this ).parent().prev().text( "" );
            ZDLconsole( "console-clean" );
            break;
        case "close-all":
            $( ".onclose" ).text( $.i18n( "close-all-shutdown" ) );
            zdlRunning = false;
            myZDL.exitAll().then( function() {
                window.setTimeout( function() {
                    window.location.href = window.location.pathname;
                }, 2000 );
            } );
            break;
        default:
            if ( $( this ).hasClass( "socket" ) ) {
                var socketPort = $( this ).text();
                if ( $( this ).parent().hasClass( "sockets-go" ) ) {
                    ZDLconsole( "new-webui", socketPort );
                    window.open( document.location.protocol + "//" + document.location.hostname + ":" + socketPort );
                } else {
                    myZDL.killSocket( $( this ).text() ).then( function() {
                        ZDLconsole( "kill-socket", socketPort );
                        if ( socketPort === document.location.port ) {
                            window.setTimeout( function() {
                                window.location.href = window.location.pathname;
                            }, 2000 );
                        }
                    } );
                }
            } else if ( $( this ).hasClass( "open-info" ) ) {
                var openInfo = $( this ),
                    toggler = openInfo.data( "toggler" );
                $( "#" + toggler ).toggle( "blind", null, 500, function() {
                    if ( $( this ).is( ":visible" ) ) {
                        openInfo.text( $.i18n( "button-close" ) );
                    } else {
                        openInfo.text( $.i18n( "button-info" ) );
                    }
                } );
			} else if ( $( this ).hasClass( "dl-manage" ) ) {
                var dlPath = $( this ).data( "path" );
				if ( dlPath !== actionPATH ) {
					myZDL = new ZDL( dlPath, "index.html" );
                	myZDL.initClient().then( function() {
                    	actionPATH = dlPath;
                    	ZDLconsole( "clinet-init", dlPath );
                	} ).catch( function( e ) {
                    	ZDLconsole( "client-init-error", e, true );
                	} );
				}
				$( "#tabs" ).tabs( "option", "active", 1 );
            } else if ( $( this ).hasClass( "dl-play" ) ) {
                var dlPlayFile = $( this ).data( "file" );
                myZDL.play( dlPlayFile ).then( function() {
                    ZDLconsole( "play-file", dlPlayFile.replace( /^.*(\/)/, '' ) );
                } );
            } else if ( $( this ).hasClass( "dl-playlist" ) ) {
                var dlPlaylistFile = $( this ).data( "file" );
                myZDL.addPlaylist( dlPlaylistFile ).then( function( res ) {
                    if ( /Non è un file audio\/video/.test( res ) ) {
                        ZDLconsole( "playlist-file-incorrect", dlPlaylistFile, true );
                    } else {
                        addToPlaylist( dlPlaylistFile );
                        ZDLconsole( "playlist-file-added", dlPlaylistFile );
                    }
                } );
            } else if ( $( this ).hasClass( "dl-stop" ) ) {
                var dlStopLink = $( this ).data( "link" );
                myZDL.stopLink( encodeURIComponent( dlStopLink ) ).then( function() {
                    ZDLconsole( "download-stop", dlStopLink );
                } );
            } else if ( $( this ).hasClass( "dl-delete" ) ) {
                var dlDeleteLink = $( this ).data( "link" ),
                    dlDeleteFile = $( this ).data( "file" ),
                    thisToggler = $( this ).closest( ".toggler" ), index;
                myZDL.deleteLink( encodeURIComponent( dlDeleteLink ) ).then( function() {
					thisToggler.prev().remove();
					thisToggler.remove();
                    index = isDownloading.indexOf( dlDeleteLink );
                    if ( index >= 0 ) {
                        isDownloading.splice( index, 1 );
                    }
                    index = fileList.indexOf( dlDeleteFile );
                    if ( index >= 0 ) {
                        fileList.splice( index, 1 );
                    }
                    ZDLconsole( "download-delete", dlDeleteLink );
                } );
            } else if ( $( this ).hasClass( "pl-delete" ) ) {
                var plDeleteFile = $( this ).data( "file" );
                myZDL.deletePlaylist( plDeleteFile ).then( function( data ) {
                    $( "#playlist" ).empty();
                    if ( isJson( data ) ) {
                        buildPlaylist( JSON.parse( data ) );
                    }
                    ZDLconsole( "playlist-file-delete", plDeleteFile );
                } );
            } else if ( $( this ).hasClass( "xdcc-search" ) ) {
                var parent = $( this ).closest( "tr" ),
                    xdccreq = {
                        host: parent.children().eq( 0 ).text(),
                        channel: encodeURIComponent( parent.children().eq( 1 ).text() ),
                        msg: encodeURIComponent( "/msg " +  parent.children().eq( 2 ).text() + " xdcc send " + parent.children().eq( 3 ).text() )
                    };
                $( this ).prop( "disabled", true ).text( "OK" );
                myZDL.addXdcc( xdccreq ).then( function( res ) {
                    ZDLconsole( "send-xdcc", "irc://" + xdccreq.host + "/" + decodeURIComponent( xdccreq.channel ) + decodeURIComponent( xdccreq.msg ) );
                    if ( res && res.length > 5 ) {
                        ZDLconsole( res, null, true );
                    }
                } );
            } else {
                ZDLconsole( "(buttons) event target error", null, true );
            }
    }
}

function UIselectors( id, value ) {
    switch ( id ) {
        case "downloader":
            myZDL.command( "set-downloader", "downloader=" + value ).then( function() {
                ZDLconsole( "path-downloader", value );
            } );
            break;
        case "reconnect":
            var val = "false";
            if ( value !== "disabled" ) val = "true";
            myZDL.command( "reconnect", "set=" + val ).then( function( res ) {
                if ( res && res.length > 5 ) {
                    if ( /Non hai ancora configurato ZDL/.test( res ) ) {
                        ZDLconsole( "modem-reconnect-misconfigured", null, true );
                    } else {
                        ZDLconsole( res, null, true );
                    }
                    $( "#reconnect" ).val( "disabled" );
                    $( ".selectmenu" ).selectmenu( "refresh" );
                } else {
                    ZDLconsole( "modem-reconnect-value", value );
                }
            } );
            break;
        case "conf-webui":
            myZDL.setConf( "web_ui", value ).then( function() {
                window.setTimeout( function() {
                    window.location.href = window.location.pathname;
                }, 2000 );
            } );
            break;
        case "conf-downloader":
            myZDL.setConf( "downloader", value ).then( function() {
                ZDLconsole( "conf-downloader", value );
            } );
            break;
        case "conf-bg-terminal":
            myZDL.setConf( "background", value ).then( function() {
                ZDLconsole( "conf-terminal-bg", value );
            } );
            break;
        case "conf-language":
            myZDL.setConf( "language", value ).then( function() {
                $.i18n().locale = value;
                $( "body" ).i18n();
                localizeRadioLabels();
                localStorage.setItem("ZDLlanguage", value);
                ZDLconsole( "conf-client-language", value.toUpperCase() );
            } );
            break;
        case "conf-auto-update":
            myZDL.setConf( "autoupdate", value ).then( function() {
                ZDLconsole( "conf-auto-update", $.i18n( "option-"+value ) );
            } );
            break;
        case "conf-resume":
            myZDL.setConf( "resume", value ).then( function() {
                ZDLconsole( "conf-file-overwrite", $.i18n( "option-"+value ) );
            } );
            break;
        case "conf-start-mode":
            myZDL.setConf( "zdl-mode", value ).then( function() {
                ZDLconsole( "conf-zdl-start-mode", value );
            } );
            break;
        default:
            ZDLconsole( "(selectors) event target error", null, true );
    }
}

function UIspinners( id, spinner ) {
    switch ( id ) {
        case "max-downloads":
            spinner.spinner( {
                min: 1,
                max: 100
            } );
            break;
        case "max-xdcc":
            spinner.spinner( {
                min: 1,
                max: 500
            } );
            break;
        case "new-socket":
            spinner.spinner( {
                min: 8080,
                max: 65535
            } );
            break;
        case "conf-axel-parts":
            spinner.spinner( {
                min: 1,
                max: 32
            } );
            break;
        case "conf-aria2-parts":
            spinner.spinner( {
                min: 1,
                max: 16
            } );
            break;
        case "conf-max-downloads":
            spinner.spinner( {
                min: 1,
                max: 100
            } );
            break;
        case "conf-torrent-tcp":
            spinner.spinner( {
                min: 1025,
                max: 65535
            } );
            break;
        case "conf-torrent-udp":
            spinner.spinner( {
                min: 1025,
                max: 65535
            } );
            break;
        case "conf-socket-tcp":
            spinner.spinner( {
                min: 8080,
                max: 65535
            } );
            break;
        default:
            ZDLconsole( "(spinners) event target error", null, true );
    }
}
