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

var exe = process.platform === `win32` ? `.exe` : ``;

var simplest = function( test )
{
  var opt =
  {
    basePath: _.pathJoin( _.pathMainDir(),'../../../file' ),
    outPath : `{{opt/basePath}}/out`,
    outExe : `{{opt/outPath}}/test1${exe}`,
    src : `{{opt/basePath}}/test1.cpp`,

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

  var con = new wConsequence().give();

  con.ifNoErrorThen(function()
  {
    test.description = 'simple make';
    var con = wMaker( o ).make();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen(function()
  {
    var got = fileProvider.fileStatAct( _.pathJoin( opt.basePath,`out/test1${exe}` ) ) != undefined;
    test.identical( got,true );
  })
  .ifNoErrorThen(function()
  {
    test.description = "try to make obj file ";

    var target =
    [
      {
        name : 'test4',
        after : `{{opt/basePath}}/out/test2.o`,
        before : [ `{{opt/basePath}}/test2.cpp` ],
        shell : `g++ -c {{opt/basePath}}/test2.cpp -o {{opt/basePath}}/out/test2.o`,
      }
    ];

    var o =
    {
      opt : opt,
      target : target,
    };

    var con = wMaker( o ).make();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen(function()
  {
    var got = fileProvider.fileStatAct( _.pathJoin( opt.basePath,`out/test2.o` ) ) != undefined;
    test.identical( got,true );
  });

  return con;
}

//

var targetInvestigateUpToDate = function( test )
{
  var opt =
  {
    basePath: _.pathJoin( _.pathMainDir(),'../../../file' ),
  };

  var target =
  [
    {
      name : 'test2',
      after : `{{opt/basePath}}`,
      before : [ `{{opt/basePath}}` ],
    }
  ];

  test.description = "compare two indentical files";
  var maker = createMaker( opt, target );
  var t = maker.env.tree.target[ 'test2' ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, true );

  test.description = "compare src with output";
  var target =
  [
    {
      name : 'test3',
      after : `{{opt/basePath}}/1.o`,
      before : [ `{{opt/basePath}}` ],
    }
  ];
  var maker = createMaker( opt, target );
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
    targetInvestigateUpToDate : targetInvestigateUpToDate

  },

  /* verbose : 1, */

}

//

_.mapExtend( Self,Proto );
_.Testing.register( Self );
if( typeof module !== 'undefined' && !module.parent )
_.Testing.test( Self );

} )( );
