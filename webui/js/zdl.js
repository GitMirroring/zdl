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

class ZDL {
    constructor( path, file ) {
        this.path = path;
        this.file = file;
    }

    getPath() {
        return this.path;
    }

    request( query ) {
        return new Promise( ( resolve, reject ) => {

            var xhr = new XMLHttpRequest();

            xhr.open( "GET", `${this.file}?${query}`, true );

            xhr.onload = () => {
                if ( xhr.status === 200 ) {
                    resolve( xhr.responseText );
                } else {
                    reject( `bad response status (${xhr.status})` );
                }
            };

            xhr.onerror = () => {
                reject( "network request failed" );
            };

            xhr.send();
        } );
    }

    initClient() {
        return this.request( `cmd=init-client&path=${this.path}` );
    }

    getStatus( loop ) {
        var query = `cmd=get-status&path=${this.path}`;
        if ( loop ) query += "&op=loop";
        return this.request( query );
    }

    getData( force ) {
        var query = "cmd=get-data";
        if ( force ) query += "&op=force";
        return this.request( query );
    }

    getFile( file ) {
        return this.request( `cmd=get-file&path=${this.path}&file=${file}` );
    }

    getFreeSpace() {
        return this.request( `cmd=get-free-space&path=${this.path}` );
    }

	getLinks() {
        return this.request( `cmd=get-links&path=${this.path}` );
    }

    getDesktopPath() {
        return this.request( "cmd=get-desktop-path" );
    }

    getIP() {
        return this.request( "cmd=get-ip" );
    }

    getPlaylist() {
        return this.request( "cmd=get-playlist" );
    }

    addLink( url ) {
        return this.request( `cmd=add-link&path=${this.path}&link=${url}` );
    }

    addTorrent( torrent ) {
        return this.request( `cmd=add-link&path=${this.path}&link=${torrent}&type=torrent` );
    }

    addXdcc( xdcc ) {
        return this.request( `cmd=add-xdcc&path=${this.path}&host=${xdcc.host}&chan=${xdcc.channel}&ctcp=${xdcc.msg}` );
    }

    searchXdcc( term ) {
        return this.request( `cmd=search-xdcc&term=${term}` );
    }

    addPlaylist( file ) {
        return this.request( `cmd=add-playlist&file=${file}` );
    }

    stopLink( link ) {
        return this.request( `cmd=stop-link&path=${this.path}&link=${link}` );
    }

    deleteLink( link ) {
        return this.request( `cmd=del-link&path=${this.path}&link=${link}` );
    }

    deleteFile( file ) {
        return this.request( `cmd=del-file&path=${this.path}&file=${file}` );
    }

    deletePlaylist( file ) {
        return this.request( `cmd=del-playlist&file=${file}` );
    }

    browseFS( path, type ) {
        return this.request( `cmd=browse-fs&path=${path}&type=${type}` );
    }

    cleanCompleted() {
        return this.request( `cmd=clean-complete&path=${this.path}` );
    }

    play( file ) {
        return this.request( `cmd=play-link&path=${this.path}&file=${file}` );
    }

    playPlaylist( file ) {
        return this.request( `cmd=play-playlist&file=${file}` );
    }

    command( cmd, params ) {
        return this.request( `cmd=${cmd}&path=${this.path}&${params}` );
    }

    setConf( key, value ) {
        return this.request( `cmd=set-conf&key=${key}&value=${value}` );
    }

    setDesktopPath( path ) {
        return this.request( `cmd=set-desktop-path&path=${path}` );
    }

    createAccount(user, pwd) {
        return this.request( `cmd=create-account&user=${user}&pass=${pwd}` );
    }

    resetAccount() {
        this.request( "cmd=reset-account" );
    }

    startSocket( port ) {
        return this.request( `cmd=run-server&port=${port}` );
    }

    killSocket( port ) {
        return this.request( `cmd=kill-server&port=${port}` );
    }

    modemReconnect( str ) {
        var query = `cmd=reconnect&path=${this.path}`;
        if ( str ) query += `&loop=${str}`;
        return this.request( query );
    }

    run() {
        return this.request( `cmd=run-zdl&path=${this.path}` );
    }

    quit() {
        return this.request( `cmd=quit-zdl&path=${this.path}` );
    }

    kill() {
        return this.request( `cmd=kill-zdl&path=${this.path}` );
    }

    reset() {
        this.request( `cmd=reset-requests&path=${this.path}` );
    }

    killServer( ports ) {
        var params = "";
        ports.forEach( ( port ) => {
            params += `&port=${port}`;
        } );
        return this.request( `cmd=kill-server${params}` );
    }

    killAll() {
        return this.request( "cmd=kill-all" );
    }

    exitAll() {
        var that = this;
        return this.request( "cmd=kill-all" ).then( () => {
            this.request( "cmd=get-sockets" ).then( ( res ) => {
                that.killServer( JSON.parse( res ) );
            } );
        } );
    }
}
