/*  server.js

    The MIT License (MIT)

    Copyright (c) 2013-2017, Reactive Sets

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
"use strict";

/* -------------------------------------------------------------------------------------------
   Start HTTP Servers
*/
var servers = require( 'toubkal' )
  .set( [
    { id: 1, ip_address: '0.0.0.0', port: 8082 },
  ] )
  .http_servers()
;

servers.RS.Serve.max_age = 10;

require( './site' )( servers.virtual_http_servers( [ 'localhost', '127.0.0.1', '192.168.1.10', '192.168.0.22' ] ) );

module.export = servers;
