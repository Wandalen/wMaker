
if( typeof module !== 'undefined' )
require( 'wmaker' );

var target =
[
  {
    name : 't1',
    after : 'my_file.o',
    before : 'my_file.cpp',
    shell : `g++ -c my_file.cpp -o my_file.o`
  },
  {
    name : 't2',
    after : 'my_file', /*on windows: my_file.exe*/
    before : 'my_file.o',
    shell : `g++ my_file.o -o my_file`
  }
]

if( module.isBrowser )
wMaker({ recipies : target }).form();
else
wMaker({ recipies : target }).exec();
