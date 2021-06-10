( function _Recipe_s_( )
{

'use strict';

//

const _ = _global_.wTools;
const Parent = null;
const Self = wRecipe;
function wRecipe( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.shortName = 'Recipe';

// --
//
// --

function preform()
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( !recipe._formed );
  _.assert( !recipe._preformed );

  if( !recipe.env )
  recipe.env = wTemplateTreeResolver({ tree : { opt : maker.opt, recipe, recipies : maker.recipies } });

  recipe._preformed = 1;
}

//

function form()
{
  var recipe = this;
  var maker = recipe.maker;

  // if( !recipe.env )
  // recipe.env = wTemplateTreeResolver({ tree : { opt : maker.opt, recipe, recipies : maker.recipies } });

  if( !recipe._preformed )
  recipe.preform();

  /* verification */

  _.assert( !!maker, 'Expects { maker }' );
  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( !recipe._formed );
  // _.assert( recipe._preformed );

  // if( !recipe.name )
  // recipe.name = maker.recipeNameGet( recipe );

  // _.assert( recipe.name === maker.recipeNameGet( recipe ) );

  // var but = _.props.keys( _.mapBut_( null, recipe,maker.RecipeFields[ 'recipe' ] ) );
  // if( but.length )
  // throw _.err( 'Recipe', recipe.name, 'should not have fields', but );

  if( !_.strDefined( recipe.name ) )
  throw _.err( 'Recipe', 'Expects string { name }' );

  if( recipe.shell && !_.strIs( recipe.shell ) )
  throw _.err( 'Recipe', recipe.name, 'Expects string { shell }' );

  if( recipe.head && !_.routineIs( recipe.head ) )
  throw _.err( 'Recipe', recipe.name, 'Expects routine { head }' );

  if( recipe.post && !_.routineIs( recipe.post ) )
  throw _.err( 'Recipe', recipe.name, 'Expects routine { post }' );

  if( recipe.after && !_.arrayIs( recipe.after ) && !_.strIs( recipe.after ) )
  throw _.err( 'Recipe', recipe.name, 'Expects string or array { recipe }' );

  if( recipe.kind === 'recipe' )
  if( !_.arrayIs( recipe.before ) && !_.strIs( recipe.before ) )
  throw _.err( 'Recipe', recipe.name, 'Expects array or string { before }' );

  if( !_.longHas( recipe.Kind, recipe.kind ) )
  throw _.err( 'Recipe', recipe.name, 'should have known { kind }, but have', recipe.kind );

  /* */

  if( !recipe.env )
  recipe.env = wTemplateTreeResolver({ tree : { opt : maker.opt, recipe, recipies : maker.recipies } });

  if( recipe.kind === 'recipe' )
  {

    if( recipe.beforeDirs )
    recipe.beforeDirs = _.array.as( recipe.beforeDirs );
    else
    recipe.beforeDirs = [];
    // if( !recipe.beforeDirs )
    // recipe.beforeDirs = [];
    // else
    // recipe.beforeDirs = _.array.as( recipe.beforeDirs );

    recipe.after = _.array.as( recipe.after );
    recipe.before = _.array.as( _.arrayFlatten( [], recipe.before ) );
    recipe.beforeNodes = Object.create( null );
    recipe.afterNodes = Object.create( null );

    for( var d = 0 ; d < recipe.before.length ; d++ )
    {
      var before = recipe.before[ d ];

      if( recipe.beforeNodes[ before ] )
      throw _.err( 'Taget', recipe.name, 'already has dependency', before );

      // recipe.beforeNodes[ before ] = recipe.subFrom( before );
      recipe.subFrom( before, recipe.beforeNodes );
    }

    /* validation */

    _.assert( _.array.is( recipe.after ) );
    _.assert( _.array.is( recipe.before ) );

  }

  _.assert( !!recipe.env );

  recipe._formed = 1;

  return recipe;
}

//

function hasAfter( after )
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.str.is( after ) );
  _.assert( !!recipe.env );

  for( var a = 0 ; a < recipe.after.length ; a++ )
  {
    if( recipe.after[ a ] === '' )
    continue;

    var rafter = recipe.env.resolve( recipe.after[ a ] )

    _.assert( _.strIs( rafter ) );

    if( after === rafter )
    return true;
  }

  return false;
}

