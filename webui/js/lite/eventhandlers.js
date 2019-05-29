function buttonHandler( e ) {
    var input,
        inputData;
    switch ( e.target.id ) {
        case "fast-download":
            input = $( "#input-fast" );
            inputData = input.val();
            if ( validateInput( inputData, "URL" ) ) {
                myZDL.addLink( inputData )
                    .then( function () {
                        input.val( "" );
                    } );
            } else {
                client.alert( "Il link inserito non è corretto!" );
            }
            break;
        case "clean-completed":
            myZDL.cleanCompleted()
                .then( function () {
                    $( ".custom-bar" )
                        .each( function () {
                            if ( $( this )
                                .find( ".progress-bar" )
                                .attr( "aria-valuenow" ) === "100" ) {
                                client.remove( "list", $( this )
                                    .data( "file" ) );
                                $( this )
                                    .remove();
                            }
                        } );
                } );
            break;
        case "change-path":
            inputData = $( "#action-path" )
                .val();
            if ( inputData !== myZDL.path ) {
                if ( validateInput( inputData, "path" ) ) {
                    myZDL.initClient( inputData )
                        .then( function () {
                            console.log( "ZDL | client inizializzato nel path:", inputData );
                        } )
                        .catch( function ( e ) {
                            client.alert( "Errore nell'inizializzazione del client: " + e );
                        } );
                } else {
                    client.alert( "Il path inserito non è corretto!" );
                }
            } else {
                client.alert( "Il client è già inizializzato su questo path!" );
            }
            break;
        case "send-link":
            input = $( "#input-link" );
            inputData = input.val();
            if ( validateInput( inputData, "URL" ) ) {
                myZDL.addLink( inputData )
                    .then( function () {
                        input.val( "" );
                    } );
            } else {
                client.alert( "Il link inserito non è corretto!" );
            }
            break;
        case "send-xdcc":
            input = $( "#input-xdcc" );
            inputData = input.val();
            if ( validateInput( inputData, "URL" ) ) {
                myZDL.addXdcc( inputData )
                    .then( function ( res ) {
                        var response = res.trim();
                        if ( response ) {
                            client.alert( "Comando xdcc già presente!" );
                        } else {
                            input.val( "" );
                        }
                    } );
            } else {
                client.alert( "Il comando xdcc inserito non è corretto!" );
            }
            break;
        case "send-torrent":
            input = $( "#input-torrent" );
            inputData = input.val();
            if ( validateInput( inputData, "path" ) ) {
                myZDL.addTorrent( inputData )
                    .then( function () {
                        input.val( "" );
                    } );
            } else {
                client.alert( "Il path del torrent inserito non è corretto!" );
            }
            break;
        case "webui-exit":
            $( this )
                .attr( "disabled", true )
                .html( "CHIUDO <i class='fas fa-cog fa-spin'></i>" );
            myZDL.exitAll()
                .then( function () {
                    setTimeout( function () {
                        window.location.href = window.location.pathname;
                    }, 2000 );
                } );
            break;
        default:
            var link,
                fileName;
            if ( $( this )
                .hasClass( "stop-download" ) ) {
                link = $( this ).data( "link" );
                fileName = $( this ).data( "file" );
                if ( client.exist( "active", fileName ) ) {
                    myZDL.stopLink( encodeURIComponent( link ) ).then( function () {
                        console.log( "ZDL | fermato il download di:", link );
                    } );
                }
            } else if ( $( this )
                .hasClass( "delete-download" ) ) {
                link = $( this ).data( "link" );
                fileName = $( this ).data( "file" );
                var path = $( this ).data( "path" ),
                    $this = $( this );
                myZDL.deleteLink( encodeURIComponent( link ), path ).then( function () {
                    $this.closest( ".custom-bar" ).remove();
                    if ( client.exist( "active", fileName ) ) {
                        client.remove( "active", fileName );
                    }
                    client.remove( "list", fileName );
                    console.log( "ZDL | cancellato il download di:", fileName );
                } );
            } else if ( $( this )
                .hasClass( "change-downloader" ) ) {
                var downloader = $( this )
                    .text();
                myZDL.command( "set-downloader", "downloader=" + downloader )
                    .then( function () {
                        console.log( "ZDL | cambiato downloader nel path:", downloader );
                    } );
            } else if ( $( this )
                .hasClass( "change-webui" ) ) {
                var webui = $( this )
                    .data( "value" );
                myZDL.setConf( "web_ui", webui )
                    .then( function () {
                        window.setTimeout( function () {
                            window.location.href = window.location.pathname;
                        }, 2000 );
                    } );
            } else {
                return false;
            }
    }
}

function validateInput( str, type ) {
    var pattern = {
        URL: /^(?:(irc|https?):\/\/)?[\w\.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+(\/msg\s.+\sxdcc\ssend\s#\d+)?$/,
        path: /^\/$|(^(?=\/)|^\.|^\.\.|^\~|^\~(?=\/))(\/(?=[^/\0])[^/\0]+)*\/?$/g
    };
    return pattern[ type ].test( str );
}
