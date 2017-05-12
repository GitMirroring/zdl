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

var net = require('net');

var port = process.argv[2];

var portInUse = function(port, callback) {
    var server = net.createServer(function(socket) {
	socket.write('Echo server\r\n');
	socket.pipe(socket);
    });

    server.listen(port, '127.0.0.1');
    server.on('error', function (e) {
	callback(true);
    });
    server.on('listening', function (e) {
	server.close();
	callback(false);
    });
};

portInUse(port, function(returnValue) {
    process.exit(1 - returnValue);
});
