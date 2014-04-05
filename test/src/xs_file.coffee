###
    xs_file.coffee

    Copyright (C) 2013, 2014, Connected Sets

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

###

# ----------------------------------------------------------------------------------------------
# xs test utils
# -------------

utils  = require( './xs_tests_utils.js' ) if require?

expect = this.expect || utils.expect
clone  = this.clone  || utils.clone
check  = this.check  || utils.check
xs     = this.xs     || utils.xs

if require?
  require '../../lib/filter.js'
  require '../../lib/server/file.js'

# ----------------------------------------------------------------------------------------------
# Test File pipelets
# ------------------

describe 'file', ->
  describe 'require_resolve():', ->
    modules = xs
      .set( [
        { id: 1, name: 'node-uuid/uuid.js' }
        { id: 2, name: 'not_an_existing_module' }
      ], { key: [ 'id', 'name' ] } )
    
    resolved = modules
      .require_resolve()
      .trace( 'uuid.js' )
      .set()
    
    it 'should resolve node-uuid/uuid.js', ( done ) ->
      resolved._fetch_all ( values ) -> check done, () ->
        uuid = values[ 0 ]
        
        expect( uuid.name ).to.be.eql 'node-uuid/uuid.js'
        expect( uuid.path.length ).to.be.above 10
        expect( uuid.uri ).to.be.eql '/node_modules/node-uuid/uuid.js'
    
    it 'should have only one resolved module', ( done ) ->
      resolved._fetch_all ( values ) -> check done, () ->
        expect( values.length ).to.be.eql 1
        expect( resolved._key ).to.be.eql [ 'id', 'name' ]
        
    it 'should allow to remove a module', ( done ) ->
      modules._remove [ { id: 1, name: 'node-uuid/uuid.js' } ]
      
      resolved._fetch_all ( values ) -> check done, () ->
        expect( values.length ).to.be.eql 0
  
  describe 'attribute_to_values()', ->
    source = xs.set( [
      {
        id: 1
        
        content: [
          { city: 'Paris'     }
          { city: 'Marseille' }
        ]
      }
      
      {
        id: 2
        
        content: [
          { city: 'Lille' }
          { city: 'Caen'  }
        ]
      }
    ] )
    
    cities = source
      .attribute_to_values( { key: [ 'city' ] } )
      .set()
    
    it 'should get cities', ( done ) ->
      cities._fetch_all ( values ) ->
        check done, () ->
          expect( values ).to.be.eql [
            { city: 'Paris'     }
            { city: 'Marseille' }
            { city: 'Lille'     }
            { city: 'Caen'      }
          ]
          
    it 'should allow to remove content', ( done ) ->
      source._remove [
        {
          id: 2
          
          content: [
            { city: 'Lille'     }
            { city: 'Caen'      }
          ]
        }
      ]
      
      cities._fetch_all ( values ) ->
        check done, () ->
          expect( values ).to.be.eql [
            { city: 'Paris'     }
            { city: 'Marseille' }
          ]
    
  describe 'configuration():', ->
    it 'should read a confirugation file in fixtures/config.json', ( done ) ->
      configuration = xs
      
        .configuration( {
          filepath      : '../fixtures/file/config.json'
          base_directory: __dirname
          key           : [ 'module' ]
        } )
      
      configuration._on 'complete', () ->
        configuration._fetch_all ( values ) -> check done, () ->
          expect( values ).to.be.eql [
            {
              flow: "configuration"
              module: "nodemailer"
              transport: "sendmail"
              transport_options: {}
            }
          ]
  
  describe 'watch_directories():', ->
    # ToDo: create test directories in fixtures/file/...
    directories_source = xs
      .set( [
          { path: 'directories' }
          { path: 'directories' }
          { path: 'directories' }
        ]
        { key: [ 'path' ] }
      )
      .union( [] )
    
    entries = directories_source.watch_directories( { base_directory: 'test/fixtures/file' } )
    
    directories = entries
      .filter [ { type: 'directory' } ]
      .trace( 'directories' )
    
    directories_source._add_source directories
    
    expected_directories = [
      'directories'
      'directories/css'
      'directories/html'
      'directories/lib'
      'directories/lib/client'
      'directories/lib/client/index'
      'directories/lib/server'
      'directories/lib/server/index'
    ]
    
    css = entries
      .filter( [ { type: 'file', extension: 'css' } ] )  
      .trace( 'css files' )
      .set()
      
    html = entries
      .filter( [ { type: 'file', extension: 'html' } ] )  
      .trace( 'html files' )
      .set()
      
    javascript = entries
      .filter( [ { type: 'file', extension: 'js' } ] )
      .set()
    
    get_entry_static_attributes = ( e ) ->
      { path: e.path, type: e.type, extension: e.extension, depth: e.depth }
    
    entry_sorter = ( a, b ) ->
      if a.path < b.path then -1 else a.path > b.path
    
    it 'should have many directories', ->
      expect( Object.keys( entries._directories ).sort() ).to.be.eql expected_directories
    
    it '"directories" directory should have a count of 3', ->
      expect( entries._directories[ 'directories' ].count ).to.be.eql 3
    
    it '"directories/css" directory should have a count of 1', ->
      expect( entries._directories[ 'directories/css' ].count ).to.be.eql 1
    
    it '"directories/lib/client/index" directory should have a count of 1', ->
      expect( entries._directories[ 'directories/lib/client/index' ].count ).to.be.eql 1
    
    it 'should have javascript files', ( done ) ->
      javascript._fetch_all ( values ) -> check done, () ->
        expect( values.map( get_entry_static_attributes ).sort entry_sorter ).to.be.eql [
          {
            "path": "directories/lib/client/index/start.js"
            "type": "file"
            "extension": "js"
            "depth": 4
          }
          
          {
            "path": "directories/lib/server/index/models.js"
            "type": "file"
            "extension": "js"
            "depth": 4
          }
        ]
    
    it 'should have css files', ( done ) ->
      css._fetch_all ( values ) -> check done, () ->
        expect( values.map( get_entry_static_attributes ).sort entry_sorter ).to.be.eql [
          {
            "path": "directories/css/index.css"
            "type": "file"
            "extension": "css"
            "depth": 2
          }
        ]
    
    it 'should have an html file', ( done ) ->
      html._fetch_all ( values ) -> check done, () ->
        expect( values.map( get_entry_static_attributes ).sort entry_sorter ).to.be.eql [
          {
            "path": "directories/html/index.html"
            "type": "file"
            "extension": "html"
            "depth": 2
          }
        ]
    
    it 'should have 11 entries', ( done ) ->
      entries._fetch_all ( values ) -> check done, () ->
        expect( values.length ).to.be 11
    
    it 'should many directories at depths 1, and 2', ( done ) ->
      directories._fetch_all ( values ) -> check done, () ->
        expect( values.map( get_entry_static_attributes ).sort entry_sorter ).to.be.eql [
          {
            "path": "directories/css"
            "type": "directory"
            "extension": ""
            "depth": 1
          }
          
          {
            "path": "directories/html"
            "type": "directory"
            "extension": ""
            "depth": 1
          }
          
          {
            path: 'directories/lib'
            type: 'directory'
            extension: ''
            depth: 1
          }
          
          {
            path: 'directories/lib/client'
            type: 'directory'
            extension: ''
            depth: 2
          }
          
          {
            path: 'directories/lib/client/index'
            type: 'directory'
            extension: ''
            depth: 3
          }
          
          {
            "path": "directories/lib/server"
            "type": "directory"
            "extension": ""
            "depth": 2
          }
          
          {
            "path": "directories/lib/server/index"
            "type": "directory"
            "extension": ""
            "depth": 3
          }
        ]
    
    it 'should not remove "directories" directory after removing 2 extra path from directories_source', ->
      entries._remove [
          { path: 'directories' }
          { path: 'directories' }
        ]
      
      expect( entries._directories[ 'directories' ].count ).to.be.eql 1
    
    it 'should still have many directories', ->
      expect( Object.keys( entries._directories ).sort() ).to.be.eql expected_directories
    
    it 'should remove both directories after removing the "directories" directory', ->
      entries._remove [ { path: 'directories' } ]
      
      expect( Object.keys( entries._directories ) ).to.be.eql []
    
    it 'should have no directory left', ( done ) ->
      directories._fetch_all ( values ) -> check done, () -> expect( values ).to.be.eql []
    
    it 'should have no css files left', ( done ) ->
      css._fetch_all ( values ) -> check done, () -> expect( values ).to.be.eql []
    
    it 'should have no html files left', ( done ) ->
      html._fetch_all ( values ) -> check done, () -> expect( values ).to.be.eql []
    
    it 'should have no javascript files left', ( done ) ->
      javascript._fetch_all ( values ) -> check done, () -> expect( values ).to.be.eql []
    
    it 'should have no entries left', ( done ) ->
      entries._fetch_all ( values ) -> check done, () -> expect( values ).to.be.eql []
    
    it 'should not throw after attempting to remove extra directory', ->
      entries._remove [ { path: 'directories' } ]
      
      expect( Object.keys( entries._directories ) ).to.be.eql []

