/* jshint esversion: 7 */

var client = ( function () {
    var data = {
        list: [],
        active: [],
        running: true
    };

    /* Validate json */
    function parseJson( str ) {
        try {
            JSON.parse( str );
        } catch ( e ) {
            return false;
        }
        return true;
    }

    /* Monitoring download */
    function downloadCompleted( file, perc ) {
        if ( perc < 100 && !data.active.includes( file ) ) {
            data.active.push( file );
        } else {
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
        return parseFloat( ( bytes / 1024 ** i )
            .toFixed( 2 ) ) + " " + sizes[ i ];
    }

    function alertModal( message ) {
        $( "<div class='modal fade' id='errorModal' role='dialog'><div class='modal-dialog'><div class='modal-content'><div class='modal-body text-center p-10'><h4 class='modal-alert'>Errore!</h4><p>" + message + "</p><div class='text-center'><button class='btn btn-danger btn-close'>Chiudi</button></div></div></div></div> " )
            .appendTo( 'body' );

        $( "#errorModal" )
            .modal( {
                backdrop: 'static',
                keyboard: false
            } );

        $( ".btn-close" )
            .click(function () {
                $("#errorModal").modal("hide");
            });

        $( "#errorModal" )
            .on( 'hidden.bs.modal', function () {
                $( "#errorModal" )
                    .remove();
            } );
    }

    /* Configuration settings (polling) */
    function statusFlow() {
        var arg = arguments[ 0 ] || false;
        myZDL.getStatus( arg )
            .then( function ( res ) {
                if ( parseJson( res ) ) {
                    var obj = JSON.parse( res ),
                        running = false;
                    if ( obj.status === "running" ) {
                        running = true;
                    }
                    if ( data.running !== running ) {
                        data.running = running;
                    }
                    $( "#action-path" )
                        .val( obj.path );
                    $( "#local-downloader" )
                        .val( obj.downloader );
                }
                statusFlow();
            } )
            .catch( function ( e ) {
                if ( data.running ) {
                    console.log( "ZDL | status flow error:", e );
                    statusFlow();
                }
            } );
    }

    /* Downloads management (polling) */
    function downloadFlow() {
        var arg = arguments[ 0 ] || false;
        myZDL.getData( arg )
            .then( function ( res ) {
                if ( parseJson( res ) ) {
                    var obj = JSON.parse( res ),
                        id,
                        len,
                        perc,
                        progress,
                        statusVal;
                    $.each( obj, function ( index, value ) {
                        id = $.md5( value.link );
                        perc = parseInt( value.percent );
                        if ( perc < 100 ) {
                            statusVal = value.percent + "% " + Math.round( value.speed ) + value.speed_measure + " " + value.eta;
                        } else {
                            statusVal = "100%";
                        }
                        len = formatFileLength( value.length );
                        if ( !data.list.includes( value.file ) ) {
                            $( "<div class='custom-bar'><div class='progress custom-progress'><div id='bar-" + id + "' class='progress-bar green' role='progressbar' aria-valuenow='0' aria-valuemin='0' aria-valuemax='100' data-file='" + value.file + "'></div></div><div class='custom-info' data-toggle='collapse' data-target='#collapse-" + id + "' aria-expanded='false' aria-controls='collapse-" + id + "'><div class='row'><div class='filename col-12 col-md-10'>" + value.file + "</div><div id='status-" + id + "' class='status col-12 col-md-2'>" + statusVal + "</div></div></div><div class='collapse custom-commands' id='collapse-" + id + "'><div class='card card-body'><button class='btn custom-btn-style-1 _size-2 text-color-light custom-handler stop-download' type='button' data-file='" + value.file + "' data-link='" + value.link + "'><i class='fas fa-minus-circle mr-2'></i>FERMA</button><button class='btn custom-btn-style-1 _size-2 text-color-light custom-handler delete-download' type='button' data-path='" + value.path + "' data-link='" + value.link + "' data-file='" + value.file + "'><i class='fas fa-trash mr-2'></i>ELIMINA</button></div></div></div>" )
                                .prependTo( "#downloads" );
                            $( "#bar-" + id )
                                .css( "width", perc + "%" )
                                .attr( "aria-valuenow", perc );
                            data.list.push( value.file );
                        } else {
                            progress = $( "#bar-" + id );
                            if ( !progress.hasClass( value.color ) ) {
                                progress.removeClass()
                                    .addClass( "progress-bar " + value.color );
                            }
                            progress.css( "width", perc + "%" )
                                .attr( "aria-valuenow", perc );
                            $( "#status-" + id )
                                .text( statusVal );
                            if ( downloadCompleted( value.file, perc ) ) {
                                console.log( "ZDL | file downloaded:", value.file );
                            }
                        }
                    } );
                }
                downloadFlow();
            } )
            .catch( function ( e ) {
                if ( data.running ) {
                    console.log( "ZDL | download flow error:", e );
                    downloadFlow();
                }
            } );
    }

    /*Start the client */
    function init() {
        // event delegation
        $( "#main" )
            .on( "click", ".custom-handler", buttonHandler );

        // init client
        myZDL.initClient()
            .then( function () {
                statusFlow( true );
                downloadFlow( true );
                console.log( "ZDL | client inizialized on path: ", myZDL.path );
            } )
            .catch( function ( e ) {
                console.log( "ZDL | inizialization error:", e );
            } );
    }

    // expose
    return {
        remove: function ( key, name ) {
            data[ key ].splice( data[ key ].indexOf( name ), 1 );
        },
        exist: function ( key, name ) {
            return data[ key ].includes( name );
        },
        alert: function ( msg ) {
            alertModal( msg );
        },
        init: init
    };
} )();
