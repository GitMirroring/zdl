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
//


var separator = '\n';
var page = require('webpage').create(),
    system = require('system'),
    id, match;

if(system.args.length < 2) {
    console.error('No URL provided');
    phantom.exit(1);
}
match = system.args[1].match(
	/https?:\/\/(?:openload\.(?:co|io)|oload\.tv)\/(?:f|embed)\/([\w\-]+)/);
if(match === null) {
    console.error('Could not find video ID in provided URL');
    phantom.exit(2);
}
id = match[1];

page.settings.userAgent = 'Mozilla/5.0 (Linux; Android 6.0; LENNY3 Build/MRA58K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.132 Mobile Safari/537.36';

page.open('https://openload.co/embed/' + id + '/', function(status) {
    var stream_id = system.args[2];
    var info = page.evaluate(function(stream_id) {	
	return {
	    decoded_id: document.getElementById(stream_id).innerHTML, 
	    title: document.querySelector('meta[name="og:title"],'
					  + 'meta[name=description]').content
	};
    }, stream_id);
    var url = 'https://openload.co/stream/' + info.decoded_id + '?mime=true';
    console.log(url + separator + info.title);
    phantom.exit();
});

page.onInitialized = function() {
    page.evaluate(function() {
	delete window.callPhantom;
	delete window._phantom;
    });
};
