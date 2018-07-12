# wMaker [![Build Status](https://travis-ci.org/Wandalen/wMaker.svg?branch=master)](https://travis-ci.org/Wandalen/wMaker)

Analog of so-called 'make' in Java Script.

## Installation
```terminal
npm install wmaker
```

## Usage
### Options
|  Name 	|Type| Optional  	| Description  	|
|---	|---	|---  |---  |
|opt |object|*|Structure for storing user defined variables.
|recipe|array|-|Array which stores make recipes.
|defaultTargetName|string|*|Make will run this target by default, useful with multiple recipes, if not specified first target in the structure will be default.
|usingLogging|bool|*|Enable logging of making process, enabled by default.
|currentPath|string|*| Current working directory, by default is the folder where make script is located.

<!-- #### Opt Description will be here-->

#### Target
|  Property 	| Type  	| Description  	|
|---	|---	|---  |
|name |string|Target name.
|shell|string|Commands to execute in comand prompt.
|after|array/string|Files for validation and "up-to-date" check with files from 'before'. Validation - check whether all files from this list exists. "Up-to-date" means that any file from 'after' property is newer then other any file from 'before' or they have same date.
|before|array/string|Dependencies( files/targets ) that must checked for "up-to-date" before recipe execution.If recipe is "up-to-date" it will not be executed.
|pre|function|Function called at the beginning of recipe execution.
|post|function|Function called at the ending of recipe execution.

### Methods
|  Name 	| Description  	|
|---	|---	|
|form|Runs default target using name specified as 'defaultTargetName'.
|exec|Runs default target using name specified as 'defaultTargetName' or as command line argument.
|makeTarget|Runs target using name passed as argument.

##### Example #1
```javascript
/*simplest make target example using g++*/
var target =
{
  after : 'my_file.o',
  before : 'my_file.cpp',
  shell : `g++ -c my_file.cpp -o my_file.o`
}
wMaker({ recipe : [ target ] }).form();
```
##### Example #2
```javascript
/*example of using pre function in target*/
var _ = wTools;
var pre = function()
{ /*some useful code here for example creating *.cpp file */
  var code = 'int  main() { return 0; }';
  fileProvider = _.FileProvider.HardDrive();
  fileProvider.fileWriteAct
  ({
      filePath : 'my_file.cpp',
      data : code,
      sync : 1,
  });
}

var target =
{
  pre : pre,
  after : 'my_file.o',
  before : 'my_file.cpp',
  shell : `g++ -c my_file.cpp -o my_file.o`
}
wMaker({ recipe : [ target ] }).form();
```
##### Example #3
```javascript
/*run specific target using makeTarget*/
var target =
{
  name : 't1',
  after : 'my_file.o',
  before : 'my_file.cpp',
  shell : `g++ -c my_file.cpp -o my_file.o`
}
var maker = wMaker
({
  recipe : [ target ],
  defaultTargetName : '' /*disable default target execution by form()*/
});
maker.form(); /*run form to process provided target info*/
maker.makeTarget( 't1' ); /*run recipe t1*/
```
##### Example #4
```javascript
/*run specific target using command line*/
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
wMaker({ recipe : target }).exec();
```
```terminal
node my_make_file.js t1
```


















