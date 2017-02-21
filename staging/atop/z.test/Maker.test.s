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

var exe = process.platform === `win32` ? `.exe` : ``;
var basePath = _.pathJoin( _.pathMainDir(),'../../../file' );

var simplest = function( test )
{
  var opt =
  {
    basePath: basePath,
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

var recipeRunCheck = function( test )
{
  var file1 = _.pathJoin( basePath, 'file1');
  var file2 = _.pathJoin( basePath, 'file2');

  var called = false;
  var pre = function(){ called = true; }

  fileProvider.fileWriteAct
  ({
      pathFile : file1,
      data : 'abc',
      sync : 1,
  });
  var con = _.timeOut( 1000 );
  con.doThen( function( )
  {
    fileProvider.fileWriteAct
    ({
       pathFile : file2,
       data : 'bca',
       sync : 1,
    });
  })
  .ifNoErrorThen( function()
  {
    test.description = 'after is older then before';
    var target =
    [
      {
        name : 'a1',
        after : `${file1}`,
        before : [ `${file2}` ],
        pre : pre
      }
    ];
    var con = wMaker({ target : target }).make();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen( function()
  {
    //if no error recipe is done
    test.identical( called , true );
  })
  .ifNoErrorThen( function()
  {
    called = false;
    var target =
    [
      {
        name : 'a2',
        after : `${file2}`,
        before : [ `${file1}` ],
        pre : pre
      }
    ];
    test.description = 'after is newer then before';
    var con = wMaker({ target : target }).make();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen( function()
  {
    test.identical( called, false );
  })
  .ifNoErrorThen( function()
  {
    var target =
    [
      {
        name : 'a3',
        after : `${file1}`,
        before : [ `${file1}` ],
        pre : pre
      }
    ];
    test.description = 'after == newer';
    var con = wMaker({ target : target }).make();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen( function()
  {
    test.identical( called, false );
  });

  return con;
}

//

var targetsAdjust = function( test )
{
  test.description = "check targets dependencies";
  var target =
  [
    {
      name : 'first',
      after : `a1`,
      before : [ 'a.cpp' ],
    },
    {
      name : 'second',
      after : [ 'a2' ],
      before : [ 'first','a2.cpp' ],
    }
  ];

  var maker = wMaker({ target : target, defaultTargetName : '' });
  maker.make();
  target = maker.env.tree.target;
  var got = [ target.first.beforeNodes, target.second.beforeNodes ];
  var expected =
  [
    { 'a.cpp' : { kind : 'file', filePath : 'a.cpp' } },
    {
      'first' :
      {
        kind : 'recipe',
        name : 'first',
        before : [ 'a.cpp' ],
        after : [ 'a1' ],
        beforeNodes : { 'a.cpp' : { kind : 'file', filePath : 'a.cpp' } }
      },
      'a2.cpp' : { kind : 'file', filePath : 'a2.cpp' }
    }
  ];

  test.identical( got, expected );

}

//

var targetInvestigateUpToDate = function( test )
{
  var opt =
  {
    basePath: basePath,
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
  var maker = wMaker({ opt : opt, target : target, defaultTargetName : '' });
  maker.make();
  var t = maker.env.tree.target[ target[ 0 ].name ];
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
  var maker = wMaker({ opt : opt, target : target, defaultTargetName : '' });
  maker.make();
  var t = maker.env.tree.target[ target[ 0 ].name ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, false );
}

//

var pathesFor = function( test )
{
  test.description = "check if relative pathes are generated correctly";
  var maker = wMaker({ target : {}, defaultTargetName : '' });
  maker.make();
  var got = maker.pathesFor( [ '../../../file', '../../../file/test1.cpp', '../../../test2.cpp' ] );
  var expected =
  [
    _.pathJoin( _.pathMainDir(), '../../../file' ),
    _.pathJoin( _.pathMainDir(), '../../../file/test1.cpp' ),
    _.pathJoin( _.pathMainDir(), '../../../test2.cpp' ),
  ];

  test.identical( got, expected );
}


var Proto =
{

  name : 'Maker',

  tests :
  {

    simplest : simplest,
    recipeRunCheck : recipeRunCheck,
    targetsAdjust : targetsAdjust,
    targetInvestigateUpToDate : targetInvestigateUpToDate,

    //etc
    pathesFor : pathesFor,

  },

  /* verbose : 1, */

}

//

_.mapExtend( Self,Proto );
_.Testing.register( Self );
if( typeof module !== 'undefined' && !module.parent )
_.Testing.test( Self );

} )( );
