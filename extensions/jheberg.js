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
    system = require('system');

if(system.args.length < 2) {
    console.error('No URL provided');
    phantom.exit(1);
}

var url_in = system.args[1];

//page.settings.userAgent = 'Mozilla/5.0 (Linux; Android 6.0; LENNY3 Build/MRA58K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.132 Mobile Safari/537.36';
page.settings.userAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0";

page.onConsoleMessage = function (msg) {
    console.log(msg);
};

page.open(url_in, function(status) {
    page.evaluate(function() {
	//	console.log(document.getElementById('jschl-answer').value);
	console.log(document.cookie);
    });
    // phantom.addCookie({
    // 	'file_id': file_id,
    // 	'aff': aff,
    // 	'domain': 'flashx.to',
    // 	'path': '/',
    // 	'httponly': true,
    // 	'secure': false,
    // 	'expires': (new Date()).getTime() + 360
    // });

    // console.log(phantom.cookies);
    phantom.exit();
});

page.onInitialized = function() {
  page.evaluate(function() {
    delete window.callPhantom;
    delete window._phantom;
  });
};
