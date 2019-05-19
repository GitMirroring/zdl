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

var client = ( function () {
    var data = {
        list: [],
        active: [],
        running: true,
        log: "all",
        table: {},
        locale: "en",
        audio: "mp3"
    };

    /* Display some initial info */
    function displayInfo() {
        if ( data.running ) {
            myZDL.getFreeSpace().then( function ( space ) {
                $( "#free-space" ).text( space );
            } );
            myZDL.getDesktopPath().then( function ( path ) {
                $( "#path-launcher" ).val( path );
            } );
        }
    }

    /* Display the playlist */
    function displayPlaylist() {
        myZDL.getPlaylist().then( function ( data ) {
            if ( data && utils.parseJson( data ) ) {
                utils.buildPlaylist( JSON.parse( data ) );
            } else {
                if ( data.trim() ) {
                    utils.log( "playlist-json-corrupted", null, true );
                }
            }
        } );
    }

    /* Get class from color */
    function colorToClass( color ) {
        var matching = {
            yellow: "unterminated",
            red: "aborted",
            green: "downloading"
        };
        return matching[ color ] || "downloading";
    }

    /* Monitoring download */
    function downloadCompleted( file, perc ) {
        if ( perc < 100 && !data.active.includes( file ) ) {
            data.active.push( file );
        } else {
            //var index = client.data.active.indexOf( file );
            if ( data.active.includes( file ) && perc === 100 ) {
                data.active.splice( data.active.indexOf( file ), 1 );
                return true;
            }
        }
        return false;
    }

    /* Get formatted file length */
    function formatFileLength( bytes ) {
        // stackoverflow 15900485
        if ( !bytes ) {
            return "---";
        }
        var sizes = [
                "Bytes", "KB", "MB", "GB", "TB"
            ],
            i = Math.floor( Math.log( bytes ) / Math.log( 1024 ) );
        return parseFloat( ( bytes / 1024 ** i ).toFixed( 2 ) ) + " " + sizes[ i ];
    }

    /* Display sockets buttons */
    function displaySocketsButtons( sockets ) {
        var socketGo = $( ".sockets-go" ),
            socketKill = $( ".sockets-kill" );
        $( ".socket" ).each( function () {
            $( this ).remove();
        } );
        $.each( sockets, function ( index, value ) {
            $( "<button class='socket button'>" + value + "</button>" ).appendTo( socketGo );
            $( "<button class='socket button'>" + value + "</button>" ).appendTo( socketKill );
        } );
        $( ".socket" ).button();
    }

    /* Toggle editable input */
    function editableToggle() {
        var checked = $( this ).prop( "checked" ),
            input = $( this ).parent().find( "input:text" );
        if ( checked ) {
            input.prop( "readonly", false );
        } else {
            input.prop( "readonly", true );
        }
    }

    /* Toggle logging option */
    function loggingToggle() {
        var checked = $( this ).prop( "checked" );
        if ( checked ) {
            data.log = "errors";
        } else {
            data.log = "all";
        }
    }

    /* Toggle audio format */
    function audioFormat() {
        data.audio = $( this ).val();
    }

    /* Configuration settings (polling) */
    function statusFlow() {
        var arg = arguments[ 0 ] || false;
        myZDL.getStatus( arg ).then( function ( res ) {
            if ( utils.parseJson( res ) ) {
                var obj = JSON.parse( res ),
                    running = false;
                if ( obj.status === "running" ) {
                    running = true;
                }
                if ( data.running !== running ) {
                    $( "#zdl-quit, #zdl-killall, #zdl-run" ).toggleClass( "hidden" );
                    $( "#wait" ).addClass( "hidden" );
                    data.running = running;
                }
                if ( !obj.conf.resume ) {
                    obj.conf.resume = "disabled";
                }
                $( "#action-path" ).val( obj.path );
                $( "#local-downloader" ).val( obj.downloader );
                $( "#max-xdcc" ).val( 50 );
                $( "#reconnect" ).val( obj.reconnect );
                $( "#downloader" ).val( obj.conf.conf_downloader );
                $( "#bg-terminal" ).val( obj.conf.background );
                $( "#language" ).val( obj.conf.language );
                $( "#reconnecter" ).val( obj.conf.reconnecter );
                $( "#auto-update" ).val( obj.conf.autoupdate );
                $( "#player" ).val( obj.conf.player );
                $( "#editor" ).val( obj.conf.editor );
                $( "#resume" ).val( obj.conf.resume );
                $( "#start-mode" ).val( obj.conf.zdl_mode );
                $( "#torrent-tcp" ).val( obj.conf.tcp_port );
                $( "#torrent-udp" ).val( obj.conf.udp_port );
                $( "#socket-tcp" ).val( obj.conf.socket_port );
                $( "#browser" ).val( obj.conf.browser );

                $( "#local-max-downloads" ).slider( "value", obj.maxDownloads ).children().text( obj.maxDownloads );
                $( "#axel-parts" ).slider( "value", obj.conf.axel_parts ).children().text( obj.conf.axel_parts );
                $( "#aria2-connections" ).slider( "value", obj.conf.aria2_connections ).children().text( obj.conf.aria2_connections );
                $( "#max-downloads" ).slider( "value", obj.conf.max_dl ).children().text( obj.conf.max_dl );

                $( ".selectmenu" ).selectmenu( "refresh" );

                displaySocketsButtons( obj.sockets );

                if ( arg ) {
                    $( "#new-socket" ).val( parseInt( window.location.port ) + 1 );
                }
            }
            statusFlow();
        } ).catch( function ( e ) {
            if ( data.running ) {
                utils.log( "status-flow-error", e );
                statusFlow();
            }
        } );
    }

    /* Downloads management (polling) */
    function downloadFlow() {
        var arg = arguments[ 0 ] || false;
        myZDL.getData( arg ).then( function ( res ) {
            if ( utils.parseJson( res ) ) {
                var obj = JSON.parse( res ),
                    id,
                    len,
                    perc,
                    status,
                    statusVal,
                    statusParent,
                    statusClass;
                $.each( obj, function ( index, value ) {
                    id = $.md5( value.link );
                    perc = parseInt( value.percent );
                    if ( perc < 100 ) {
                        statusClass = colorToClass( value.color );
                        statusVal = value.percent + "% " + Math.round( value.speed ) + value.speed_measure + " " + value.eta;
                    } else {
                        statusClass = "";
                        statusVal = "100%";
                    }
                    len = formatFileLength( value.length );
                    if ( !data.list.includes( value.file ) ) {
                        if ( statusClass ) {
                            statusClass = " " + statusClass;
                        }
                        $( "<div class='progressbar'><div class='side-bar'><div id='bar-" + id + "'><div class='label'>" + value.file + "</div></div></div><div class='side-status" + statusClass + "'><span id='dl-status-" + id + "'></span></div><div class='side-button'><button data-i18n='button-info' class='button open-info' data-toggle='info-" + id + "'>Info</button></div></div><div class='toggle'><div id='info-" + id + "' class='content info ui-widget-content ui-corner-all'><ul><li><span>Downloader: </span>" + value.downloader + "</li><li><span>Link: </span>" + value.link + "</li><li><span>Path: </span>" + value.path + "</li><li><span>Length: </span><span class='dl-size'>" + len + "</span></li><li><span>URL: </span>" + value.url + "</li></ul><button data-i18n='button-manage' class='button dl-manage' data-path='" + value.path + "'>Manage</button><button data-i18n='button-play' class='button play-file' data-file='" + value.path + "/" + value.file + "'>Play</button><button data-i18n='button-playlist' class='button dl-playlist' data-file='" + value.path + "/" + value.file + "'>Add to playlist</button><button data-i18n='button-stop' class='button dl-stop' data-link='" + value.link + "' data-file='" + value.file + "'>Stop</button><button data-i18n='button-delete' class='button dl-delete' data-path='" + value.path + "' data-link='" + value.link + "' data-file='" + value.file + "' title='" + $.i18n("delete-download-tooltip") + "'>Delete</button></div></div>" ).prependTo( "#downloads" );
                        $( "#dl-status-" + id ).text( statusVal );
                        $( ".progressbar:first-child > .side-button > .button" ).button();
                        $( "#info-" + id + " > .button" ).button().i18n().tooltip( {
                            position: {
                                my: "left bottom",
                                at: "right top-5",
                            },
                            classes: {
                                "ui-tooltip": "tooltip-custom-red"
                            }
                        } );
                        if ( perc === 0 ) {
                            perc = false;
                        }
                        $( "#bar-" + id ).progressbar( {
                            value: perc
                        } );
                        data.list.push( value.file );
                    } else {
                        status = $( "#dl-status-" + id );
                        statusParent = status.parent();
                        if ( !statusParent.hasClass( statusClass ) ) {
                            statusParent.removeClass().addClass( "side-status " + statusClass );
                        }
                        status.text( statusVal );
                        $( "#bar-" + id ).progressbar( "value", perc );
                        $( "#info-" + id + " .dl-size").text( len );
                        if ( downloadCompleted( value.file, perc ) ) {
                            utils.log( "file-downloaded", value.file );
                        }
                    }
                } );
            }
            downloadFlow();
        } ).catch( function ( e ) {
            if ( data.running ) {
                utils.log( "download-flow-error", e );
                downloadFlow();
            }
        } );
    }

    /* Initialize DataTable for xdcc search */
    function datatable( lang ) {
        return $( "#xdcc-eu" ).DataTable( {
            order: [
                [ 4, "desc" ]
            ],
            //retrieve: true,
            paginate: false,
            responsive: true,
            columnDefs: [ {
                responsivePriority: 1,
                targets: 0
            }, {
                responsivePriority: 1,
                targets: -3
            } ],
            language: {
                url: "/i18n/" + lang + ".lang"
            }
        } );
    }

    /* Show the UI */
    function showUI() {
        $( ".loader" ).hide();
        $( ".wrapper" ).show();
        console.log( "ZDL UI start" );
    }

    /*Start the client */
    function init() {
        // Retrieve the configured language
        var language = document.cookie.replace( /(?:(?:^|.*;\s*)_zdlstartuplanguage\s*\=\s*([^;]*).*$)|^.*$/, "$1" );
        if ( language ) {
            localStorage.setItem( "ZDLlanguage", language );
            console.log( "ZDL language (cookie): " + language.toUpperCase() );
            document.cookie = "_zdlstartuplanguage=; Thu, 01 Jan 1970 00:00:01 GMT";
        } else {
            language = localStorage.getItem( "ZDLlanguage" );
            if ( language ) {
                console.log( "ZDL language (storage): " + language.toUpperCase() );
            } else {
                language = "en";
                console.log( "Unable to get ZDL language. Use default: EN" );
            }
        }

        data.locale = language;

        // Load i18n strings
        $.i18n().load( {
            it: "i18n/it.json",
            en: "i18n/en.json"
        } ).done( function () {
            // Localize
            $.i18n().locale = language;
            $( "body" ).i18n();
            utils.log( "start-locale", language.toUpperCase() );

            // Init widgets
            $( "#tabs" ).tabs();
            $( ".button" ).button();
            $( ".spinner" ).spinner( {
                create: function ( e, ui ) {
                    spinnersSetRange( e.target.id, $( this ) );
                }
            } );
            $( ".slider" ).slider( {
                create: function ( e, ui ) {
                    slidersSetRange( e.target.id, $( this ) );
                },
                slide: function ( e, ui ) {
                    $( this ).children().text( ui.value );
                }
            } );
            $( ".selectmenu" ).selectmenu( {
                change: function ( e, data ) {
                    selectMenuHandler( e.target.id, data.item.value );
                }
            } );
            $( "#console-only-errors" ).prop( "checked", false ).checkboxradio().change( loggingToggle );
            $( ".input-editable" ).prop( "checked", false ).checkboxradio().change( editableToggle );
            $( ".radio-audio" ).prop( "checked", false ).checkboxradio().change( audioFormat );
            $( "#radio-mp3" ).prop( "checked", true ).checkboxradio( "refresh" );
            $( "#tabs" ).on( "click", ".button", buttonHandler );

            $( "#edit-links-delete" ).attr( "title", $.i18n( "delete-queue-tooltip" ) ).tooltip( {
                position: {
                    my: "right bottom-5",
                    at: "right top",
                },
                classes: {
                    "ui-tooltip": "tooltip-custom-red"
                }
            } );

            /* init table */
            data.table = datatable( language );

            /* init client */
            myZDL.initClient().then( function () {
                displayInfo();
                displayPlaylist();
                statusFlow( true );
                downloadFlow( true );
                showUI();
                utils.log( "client-init", myZDL.path );
            } ).catch( function ( e ) {
                utils.log( "client-init-error", e, true );
                console.log( e );
            } );
        } );
    }

    return {
        remove: function ( key, name ) {
            data[ key ].splice( data[ key ].indexOf( name ), 1 );
        },
        exist: function ( key, name ) {
            return data[ key ].includes( name );
        },
        get: function ( key ) {
            return data[ key ];
        },
        set: function( key, val ) {
            data[ key ] = val;
        },
        table: function () {
            return data.table;
        },
        tableInit: function ( lang ) {
            if ( data.table.hasOwnProperty( "destroy" ) ) {
                data.table.destroy();
            }
            data.table = datatable( lang );
        },
        init: init
    };
} )();