//

function subFrom( name, nodes )
{
  var recipe = this;
  var maker = recipe.maker;
  var result;

  // var name = recipe.before[ d ];
  // var result = map[ name ];
  // if( result )
  // throw _.err( 'Taget', recipe.name, 'already has dependency',name );

  // if( _.arrayIs( name ) )
  // name = name.join( ';' );

  _.assert( _.strDefined( name ), 'Expects string { name }' )
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  var before = recipe.env.resolve( name );

  result = maker.recipyWithBefore( before );

  if( !result.length )
  {
    result =
    [
      new recipe.Self
      ({
        kind : 'file',
        name,
        _filePath : name,
        _dirs : recipe.beforeDirs,
        opt : recipe.opt,
        maker,
      }).form()
    ];
  }

  _.assert( result.length > 0 );

  for( var r = 0 ; r < result.length ; r++ )
  {
    var node = result[ r ];
    _.assert( !nodes[ node.name ], 'already has node', node.name );
    nodes[ node.name ] = node;
  }

  // if( maker.recipies[ name ] )
  // subRecipe = maker.recipies[ name ];
  // else
  // subRecipe = new recipe.Self
  // ({
  //   kind : 'file',
  //   name : name,
  //   _filePath : name,
  //   _dirs : recipe.beforeDirs,
  //   opt : recipe.opt,
  //   maker : maker,
  // }).form();

  // else
  // subRecipe = recipe.Self
  // ({
  //   kind : 'file',
  //   name : name,
  //   _filePath : name,
  //   _dirs : recipe.beforeDirs,
  //   env : recipe.env,
  //   maker : maker,
  // }).form();

  // recipe.beforeNodes[ name ] = { kind : 'file', filePath : name, dirs : recipe.beforeDirs };

  // _.assert( subRecipe instanceof Self );
  // _.assert( subRecipe.kind );

  // return subRecipe;
}

//

function isDone()
{
  var recipe = this;
  var maker = recipe.maker;
  var result = Object.create( null );
  result.ok = 0;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  var paths = recipe.pathsFor( recipe.after );
  for( var a = 0 ; a < recipe.after.length ; a++ )
  {
    if( !maker.fileProvider.statResolvedRead( paths[ a ] ) )
    {
      result.missing = paths[ a ];
      return result;
    }
  }

  result.ok = 1;
  return result;
}

//

function investigateUpToDate()
{
  var recipe = this;
  _.assert( arguments.length === 0, 'Expects no arguments' );
  return recipe._investigateUpToDate( null );
}

//

function _investigateUpToDate( parent )
{
  var recipe = this;
  var result = true;

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( recipe.kind === 'recipe' )
  result = recipe.investigateUpToDateRecipe() && result;
  else if( recipe.kind === 'file' )
  result = recipe.investigateUpToDateFile( parent ) && result;
  else _.assert( 0, 'unknown recipe kind', recipe.kind );

  recipe.upToDate = result;

  return result;
}

//

function investigateUpToDateRecipe()
{
  var recipe = this;
  var result = true;

  _.assert( recipe.kind === 'recipe' );

  if( !Object.keys( recipe.beforeNodes ).length )
  result = false;

  for( var d in recipe.beforeNodes )
  {
    var node = recipe.beforeNodes[ d ];
    result = node._investigateUpToDate( recipe ) && result;
  }

  recipe.upToDate = result;

  return result;
}

//

