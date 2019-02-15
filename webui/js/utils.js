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

function ZDLconsole( key, param, error = false ) {
    if ( !logOnlyErrors || error) {
        var to2 = function( i ) {
                if ( i < 10 ) return "0" + i;
                return i;
            },
            date = new Date(),
            time = to2( date.getHours() ) + ":" + to2( date.getMinutes() ) + ":" + to2( date.getSeconds() ),
            type = "event",
            msg;

        if ( param ) msg = $.i18n( key, param );
        else msg = $.i18n( key );

        if ( error ) {
            type = "error";
            $( "#tabs" ).tabs( "option", "active", 6 );
        }

        $( "#console" ).append( "<span class=\"" + type + "\">" + time + " > " + msg.trim() + "</span>" );
    }
}

function isJson( str ) {
    try {
        JSON.parse( str );
    } catch ( e ) {
        return false;
    }
    return true;
}

function isDownloaded( file, perc ) {
    if ( perc < 100 && isDownloading.indexOf( file ) < 0 ) {
        isDownloading.push( file );
    } else {
        var index = isDownloading.indexOf( file );
        if ( index >= 0 && perc === 100 ) {
            isDownloading.splice( index, 1 );
            return true;
        }
    }
    return false;
}

function formatFileLength( bytes ) { // stackoverflow 15900485
    if ( !bytes ) return "---";
    var sizes = [ "Bytes", "KB", "MB", "GB", "TB" ],
        i = Math.floor( Math.log( bytes ) / Math.log( 1024 ) );
    return parseFloat( ( bytes / Math.pow( 1024, i ) ).toFixed( 2 ) ) + " " + sizes[ i ];
}

function displaySocketsButtons( sockets ) {
    $( ".socket" ).each( function() {
        $( this ).remove();
    } );
    $.each( sockets, function( index, value ) {
        $( "<button class=\"socket button\">" + value + "</button>" ).appendTo( ".sockets-go" );
        $( "<button class=\"socket button\">" + value + "</button>" ).appendTo( ".sockets-kill" );
    } );
    $( ".socket" ).button();
}

function browseFs( path, id, type ) {
    if ( type === "folders" ) {
        $( "#" + id + "-path" ).val( path );
    }
    myZDL.browseFS( path, type ).then( function( res ) {
        if ( res ) {
            var items = res.replace( /;?\n?$/, "" ).split( ";" ),
                parent = path.substring( 0, path.lastIndexOf( "/" ) ),
                fix = function( p ) {
                    return p.replace( /\s/g, "%20" );
                },
                tree,
                node;
            if ( !parent ) parent = "/";
            tree = $( "#" + id + "-tree" ).empty();
            if ( path !== "/" ) {
                node = "<li class=\"folder\"><a href=javascript:browseFs(\"" + fix( parent ) + "\",\"" + id + "\",\"" + type + "\");>..</a></li>";
                tree.append( node );
            } else {
                path = "";
            }
            $.each( items, function( index, item ) {
                if ( item ) {
                    if ( type === "folders" || /^\[.+\]$/.test( item ) ) {
                        item = item.slice( 1, -1 );
                        node = "<li class=\"folder\"><a href=javascript:browseFs(\"" + fix( path + "/" + item ) + "\",\"" + id + "\",\"" + type + "\");>" + item + "</a></li>";
                    } else {
                        node = "<li class=\"" + type + "\"><a href=javascript:selectFile(\"" + fix( path + "/" + item ) + "\",\"" + id + "\");>" + item + "</a></li>";
                    }

                    tree.append( node );
                }
            } );
        }
    } );
}

function buildPlaylist( data ) {
    var playlist = $( "#playlist" ),
        node,
        filename;
    $.each( data, function( index, file ) {
        filename = file.replace( /^.*(\/)/, '' );
        node = "<div class=\"pl-item\"><div class=\"pl-file\">" + filename + "</div><div class=\"pl-buttons\"><button data-i18n=\"button-play\" class=\"button dl-play\" data-file=\"" + file + "\">Play</button><button data-i18n=\"button-delete\" class=\"button pl-delete\" data-file=\"" + file + "\">Delete</button></div></div>";
        playlist.append( node );
    } );
    $( ".button" ).button();
}

function addToPlaylist( file ) {
    var playlist = $( "#playlist" ),
        node,
        filename = file.replace( /^.*(\/)/, '' );
    node = "<div class=\"pl-item\"><div class=\"pl-file\">" + filename + "</div><div class=\"pl-buttons\"><button data-i18n=\"button-play\" class=\"button dl-play\" data-file=\"" + file + "\">Play</button><button data-i18n=\"button-delete\" class=\"button pl-delete\" data-file=\"" + file + "\">Delete</button></div></div>";
    playlist.append( node );
    $( ".button" ).button();
}

function selectFile( path, id ) {
    $( "#" + id + "-path" ).val( path );
}

function inputEditable() {
    var isChecked = $( this ).prop( "checked" ),
        input = $( this ).parent().find( "input:text" );
    if ( isChecked ) input.prop( "readonly", false );
    else input.prop( "readonly", true );
}

function consoleOption() {
    var isChecked = $( this ).prop( "checked" );
    if ( isChecked ) logOnlyErrors = true;
    else logOnlyErrors = false;
}

function validateInput( str, type ) {
    /* jshint ignore: start */
    var pattern = {
        "URL": /^(?:(irc|https?):\/\/)?[\w\.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+(\/msg\s.+\sxdcc\ssend\s#\d+)?$/,
        "path": /^((\/([\w\.\-\(\)\]\[\?\\@\$\^#&=|:;, ])+)+)|([\w\-]+)$/
    };
    /* jshint ignore: end */
    return pattern[ type ].test( str );
}

function localizeRadioLabels() {
    $( "#console-only-errors" ).checkboxradio( "option", "label", $.i18n( "radio-only-errors" ) );
    $( ".input-editable" ).checkboxradio( "option", "label", $.i18n( "radio-input-edit" ) );
}
