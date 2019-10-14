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

page.settings.userAgent = 'Mozilla/5.0 (Linux; Android 6.0; LENNY3 Build/MRA58K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.132 Mobile Safari/537.36';

page.onResourceReceived = function(response) {
    if (response.contentType && response.contentType.match(/video/g)) {
	console.log(response.url);
    }
};

page.open(system.args[1], function(status) {
    phantom.exit();
});

page.onInitialized = function() {
    page.evaluate(function() {
	delete window.callPhantom;
	delete window._phantom;
    });
};
