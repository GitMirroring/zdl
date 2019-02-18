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

/* jshint esversion: 6 */

function initClient() {
	var language = document.cookie.replace( /(?:(?:^|.*;\s*)_zdlstartuplanguage\s*\=\s*([^;]*).*$)|^.*$/, "$1" );
	if ( language ) {
		localStorage.setItem( "ZDLlanguage", language );
		console.log( "Get ZDL language from cookie: " + language.toUpperCase() );
		document.cookie = "_zdlstartuplanguage=; Thu, 01 Jan 1970 00:00:01 GMT";
	} else {
		language = localStorage.getItem( "ZDLlanguage" );
		if ( language ) {
			console.log( "Get ZDL language from storage: " + language.toUpperCase() );
		} else {
			language = "en";
			console.log( "Unable to get ZDL language. Set to default: EN" );
		}
	}
	if ( language === "it_IT.UTF-8" ) language = "it";

	$.i18n().load({
		"it": "i18n/it.json",
		"en": "i18n/en.json"
	} ).done( function() {
		$.i18n().locale = language;
		$( "body" ).i18n();
		ZDLconsole( "start-locale", language.toUpperCase() );

		$( "#tabs" ).tabs();

		$( ".button" ).button();

		$( ".spinner" ).spinner({
			create: function( e, ui ) {
				UIspinners( e.target.id, $(this) );
			}
		} );

		$( ".selectmenu" ).selectmenu({
			change: function( e, data ) {
				UIselectors( e.target.id, data.item.value );
			}
		} );

		$( "#console-only-errors" ).prop( "checked", false )
						.checkboxradio()
						.change( consoleOption );

		$( ".input-editable" ).prop( "checked", false )
						.checkboxradio()
						.change( inputEditable );

		$( document ).on( "click", ".button", UIbuttons );

		myZDL.initClient().then(function() {
			statusInit();
			statusFlow( true );
			downloadFlow( true );
			initTable();
			ZDLconsole( "client-init", actionPATH );
		} ).catch(function( e ) {
			ZDLconsole( "client-init-error", e, true );
			console.log(e);
		} );
	} );
}

function statusInit() {
	if ( zdlRunning ) {
		myZDL.getFreeSpace().then( function( space ) {
	        $( "#free-space" ).text( space );
	    } );

	    myZDL.getDesktopPath().then( function( path ) {
	        $( "#conf-desktop" ).val( path );
	    } );

	    $( "#new-socket" ).val( parseInt( window.location.port ) + 1 );

	    myZDL.getPlaylist().then( function( data ) {
	        if ( isJson( data ) ) {
	            buildPlaylist( JSON.parse( data ) );
	        }
	    } );
	}
}

function statusFlow() {
    var arg = arguments[ 0 ] || false;
    myZDL.getStatus( arg ).then( function( res ) {
        if ( isJson( res ) ) {
            var obj = JSON.parse( res ), status;
			obj.status === "running" ? status = true : status = false;
			if ( status !== zdlRunning ) {
				$( "#zdl-quit, #zdl-killall, #zdl-run" ).toggleClass( "hide" );
				$( "#wait" ).addClass( "hide" );
				zdlRunning = status;
			}
            if ( !obj.conf.resume ) obj.conf.resume = "disabled";
            if ( obj.conf.language === "it_IT.UTF-8" ) obj.conf.language = "it";
            $( "#path" ).val( obj.path );
            $( "#downloader" ).val( obj.downloader );
            $( "#max-downloads" ).val( obj.maxDownloads );
            $( "#max-xdcc" ).val( 50 );
            $( "#reconnect" ).val( obj.reconnect );
            $( "#conf-downloader" ).val( obj.conf.conf_downloader );
            $( "#conf-axel-parts" ).val( obj.conf.axel_parts );
            $( "#conf-aria2-parts" ).val( obj.conf.aria2_connections );
            $( "#conf-max-downloads" ).val( obj.conf.max_dl );
            $( "#conf-bg-terminal" ).val( obj.conf.background );
            $( "#conf-language" ).val( obj.conf.language );
            $( "#conf-reconnecter" ).val( obj.conf.reconnecter );
            $( "#conf-auto-update" ).val( obj.conf.autoupdate );
            $( "#conf-player" ).val( obj.conf.player );
            $( "#conf-editor" ).val( obj.conf.editor );
            $( "#conf-resume" ).val( obj.conf.resume );
            $( "#conf-start-mode" ).val( obj.conf.zdl_mode );
            $( "#conf-torrent-tcp" ).val( obj.conf.tcp_port );
            $( "#conf-torrent-udp" ).val( obj.conf.udp_port );
            $( "#conf-socket-tcp" ).val( obj.conf.socket_port );
            $( "#conf-browser" ).val( obj.conf.browser );

            $( ".selectmenu" ).selectmenu( "refresh" );

            displaySocketsButtons( obj.sockets );

            if ( arg ) showUI();
        }
        //if ( !arg && !logOnlyErrors ) ZDLconsole( "status-update" );
        statusFlow();
    } ).catch( function( e ) {
		if ( zdlRunning ) {
			ZDLconsole( "status-flow-error", e );
			statusFlow();
		}
    } );
}

