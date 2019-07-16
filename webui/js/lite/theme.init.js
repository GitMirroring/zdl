// Commom Plugins
( function ( $ ) {

    'use strict';

    // Sticky Header
    if ( typeof theme.StickyHeader !== 'undefined' ) {
        theme.StickyHeader.initialize();
    }

    // Nav Menu
    if ( typeof theme.Nav !== 'undefined' ) {
        theme.Nav.initialize();
    }

    // Scroll to Top Button.
    if ( typeof theme.ScrollToTop !== 'undefined' ) {
        theme.ScrollToTop.initialize();
    }

} )
.apply( this, [ jQuery ] );

// Section Scroll
( function ( $ ) {

    'use strict';

    if ( $.isFunction( $.fn[ 'themeSectionScroll' ] ) ) {

        $( function () {
            $( '[data-section-scroll]:not(.manual)' )
                .each( function () {
                    var $this = $( this ),
                        opts;

                    var pluginOptions = theme.fn.getOptions( $this.data( 'plugin-options' ) );
                    if ( pluginOptions )
                        opts = pluginOptions;

                    $this.themePluginSectionScroll( opts );
                } );
        } );

    }

} )
.apply( this, [ jQuery ] );
