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

var pre = function pre()
{
  var outPath = this.env.query( 'opt/outPath' );
  logger.log( 'outPath',outPath );
  fileProvider.directoryMake( outPath );
};

//

var createMaker = function( opt, target )
{
  var maker = wMaker({ opt : opt, target : target });
  maker.currentPath = _.pathMainDir();
  maker.fileProvider = fileProvider;
  maker.env = wTemplateTree({ tree : { opt : maker.opt, target : maker.target } });
  maker.targetsAdjust();
  return maker;
}

//

var simplest = function( test )
{
  test.description = 'simple make';

  var opt =
  {
    outPath : '../../../file/out',
    outExe : '../../../file/out/test1',
    src : '../../../file/test1.cpp',

  };

  var target =
  [
    {
      name : 'test1',
      after : '{{opt/outExe}}',
      before : [ '{{opt/src}}' ],
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

var targetInvestigateUpToDate = function( test )
{
  var target =
  [
    {
      name : 'test1',
      after : './file/test1.cpp',
      before : [ './file/test1.cpp' ],
    }
  ];

  test.description = "compare two indentical files"
  var maker = createMaker( {}, target );
  var t = maker.env.tree.target[ target[ 0 ].name ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, true );

  test.description = "compare src with output"
  var target =
  [
    {
      name : 'test1',
      after : './file/out/test1.o',
      before : [ './file/test1.cpp' ],
    }
  ];
  var maker = createMaker( {}, target );
  var t = maker.env.tree.target[ target[ 0 ].name ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, false );
}

var Proto =
{

  name : 'Maker',

  tests :
  {

    simplest : simplest,
    // targetInvestigateUpToDate : targetInvestigateUpToDate

  },

  /* verbose : 1, */

}

//

_.mapExtend( Self,Proto );
_.Testing.register( Self );
if( typeof module !== 'undefined' && !module.parent )
_.Testing.test( Self );

} )( );
