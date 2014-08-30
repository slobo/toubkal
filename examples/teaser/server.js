"use strict";

var xs      = require( '../../' )
  , XS      = xs.XS
  , extend  = XS.extend
;

require( '../../lib/filter.js' );
require( '../../lib/server/http.js' );
require( '../../lib/server/socket_io_clients.js' );
require( '../../lib/server/file.js' );
require( '../../lib/server/uglify.js' );
require( '../../lib/order.js' );

var servers = xs
  .set( [ // Define http servers
    { port: '8080', ip_address: '127.0.0.1' } // this application has only one server
  ] )
  
  .http_servers() // start http servers
;

var xs_dependencies = xs
  .set( [ { name: 'node-uuid/uuid.js' } ] )
  
  .require_resolve()
;

// Merge and mimify client javascript assets in realtime
var all_min_js = xs.union( [ xs_dependencies, xs
  .set( [ // Define the minimum set of javascript files required to serve this client application
    { path: '../../lib/xs.js'                  },
    { path: '../../lib/code.js'                },
    { path: '../../lib/query.js'               },
    { path: '../../lib/transactions.js'        },
    { path: '../../lib/pipelet.js'             },
    { path: '../../lib/filter.js'              },
    { path: '../../lib/join.js'                },
    { path: '../../lib/aggregate.js'           },
    { path: '../../lib/order.js'               },
    { path: '../../lib/selector.js'            },
    { path: '../../lib/table.js'               },
    { path: '../../lib/socket_io_crossover.js' },
    { path: '../../lib/socket_io_server.js'    },
    { path: 'client.js'                        }
  ] ) ] )
  
  .auto_increment() // Keeps track of files load order by adding an id attribute starting at 1
  
  .watch()                      // Retrieves files content with realtime updates
  
  .order( [ { id: 'id' } ] )    // Order files by auto_increment order before minifying
  
  .uglify( 'all-min.js', { warnings: false } )       // Minify in realtime using uglify-js and provide "all-min.map" source map
;

// Listen when all-min.js is ready
servers.http_listen( all_min_js );

// Other static assets
xs.set( [ { path: 'index.html' } ] )
  
  .watch()                 // Retrieves file content with realtime updates
  
  .union( [ all_min_js ] ) // Add minified assets
  
  .serve( servers ) // Deliver up-to-date compiled and mimified assets to clients
;

// Start socket servers on all http servers using socket.io
var clients = servers.socket_io_clients(); // Provide a dataflow of socket.io client connections

var sales = xs
  .configuration( { filepath: 'sales.json', flow: 'sales' } ) // The sales dataflow 
  
  .alter( function( sale ) {
    sale.year = parseInt( sale.date.substr( 0, 4 ), 10 );
  } )
;

sales
  .dispatch( clients, client )  // Serve 64k simultaneous user connexions over one core
;

function client ( source ) {
  
  var socket = this.socket;     // Socket to exchange data with web browser

  source                        // Dataflows from the database through dispatch()
    ._add_destination( socket ) // Send data to web browser
  ;

  return socket;
}
