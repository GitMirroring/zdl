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

/* jshint esversion: 6 */

/* Clean the xhr response */
function clean( str ) {
    return str.replace( /(\r?\n|\r)/gm, "" );
}

/* Ckeck if an account exist */
function checkAccount() {
    var xhr = new XMLHttpRequest();
    xhr.open( "GET", "login.html?cmd=check-account", true );
    xhr.onload = () => {
        if ( xhr.status === 200 ) {
            if ( clean( xhr.responseText ) === "exists" ) {
                displayForm( "login" );
            } else {
                displayForm( "signup" );
            }
        } else if ( xhr.status === 302 ) {
            window.location.replace( "login.html" );
        } else {
            console.log( `login error (${xhr.status})` );
        }
    };
    xhr.onerror = () => {
        console.log( "network request failed" );
    };

    xhr.send();
}

/* Create a new account */
function createAccount( user, pwd ) {
    var xhr = new XMLHttpRequest();
    xhr.open( "POST", "login.html", true );
    xhr.onload = () => {
        if ( xhr.status === 200 ) {
            checkAccount();
        } else {
            console.log( `create account error (${xhr.status})` );
        }
    };
    xhr.onerror = () => {
        console.log( "network request failed" );
    };

    xhr.send( `cmd=create-account&user=${user}&pass=${pwd}` );
}

/* Dispaly the form to signup/signin */
function displayForm( name ) {
    var forms = [
            "login", "signup"
        ],
        idx = 1 - forms.indexOf( name ),
        view = document.getElementById( name ),
        hide = document.getElementById( forms[ idx ] );

    if ( window.getComputedStyle( view ).display === "none" ) {
        view.style.display = "block";
        hide.style.display = "none";
    }
}

var url = new URL( window.location.href ),
    inputs = document.querySelectorAll( ".form input" );

if ( url.searchParams.get( "op" ) === "retry" ) {
    document.querySelector( "#login .error" ).textContent = "Login errato: riprova";
} else {
    checkAccount();
} [ "blur", "focus" ].forEach( function ( e ) {
    for ( var input of inputs ) {
        input.addEventListener( e, function ( event ) {
            var label = this.previousElementSibling;
            if ( event.type === "focus" ) {
                label.classList.add( "highlight" );
            } else {
                label.classList.remove( "highlight" );
            }
        }, false );
    }
} );

/* Add an event listener to the signup button */
document.querySelector( "#signup button" ).addEventListener( "click", function ( e ) {
    var pwds = document.querySelectorAll( ".pwd" );
    if ( pwds[ 0 ].value !== pwds[ 1 ].value ) {
        document.querySelector( "#signup .error" ).textContent = "Le password non combaciano: controlla";
    } else {
        var usr = document.getElementById( "user" ).value;
        createAccount( usr, pwds[ 0 ].value );
    }
} );
