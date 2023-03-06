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

/**
 * ZDL class
 * Send requests to zdl server
 */
class ZDL {
    constructor( path, file ) {
        this.path = path;
        this.file = file;
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

    initClient( path ) {
        if ( path ) this.path = path;
        return this.request( `cmd=init-client&path=${this.path}` );
    }

    getLanguage() {
        return this.request( "cmd=get-language" );
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

    getLivestream() {
        return this.request( "cmd=get-livestream-opts" );
    }

    getConsoleLog( path, loop ) {
        return this.request( `cmd=get-console&path=${path}&loop=${loop}` );
    }

    getIP() {
        return this.request( "cmd=get-ip" );
    }

    getPlaylist() {
        return this.request( "cmd=get-playlist" );
    }

    addLink( url ) {
        url = encodeURIComponent( url );
        return this.request( `cmd=add-link&path=${this.path}&link=${url}` );
    }

    addTorrent( torrent ) {
        torrent = encodeURIComponent( torrent );
        return this.request( `cmd=add-link&path=${this.path}&link=${torrent}&type=torrent` );
    }

    addXdcc( xdcc ) {
        return this.request( `cmd=add-xdcc&path=${this.path}&host=${xdcc.host}&chan=${xdcc.channel}&ctcp=${xdcc.msg}` );
    }

    searchXdcc( term ) {
        return this.request( `cmd=search-xdcc&term=${term}` );
    }

    stopLink( link ) {
        link = encodeURIComponent( link );
        return this.request( `cmd=stop-link&path=${this.path}&link=${link}` );
    }

    stopConsoleLog() {
        return this.request( "cmd=stop-console" );
    }

    deleteLink( link, path ) {
        link = encodeURIComponent( link );
        return this.request( `cmd=del-link&path=${path}&link=${link}` );
    }

    deleteFile( file ) {
        return this.request( `cmd=del-file&path=${this.path}&file=${file}` );
    }

    playlistAdd( file ) {
        return this.request( `cmd=add-playlist&file=${file}` );
    }

    playlistDelete( file ) {
        return this.request( `cmd=del-playlist&file=${file}` );
    }

    playPlaylist( list ) {
        return this.request( `cmd=play-playlist&files=${list}` );
    }

    playMedia( file ) {
        return this.request( `cmd=play-media&file=${file}` );
    }

    extractAudio( video, format ) {
        return this.request( `cmd=extract-audio&video=${video}&format=${format}` );
    }

    browseFS( path, type ) {
        return this.request( `cmd=browse-fs&path=${path}&type=${type}` );
    }

    cleanCompleted() {
        return this.request( `cmd=clean-complete&path=${this.path}` );
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

    setLivestream( path, link, start, duration ) {
        link = encodeURIComponent(link);
        return this.request( `cmd=set-livestream&path=${path}&link=${link}&start=${start}&duration=${duration}` );
    }

    createAccount( user, pwd ) {
        return this.request( `cmd=create-account&user=${user}&pass=${pwd}` );
    }

    resetAccount() {
        this.request( "cmd=reset-account" );
    }

    checkVersion() {
        return this.request( "cmd=check-version" );
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
