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

/* jshint esversion: 8 */

var client = ( function () {
    var data = {
        list: [],
        active: [],
        running: true,
        log: "all",
        dialog: {
            open: false,
            service: "none"
        },
        table: {},
        locale: "en",
        audio: "mp3",
        channels: {}
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

    /* Display Livestream */
    function displayLivestream() {
        myZDL.getLivestream().then( function ( data ) {
            if ( data && utils.parseJson( data ) ) {
                utils.buildLivestream( JSON.parse( data ) );
                $( ".radio-stream" ).checkboxradio( {
                    icon: false
                } );
            } else {
                if ( data.trim() ) {
                    utils.log( "livestream-json-corrupted", null, true );
                }
            }
        } );
    }

    /* Display livestream scheduled */
    function displayLivestreamScheduled( livestream ) {
        if ( livestream.length > 0 ) {
            var scheduledMarkup,
                renderItems = function ( items ) {
                    return `${$.map( items, function( val, key ) {
                        return `<span><strong>${key}:</strong> ${val}</span>`;
                    } ).join( "" )}`;
                },
                streamUrl,
                scheduledRec = $( "#scheduled-rec" );
            $.each( livestream, function ( index, item ) {
                streamUrl = item.link.slice( 0, item.link.lastIndexOf( "#" ) );
                scheduledMarkup = `
                    <div class="scheduled-item">
                        <div class="title">
                            ${data.channels[ streamUrl ]}
                            <button class="button rec-delete ui-button ui-widget ui-corner-all ui-button-icon-only" data-link="${item.link}" data-path="${item.path}">
                                <span class="ui-button-icon ui-icon ui-icon-close"></span>
                            </button>
                        </div>
                        <div class="content">
                            ${renderItems( { "URL":item.link, "Path":item.path, "Start":item.start, "Duration":item.duration } )}
                        </div>
                    </div>
                `;
            } );
            scheduledRec.empty().append( scheduledMarkup ).i18n();
            scheduledRec.find( ".button" ).button().i18n();
        } else {
            var elem = $( "#scheduled-rec" );
            if ( elem.children().length > 0 ) {
                elem.empty();
            }
        }
    }

    /* Display active paths */
    function displayActivePaths( paths, active ) {
        var placeholder = "<option val='' disabled selected>Paths</option>",
            node = "";
        $.each( paths, function ( index, item ) {
            node += "<option value='" + item + "'>" + item + "</option>";
        } );
        $( "#action-path-select, #console-path-select" ).empty().append( placeholder + node );
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
        var isActive = data.active.includes( file );
        if ( perc < 100 && !isActive ) {
            data.active.push( file );
            utils.updateCounters( data.list.length, data.active.length );
        } else {
            if ( perc === 100 && isActive ) {
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

    /* Toggle log/events in a box */
    function dialogToggle() {
        var checked = $( this ).prop( "checked" ),
            markup,
            title,
            service;
        if ( $( this ).is( "#events-dialog" ) ) {
            markup = `<div class="events-container">
                 <div id="dialog-events" class="events"></div></div>`;
            title = $.i18n( "tab-8-label-webui-events" );
            service = "events";
        } else {
            markup = `<div class="log-container">
                 <textarea id="dialog-download-log" readonly></textarea></div>`;
            title = "Download log";
            service = "log";
        }
        if ( checked ) {
            if ( data.dialog.open ) {
                $( this ).prop( "checked", false ).checkboxradio( "refresh" );
                utils.log( "dialog-already-open", null, true );
            } else {
                data.dialog = {
                    open: true,
                    service: service
                };
                var dialog = $( "#dialog" ).empty().append( markup );
                dialog.dialog( "option", {
                    title: title,
                    width: 600
                } );
                dialog.dialog( "open" );
                utils.log( "dialog-logging-start" );
            }
        } else {
            data.dialog = {
                open: false,
                service: "none"
            };
            $( "#dialog" ).dialog( "close" );
            $( this ).blur();
            utils.log( "dialog-logging-stop" );
        }
    }

    /* Toggle audio format */
    function audioFormat() {
        data.audio = $( this ).val();
    }

    /* Configuration status loop (polling) */
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

                displayActivePaths( obj.paths, obj.path );

                displayLivestreamScheduled( obj.livestream );

                displaySocketsButtons( obj.sockets );

                if ( arg ) {
                    $( "#new-socket" ).val( parseInt( window.location.port ) + 1 );
                    utils.updateCounters( data.list.length, data.active.length );
                }

                $( ".selectmenu" ).selectmenu( "refresh" );
            }
            statusFlow();
        } ).catch( function ( e ) {
            if ( data.running ) {
                utils.log( "status-flow-error", e );
                statusFlow();
            }
        } );
    }

    /* Download data loop (polling) */
    function downloadFlow() {
        var arg = arguments[ 0 ] || false,
            force = false;
        myZDL.getData( arg ).then( function ( res ) {
            if ( utils.parseJson( res ) ) {
                var obj = JSON.parse( res ),
                    bar,
                    id,
                    len,
                    perc,
                    status,
                    statusVal,
                    statusParent,
                    statusClass,
                    download,
                    downloadMarkup,
                    info,
                    filename,
                    links = [];
                $.each( obj, function ( index, value ) {
                    id = $.md5( value.link );
                    links.push( value.link );
                    perc = parseInt( value.percent );
                    if ( perc < 100 ) {
                        statusClass = " " + colorToClass( value.color );
                        statusVal = value.percent + "% " + Math.round( value.speed ) + value.speed_measure + " " + value.eta;
                        if ( value.downloader === "FFMpeg" && value.color === "green" ) {
                            force = true;
                        }
                    } else {
                        statusClass = " downloaded";
                        statusVal = "100%";
                    }
                    len = formatFileLength( value.length );
                    if ( !data.list.includes( id ) && !$( "#bar-" + id ).length ) {
                        downloadMarkup = `
                            <div class="download">
                                <div class="progressbar">
                                	<div class="side-bar">
                                		<div id="bar-${id}">
                                			<div class="label">${value.file}</div>
                                		</div>
                                	</div>
                                	<div class="side-status${statusClass}">
                                		<span id="dl-status-${id}"></span>
                                	</div>
                                	<div class="side-button">
                                		<button data-i18n="button-info" class="button open-info" data-toggle="info-${id}">Info</button>
                                	</div>
                                </div>
                                <div class="toggle">
                                	<div id="info-${id}" class="content info ui-widget-content ui-corner-all">
                                		<ul>
                                			<li><span>Downloader: </span>${value.downloader}</li>
                                			<li><span>Link: </span>${value.link}</li>
                                			<li><span>Path: </span>${value.path}</li>
                                			<li><span>Length: </span><span class="dl-size">${len}</span></li>
                                			<li><span>URL: </span>${value.url}</li>
                                		</ul>
                                		<button data-i18n="button-manage" class="button dl-manage" data-path="${value.path}">Manage</button>
                                		<button data-i18n="button-play" class="button play-file" data-file="${value.path}/${value.file}">Play</button>
                                		<button data-i18n="button-playlist" class="button dl-playlist" data-file="${value.path}/${value.file}">Add to playlist</button>
                                		<button data-i18n="button-stop" class="button dl-stop" data-link="${value.link}" data-file="${value.file}">Stop</button>
                                		<button data-i18n="button-delete" class="button dl-delete" data-path="${value.path}" data-link="${value.link}" data-file="${value.file}">Delete</button>
                                	</div>
                                </div>
                            </div>
                        `;
                        download = $( downloadMarkup ).prependTo( "#downloads" );
                        download.find( " .button" ).button().i18n();
                        download.find( " .toggle .button:last-child" ).attr( "title", $.i18n( "delete-download-tooltip" ) ).tooltip( {
                            position: {
                                my: "left bottom",
                                at: "right top-5",
                            },
                            classes: {
                                "ui-tooltip": "tooltip-custom-red"
                            }
                        } );
                        if ( perc < 100 ) {
                            perc = false;
                            statusVal = "---";
                        }
                        $( "#dl-status-" + id ).text( statusVal );
                        $( "#bar-" + id ).progressbar( {
                            value: perc
                        } );
                        data.list.push( id );
                        utils.updateCounters( data.list.length, data.active.length );
                    } else {
                        bar = $( "#bar-" + id );
                        status = $( "#dl-status-" + id );
                        info = $( "#info-" + id );

                        if ( bar.hasClass( "ui-progressbar-indeterminate" ) ) {
                            bar.progressbar( "value", 0.1 );
                        }
                        bar.children( ".ui-progressbar-value" ).animate( {
                            width: perc + "%"
                        }, 500 );
                        info.find( " .dl-size" ).text( len );

                        statusParent = status.parent();
                        if ( !statusParent.hasClass( statusClass ) ) {
                            statusParent.removeClass().addClass( "side-status " + statusClass );
                        }
                        status.text( statusVal );

                        filename = bar.children( ".label" ).text();
                        if ( filename !== value.file ) {
                            data.active.splice( data.active.indexOf( filename ), 1, value.file );
                            bar.children( ".label" ).text( value.file );
                            info.children( "button.play-file, button.dl-playlist" ).attr( "data-file", value.path + "/" + value.file );
                        }

                        if ( downloadCompleted( value.file, perc ) ) {
                            bar.attr( "aria-valuenow", perc );
                            utils.updateCounters( data.list.length, data.active.length );
                            utils.log( "file-downloaded", value.file );
                        }
                    }
                } );
                utils.checkBars( links );
            }
            downloadFlow( force );
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
                [ 0, "asc" ]
            ],
            //retrieve: true,
            paginate: false,
            responsive: true,
            columnDefs: [ {
                responsivePriority: 1,
                targets: -1
            }, {
                responsivePriority: 2,
                targets: 0
            }, {
                responsivePriority: 3,
                targets: 1
            }, {
                className: "centered",
                targets: [ 0, 2, 3, 4, 5, 6, 7, 8 ]
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
        // Check if zdl is outdated
        myZDL.checkVersion().then( function ( res ) {
            if ( res.trim() === "outdated" ) {
                var msg = $.i18n( "dialog-update-msg" ),
                    dialog = $( "#dialog" ).append( `<div class="notice">${msg}</div>` );
                dialog.dialog( "option", {
                    title: $.i18n( "dialog-update-title" ),
                    width: 400
                } );
                dialog.dialog( "open" );
                console.log( "Running an outdated version of ZDL" );
            }
        } );
        console.log( "ZDL web UI started" );
    }

    /*Start the client */
    function init( lang ) {

        if ( !lang ) {
            lang = "en";
            console.log( "ZDL language is undefined! Load default: EN" );
        }

        data.locale = lang;

        // Load i18n strings
        $.i18n().load( {
            it: "i18n/it.json",
            en: "i18n/en.json"
        } ).done( function () {
            // Localize
            $.i18n().locale = lang;
            $( "body" ).i18n();
            utils.log( "start-locale", lang.toUpperCase() );

            // Init widgets
            $( "#tabs" ).tabs( {
                activate: function ( e, ui ) {
                    var active = $( "#tabs" ).tabs( "option", "active" );
                    if ( active === 2 ) {
                        // fix column responsive for datatable inside tab
                        $( $.fn.dataTable.tables( true ) ).DataTable()
                            .columns.adjust()
                            .responsive.recalc();
                    }
                }
            } );
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
            $( "#console-only-errors" ).checkboxradio().change( loggingToggle );
            $( ".console-in-dialog" ).checkboxradio().change( dialogToggle );
            $( ".input-editable" ).checkboxradio().change( editableToggle );
            $( ".radio-audio" ).checkboxradio( {
                icon: false
            } ).change( audioFormat );
            $( "#tomorrow-time" ).checkboxradio();
            $( "#tabs" ).on( "click", ".button", buttonHandler );
            $( "#dialog" ).dialog( {
                autoOpen: false,
                show: {
                    effect: "blind",
                    duration: 800
                },
                hide: {
                    effect: "fade",
                    duration: 800
                },
                close: function ( event, ui ) {
                    if ( data.dialog.open ) {
                        data.dialog = {
                            open: false,
                            service: "none"
                        };
                        $( ".console-in-dialog" ).prop( "checked", false ).checkboxradio( "refresh" ).blur();
                        utils.log( "dialog-logging-stop" );
                    }
                }
            } );

            $( "#edit-links-delete" ).attr( "title", $.i18n( "delete-queue-tooltip" ) ).tooltip( {
                position: {
                    my: "right bottom-5",
                    at: "right top",
                },
                classes: {
                    "ui-tooltip": "tooltip-custom-red"
                }
            } );

            // Extend widget for time spinner
            $.widget( "ui.timespinner", $.ui.spinner, {
                options: {
                    step: 60 * 1000,
                    page: 60
                },
                _parse: function ( value ) {
                    if ( typeof value === "string" ) {
                        if ( Number( value ) == value ) {
                            return Number( value );
                        }
                        return +Globalize.parseDate( value );
                    }
                    return value;
                },
                _format: function ( value ) {
                    return Globalize.format( new Date( value ), "T" );
                }
            } );
            Globalize.culture( "it-IT" );
            $( ".time-spinner" ).timespinner();

            /* init table */
            data.table = datatable( lang );

            /* init client */
            myZDL.initClient().then( function () {
                displayInfo();
                displayPlaylist();
                displayLivestream();
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

    // expose fn
    return {
        remove: function ( key, name ) {
            if ( data[ key ].includes( name ) ) {
                data[ key ].splice( data[ key ].indexOf( name ), 1 );
            }
        },
        exist: function ( key, name ) {
            return data[ key ].includes( name );
        },
        get: function ( key ) {
            return data[ key ];
        },
        set: function ( key, val ) {
            data[ key ] = val;
        },
        getCount: function () {
            return [ data.list.length, data.active.length ];
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
