var utils = {
	/* Browse file and directory tree of the path */
	browseFs: function( path, id, type ) {
        if ( type === "folders" ) {
            $( "#" + id ).val( path );
        }
		$( "#current-path" ).text( path );
        myZDL.browseFS( path, type ).then( function ( res ) {
            if ( res ) {
                var items = res.replace( /;?\n?$/, "" ).split( ";" ),
                    parent = path.substring( 0, path.lastIndexOf( "/" ) ),
                    params = function ( p ) {
                        return "'" + p.replace( /\s/g, "%20" ) + "','" + id + "','" + type + "'";
                    },
                    node = "";
                if ( !parent ) {
                    parent = "/";
                }
                if ( path !== "/" ) {
                    node += "<li><a href=javascript:utils.browseFs(" + params( parent ) + ");>..</a></li>";
                } else {
                    path = "";
                }
                $.each( items, function ( index, item ) {
                    if ( item ) {
                        if ( type === "folders" || /^\[.+\]$/.test( item ) ) {
                            item = item.slice( 1, -1 );
                            node += "<li><a href=javascript:utils.browseFs(" + params( path + "/" + item ) + ");>" + item + "</a></li>";
                        } else {
                            node += "<li><a href=javascript:utils.selectFile(" + params( path + "/" + item ) + ");>" + item + "</a></li>";
                        }
                    }
                } );
				$( "#" + id + "-tree" ).empty().append( node );
            }
        } );
    },

	/* Show the file path selected */
    selectFile: function ( path, id ) {
        $( "#" + id ).val( path );
    },
};
