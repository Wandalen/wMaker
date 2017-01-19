( function _Maker_test_s_( ) {

'use strict';

/*

to run this test
from the project directory run

npm install
node ./staging/atop/z.test/Maker.test.s

*/

if( typeof module !== 'undefined' )
{

  require( 'wTools' );
  require ( 'wTesting' );
  require( '../maker/Maker.s' )

}

var _ = wTools;
var Parent = wTools.Testing;
var Self = {};
var fileProvider = _.FileProvider.HardDrive()
//


var simplest = function( test )
{
  var pre = function pre()
  {
    var outPath = this.env.query( 'opt/outPath' );
    logger.log( 'outPath',outPath );
    fileProvider.directoryMake( outPath );
  };

  test.description = 'simple make';

  var opt =
  {
    outPath : './staging/atop/z.test/file/out',
    outExe : './staging/atop/z.test/file/out/test1',
    src : './staging/atop/z.test/file/test1.cpp',

  };

  var target =
  [
    {
      name : 'test1',
      after : '{{opt/outExe}}',
      before : [ './file/test1.cpp' ],
      shell : `g++ {{opt/src}} -o {{opt/outExe}}`,
      pre : pre
    }
  ];

  var o =
  {
    opt : opt,
    target : target,
  };

  wMaker( o ).make();

  test.identical( 1,1 );

}



//

var Proto =
{

  name : 'Maker',

  tests :
  {

    simplest : simplest,

  },

  /* verbose : 1, */

}

//

_.mapExtend( Self,Proto );
_.Testing.register( Self );
if( typeof module !== 'undefined' && !module.parent )
_.Testing.test( Self );

} )( );
