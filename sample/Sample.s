
if( typeof module !== 'undefined' )
require( 'wmaker' );

let _ = wTools;

/* */

let sourceFile = _.path.join( __dirname, 'my_file.cpp' );
let objectFile = _.path.join( __dirname, 'my_file.o' );
let exeFile = _.path.join( __dirname, 'my_file' );

let sourceFileData =
`int  main(int argc, char const *argv[]) {
  /* code */
  return 0;
}`;
_.fileProvider.fileWrite( sourceFile, sourceFileData );

var target =
[
  {
    name : 't1',
    after : objectFile,
    before : sourceFile,
    shell : `g++ -c ${ sourceFile } -o ${ objectFile }`
  },
  {
    name : 't2',
    after : exeFile, /*on windows: my_file.exe*/
    before : objectFile,
    shell : `g++ ${ objectFile } -o ${ exeFile }`
  }
]

let maker;
if( module.isBrowser )
maker = wMaker({ recipies : target }).form();
else
maker = wMaker({ recipies : target }).exec();

maker.then( () =>
{
  _.fileProvider.filesDelete( sourceFile );
  _.fileProvider.filesDelete( objectFile );
  _.fileProvider.filesDelete( exeFile );
  return null;
});