function investigateUpToDateFile( file )
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( !!recipe );
  _.assert( arguments.length === 1, 'Expects single argument' );

  if( file.upToDate !== undefined )
  {
    var result0 = file.upToDate;
    return result0;
  }

  var dst = recipe.pathsFor( recipe.after );
  var src = recipe.pathsFor( file._filePath );

  var result = maker.fileProvider.filesAreUpToDate2({ dst, src });

  if( maker.verbosity > 1 )
  logger.log( 'investigateUpToDateFile(', recipe.after.join( ', ' ), ') :', result );

  return result;
}

//

function makeTarget()
{
  var recipe = this;
  var maker = recipe.maker;
  var con = new _.Consequence();

  _.assert( arguments.length === 0, 'Expects no arguments' );

  if( recipe.investigateUpToDate() )
  {
    logger.log( 'Recipe', recipe.name, 'is up to date' );
    return con.take( null );
  }

  return recipe._makeTarget();
}

//

function _makeTarget()
{
  var recipe = this;
  var maker = recipe.maker;
  var con = new _.Consequence().take( null );

  _.assert( arguments.length === 0, 'Expects no arguments' );

  // if( _.strIs( recipe ) )
  // recipe = maker.recipies[ recipe ];

  if( maker.verbosity )
  logger.logUp( 'making recipe', recipe.env.resolve( recipe.name ) );

  if( recipe.upToDate )
  {
    logger.logDown( '' );
    return con;
  }

  /* head */

  if( recipe.head )
  con.ifNoErrorThen( function( arg/*aaa*/ )
  {
    return recipe.head.call( maker, recipe );
  });

  /* dependencies */

  recipe._makeTargetDependencies( con );

  /* shell */

  if( recipe.shell )
  con.ifNoErrorThen( function( arg/*aaa*/ )
  {
    if( recipe.shell )
    return _.process.start
    ({
      execPath : recipe.env.resolve( recipe.shell ),
      throwingExitCode : 1,
      applyingExitCode : 1,
      // outputGray : 0,
      outputGraying : 0,
      outputPrefixing : 1,
      stdio : 'inherit',
    });
    return null;
  });

  /* post */

  if( recipe.post )
  con.ifNoErrorThen( function( arg/*aaa*/ )
  {
    throw _.err( 'not tested' );
    return recipe.post();
  });

  /* validation */

  con.ifNoErrorThen( function( arg/*aaa*/ )
  {
    var done = recipe.isDone();

    if( !done.ok )
    throw _.errBrief( 'Recipe "' + recipe.name +'" failed to produce "' + done.missing + '"' );

    return null;
  });

  /* end */

  con.finally( function( err, data )
  {

    if( maker.verbosity )
    logger.log( 'done recipe', recipe.env.resolve( recipe.name ) );

    if( err )
    {
      _.process.exitCode( -1 );
      err = _.errLogOnce( err );
    }

    if( maker.verbosity )
    logger.logDown( '' );

    if( err )
    throw err;

    return null;
  });

  return con;
}

//

function _makeTargetDependencies( con )
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 1, 'Expects single argument' );

  /* */

  for( var d in recipe.beforeNodes )
  {
    var node = recipe.beforeNodes[ d ];

    // logger.log( 'node.kind',node.kind );

    if( node.kind === 'recipe' )
    {
      con.ifNoErrorThen( _.routineSeal( node, node._makeTarget ) );
    }
    else if( node.kind === 'file' )
    {
      node.filesMissedWithError();
    }
    else throw _.err( 'unknown recipe kind', recipe.kind );

  }

  return con;
}

//

