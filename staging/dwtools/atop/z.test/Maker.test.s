( function _Maker_test_s_( ) {

'use strict';

/*

to run this test
from the project directory run

npm install
node ./staging/dwtools/atop/z.test/Maker.test.s

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
var fileProvider = _.FileProvider.HardDrive();

var files =
{
  'test1.cpp' :
  `int  main(int argc, char const *argv[]) {
    /* code */
    return 0;
  }`,

  'test2.cpp' :
  `#include <iostream>

  int  main(int argc, char const *argv[])
  {
    std::cout << "abc";
    return 0;
  }`
}

var basePath;

function makeTestDir()
{
  basePath = _.dirTempFor
  ({
    packageName : Self.name,
    packagePath : _.pathResolve( _.pathRealMainDir(), '../../tmp.tmp' )
  });

  basePath = _.fileProvider.pathNativize( basePath );

  if( _.fileProvider.fileStat( basePath ) )
  _.fileProvider.fileDelete( basePath );

  _.fileProvider.directoryMake( basePath );

  _.mapOwnKeys( files )
  .forEach( ( name ) =>
  {
    var path = _.pathJoin( basePath, name );
    _.fileProvider.fileWrite( path, files[ name ] );
  });
}

function cleanTestDir()
{
  _.fileProvider.fileDelete( basePath );
}

//

var pre = function pre()
{
  var outPath = this.env.query( 'opt/outPath' );
  logger.log( 'outPath',outPath );
  fileProvider.directoryMake( outPath );
};

//

var exe = process.platform === `win32` ? `.exe` : ``;



var simplest = function( test )
{
  var opt =
  {
    basePath: basePath,
    outPath : `{{opt/basePath}}/out`,
    outExe : `{{opt/outPath}}/test1${exe}`,
    src : `{{opt/basePath}}/test1.cpp`,

  };

  var recipe =
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
    recipe : recipe,
  };

  var con = new wConsequence().give();

  con.ifNoErrorThen(function()
  {
    test.description = 'simple make';
    debugger
    var con = wMaker( o ).form();
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

    var recipe =
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
      recipe : recipe,
    };

    var con = wMaker( o ).form();
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
      filePath : file1,
      data : 'abc',
      sync : 1,
  });
  var con = _.timeOut( 1000 );
  con.doThen( function( )
  {
    fileProvider.fileWriteAct
    ({
       filePath : file2,
       data : 'bca',
       sync : 1,
    });
  })
  .ifNoErrorThen( function()
  {
    test.description = 'after is older then before';
    var recipe =
    [
      {
        name : 'a1',
        after : `${file1}`,
        before : [ `${file2}` ],
        pre : pre
      }
    ];
    var con = wMaker({ recipe : recipe }).form();
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
    var recipe =
    [
      {
        name : 'a2',
        after : `${file2}`,
        before : [ `${file1}` ],
        pre : pre
      }
    ];
    test.description = 'after is newer then before';
    var con = wMaker({ recipe : recipe }).form();
    return test.shouldMessageOnlyOnce( con );
  })
  .ifNoErrorThen( function()
  {
    test.identical( called, false );
  })
  .ifNoErrorThen( function()
  {
    var recipe =
    [
      {
        name : 'a3',
        after : `${file1}`,
        before : [ `${file1}` ],
        pre : pre
      }
    ];
    test.description = 'after == newer';
    var con = wMaker({ recipe : recipe }).form();
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
  var recipe =
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

  var maker = wMaker({ recipe : recipe, defaultTargetName : '' });
  maker.form();
  recipe = maker.env.tree.recipe;
  var got = [ recipe.first.beforeNodes, recipe.second.beforeNodes ];
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

  var recipe =
  [
    {
      name : 'test2',
      after : `{{opt/basePath}}`,
      before : [ `{{opt/basePath}}` ],
    }
  ];

  test.description = "compare two indentical files";
  var maker = wMaker({ opt : opt, recipe : recipe, defaultTargetName : '' });
  maker.form();
  var t = maker.env.tree.recipe[ recipe[ 0 ].name ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, true );

  test.description = "compare src with output";
  var recipe =
  [
    {
      name : 'test3',
      after : `{{opt/basePath}}/1.o`,
      before : [ `{{opt/basePath}}` ],
    }
  ];
  var maker = wMaker({ opt : opt, recipe : recipe, defaultTargetName : '' });
  maker.form();
  var t = maker.env.tree.recipe[ recipe[ 0 ].name ];
  var got = maker.targetInvestigateUpToDate( t );
  test.identical( got, false );
}

//

var pathesFor = function( test )
{
  test.description = "check if relative pathes are generated correctly";
  var maker = wMaker({ recipe : {}, defaultTargetName : '' });
  maker.form();
  var got = maker.pathesFor( [ '../../../file', '../../../file/test1.cpp', '../../../test2.cpp' ] );
  var currentDir = _.pathRealMainDir();
  var expected =
  [
    _.pathResolve( currentDir, '../../../file' ),
    _.pathResolve( currentDir, '../../../file/test1.cpp' ),
    _.pathResolve( currentDir, '../../../test2.cpp' ),
  ];

  test.identical( got, expected );
}


var Proto =
{

  name : 'Maker',
  silencing : 1,

  onSuiteBegin : makeTestDir,
  onSuiteEnd : cleanTestDir,

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
Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );
} )( );