function downloadFlow() {
    var arg = arguments[ 0 ] || false;
    myZDL.getData( arg ).then( function( res ) {
        if ( isJson( res ) ) {
            var obj = JSON.parse( res ),
                index, len, dlstat, perc, status, statusParent, bginfo;
            $.each( obj, function( index, value ) {
                perc = parseInt( value.percent );
                if ( perc < 100 ) {
                    if ( value.color === "yellow" ) {
						bginfo = "unterminated";
					} else if ( value.color === "red" ) {
						bginfo = "aborted";
					} else {
						bginfo = "downloading";
					}
                    dlstat = value.percent + "% " + Math.round( value.speed ) + value.speed_measure + " " + value.eta;
                } else {
                    dlstat = "100%";
					bginfo = "";
                }
                len = formatFileLength( value.length );
                if ( fileList.indexOf( value.file ) < 0 ) {
                    index = fileList.length;
					if ( bginfo ) bginfo = " " + bginfo;
                    $( "<div class=\"progressbar\"><div class=\"side-bar\"><div id=\"bar-" + index + "\"><div class=\"label\">" + value.file + "</div></div></div><div class=\"side-info" + bginfo + "\"><span id=\"dl-status-" + index + "\"></span></div><div class=\"side-button\"><button data-i18n=\"button-info\" id=\"btn-info-" + index + "\" class=\"button open-info\" data-toggler=\"info-" + index + "\">Info</button></div></div><div class=\"toggler\"><div id=\"info-" + index + "\" class=\"info ui-widget-content ui-corner-all\"><ul><li><span>Downloader: </span>" + value.downloader + "</li><li><span>Link: </span>" + value.link + "</li><li><span>Path: </span>" + value.path + "</li><li><span>Length: </span>" + len + "</li><li><span>URL: </span>" + value.url + "</li></ul><button data-i18n=\"button-manage\" id=\"btn-manage-" + index + "\" class=\"button dl-manage\" data-path=\"" + value.path + "\">Manage</button><button data-i18n=\"button-play\" id=\"btn-play-" + index + "\" class=\"button dl-play\" data-file=\"" + value.path + "/" + value.file + "\">Play</button><button data-i18n=\"button-playlist\" id=\"btn-playlist-" + index + "\" class=\"button dl-playlist\" data-file=\"" + value.path + "/" + value.file + "\">Add to playlist</button><button data-i18n=\"button-stop\" id=\"btn-stop-" + index + "\" class=\"button dl-stop\" data-link=\"" + value.link + "\" data-file=\"" + value.file + "\">Stop</button><button data-i18n=\"button-delete\" id=\"btn-delete-" + index + "\" class=\"button dl-delete\" data-link=\"" + value.link + "\" data-file=\"" + value.file + "\">Delete</button></div></div>" ).appendTo( "#downloads" );
                    $( "#dl-status-" + index ).text( dlstat );
                    $( ".button" ).button();
                    if ( perc === 0 ) {
                        $( "#bar-" + index ).progressbar( {
                            value: false
                        } );
                    } else {
                        $( "#bar-" + index ).progressbar( {
                            value: perc
                        } );
                    }
                    fileList.push( value.file );
                } else {
                    index = fileList.indexOf( value.file );
					status = $( "#dl-status-" + index );
					statusParent = status.parent();
					if ( !statusParent.hasClass( bginfo ) ) {
						statusParent.removeClass().addClass( "side-info " + bginfo );
					}
                    $( "#bar-" + index ).progressbar( "value", perc );
                    status.text( dlstat );
                    if ( isDownloaded( value.file, perc ) ) {
                        ZDLconsole( "file-downloaded", value.file );
                        statusParent.removeClass( "downloading" );
                    }
                }
            } );
			$( "#downloads" ).i18n();
        }
        downloadFlow();
    } ).catch( function( e ) {
		if ( zdlRunning ) {
			ZDLconsole( "download-flow-error", e );
			downloadFlow();
		}
    } );
}

function initTable() {
    return $( "#xdcc-eu" ).DataTable( {
        "order": [[ 4, "desc" ]],
		"retrieve": true,
		"paginate": false,
		"responsive": true,
        "columnDefs": [
            { "responsivePriority": 1, "targets": 0 },
			{ "responsivePriority": 1, "targets": -3 },
		]
    } );
}

function showUI() {
	$( ".loader" ).hide();
    $( ".wrapper" ).show();
	console.log( "show UI" );
}
