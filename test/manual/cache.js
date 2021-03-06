rs = require( 'toubkal/lib/core' );

var shema = rs
  .set( [ { id: 'test' } ] )
  
  .trace( 'schema', { all: true } )
;

rs
  .set( [
    { id: 1 },
    { id: 2 },
    { id: 3 }
  ] )
  
  .set_flow( 'test' )
  
  .trace( 'test set', { all: true } )
  
  .database_cache( shema, { pipelet: 'optimize' } )
  
  .trace( 'database_cache', { all: true } )
  
  .filter( [
    { flow: 'test', id: 2 },
    { flow: 'none', id: 1 }
  ] )
  
  .greedy()
;
