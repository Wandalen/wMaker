
if( typeof module !== 'undefined' )
require( 'wmaker' );

let _ = wTools;

if( process.platform === 'win32' )
{
  console.log( 'The current OS can has no GNU compiler' );
  return;
}

let provider = _.fileProvider;
let data =
`
#include <iostream>

int main()
{
  std::cout << "abc" << std::endl;
  return 0;
}
`;
provider.fileWrite( _.path.join( __dirname, 'file.cpp' ), data );

let sourceFile = _.path.join( __dirname, 'file.cpp' );
let objectFile = _.path.join( __dirname, `file.o` );
let recipe =
[
  {
    name : 'compile object file',
    after : objectFile,
    before : [ sourceFile ],
    shell : `g++ -c ${ sourceFile } -o ${ objectFile }`,
  },
];

let maker = wMaker({ recipies : recipe }).form();
maker.then( () =>
{
  /* clean, comment it to show output files */
  provider.filesDelete( sourceFile );
  provider.filesDelete( objectFile );
  return null;
});