function filesMissed()
{
  var recipe = this;
  var maker = recipe.maker;
  var dirs = recipe._dirs && recipe._dirs.length ? recipe._dirs : [ '.' ];
  var path = recipe._filePath;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  var notMade = [];
  // var paths = recipe.pathsFor( path );

  for( var d = 0 ; d < dirs.length ; d++ )
  {

    // var paths = maker.pathsFor( _.path.join( dirs[ d ],path ) );
    // var paths = maker.pathsFor( path );
    // paths = _.path.s.join( dirs[ d ],paths );

    var paths = recipe._pathsFor( path, dirs[ d ] );

    if( _.strIs( paths ) )
    paths = [ paths ];

    _.assert( _.arrayIs( paths ) );
    _.assert( paths.length >= 1, 'not tested' );

    var f;
    for( f = 0 ; f < paths.length ; f++ )
    if( !maker.fileProvider.statResolvedRead( paths[ f ] ) )
    {
      notMade.push( paths[ f ] );
      break;
    }

    if( f === paths.length )
    return [];

  }

  return notMade;
}

//

function filesMissedWithError()
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  var notMade = recipe.filesMissed();

  if( notMade.length === 0 )
  return notMade;

  var notMadeStr = notMade.join( '\n' );
  throw _.err( 'not made recipe', recipe._filePath, '\nmissed files :\n', notMadeStr );

  return false;
}

//

function pathsFor( paths )
{
  var recipe = this;
  var maker = recipe.maker;

  // var result = [];
  // var dirs = ( recipe._dirs && recipe._dirs.length ) ? recipe._dirs : [ '.' ];

  _.assert( arguments.length === 1, 'Expects single argument' );

  /* */

  // for( var d = 0 ; d < dirs.length ; d++ )
  // {
  //   var paths = recipe._pathsFor( paths,dirs[ d ] );
  //   if( dirs.length > 1 )
  //   result.push( paths );
  //   else
  //   result = paths;
  // }

  var result = recipe._pathsFor( paths, '.' );

  return result;
}

//

function _pathsFor( paths, dir )
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.arrayIs( paths ) || _.strIs( paths ) );

  /* */

  if( _.arrayIs( paths ) )
  {
    var result0 = [];
    for( var p = 0 ; p < paths.length ; p++ )
    result0[ p ] = recipe._pathsFor( paths[ p ], dir )[ 0 ];
    return result0;
  }

  /* */

  var result = paths;

  _.assert( !!recipe.env );

  result = recipe.env.resolve( result );
  result = _.path.s.join( dir, result );

  // if( _.strIs( paths ) )
  // paths = [ paths ];

  if( _.arrayIs( result ) )
  return recipe._pathsFor( result, dir );

  result = _.path.resolve( maker.currentPath, result );

  return [ result ];
}

// --
// relations
// --

var Composes =
{

  name : null,

  shell : null,
  before : null,
  after : null,
  head : null,
  post : null,
  debug : 0,
  beforeDirs : null,

  opt : null,

  kind : 'recipe',
  beforeNodes : null,
  afterNodes : null,
  upToDate : null,

  _filePath : null,
  _dirs : null,

}

var Aggregates =
{
}

var Associates =
{
  maker : null,
  env : null,
}

var Restricts =
{
  _preformed : 0,
  _formed : 0,
}

var Statics =
{
  Kind : [ 'recipe', 'file' ],
}

var Forbids =
{
  verbosity : 'verbosity',
}

// --
// declare
// --

const Proto =
{

  preform,
  form,

  hasAfter,

  subFrom,

  isDone,

  investigateUpToDate,
  _investigateUpToDate,
  investigateUpToDateRecipe,
  investigateUpToDateFile,

  makeTarget,
  _makeTarget,
  _makeTargetDependencies,

  filesMissed,
  filesMissedWithError,

  pathsFor,
  _pathsFor,

  //


  Composes,
  Aggregates,
  Associates,
  Restricts,
  Statics,

}

//

_.classDeclare
({
  cls : Self,
  extend : Proto,
  parent : Parent,
});

_.Copyable.mixin( Self );

_.accessor.forbid( Self.prototype, Forbids );

//

_.prototypeCrossRefer
({
  name : 'MakerAndRecipe',
  entities :
  {
    Maker : null,
    Recipe : Self,
  },
});

//

if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

})();
