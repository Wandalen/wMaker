( function _Recipe_s_( ) {

'use strict';

//

var _ = wTools;
var Parent = null;
var Self = function wRecipe( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  return o;
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'Recipe';

// --
//
// --

function form()
{
  var recipe = this;
  var maker = recipe.maker;

  // debugger; xxx

  /* verification */

  _.assert( maker,'expects { maker }' );
  _.assert( arguments.length === 0 );
  _.assert( !recipe._formed );

  // var but = _.mapKeys( _.mapBut( recipe,maker.RecipeFields[ 'recipe' ] ) );
  // if( but.length )
  // throw _.err( 'Recipe',recipe.name,'should not have fields',but );

  if( recipe.shell && !_.strIs( recipe.shell ) )
  throw _.err( 'Recipe',recipe.name,'expects string { shell }' );

  if( recipe.pre && !_.routineIs( recipe.pre ) )
  throw _.err( 'Recipe',recipe.name,'expects routine { pre }' );

  if( recipe.post && !_.routineIs( recipe.post ) )
  throw _.err( 'Recipe',recipe.name,'expects routine { post }' );

  if( recipe.after && !_.arrayIs( recipe.after ) && !_.strIs( recipe.after ) )
  throw _.err( 'Recipe',recipe.name,'expects string or array { recipe }' );

  if( !_.arrayIs( recipe.before ) && !_.strIs( recipe.before ) )
  throw _.err( 'Recipe',recipe.name,'expects array or string { before }' );

  // if( recipe.kind !== '' )
  // throw _.err( 'Recipe',recipe.name,'should not have { kind }' );

  /* */

  if( !recipe.beforeDirs )
  recipe.beforeDirs = [];
  else
  recipe.beforeDirs = _.arrayAs( recipe.beforeDirs );

  recipe.after = _.arrayAs( recipe.after );
  // recipe.before = _.arrayAs( recipe.before );
  recipe.before = _.arrayAs( _.arrayFlatten( [], recipe.before ) );
  recipe.beforeNodes = Object.create( null );
  recipe.afterNodes = Object.create( null );
  // recipe.kind = 'recipe';

  if( recipe.debug )
  debugger;

  for( var d = 0 ; d < recipe.before.length ; d++ )
  {
    var name = recipe.before[ d ];

    if( recipe.beforeNodes[ name ] )
    throw _.err( 'Taget',recipe.name,'already has dependency',name );

    recipe.beforeNodes[ name ] = recipe.subFrom( name );

  }

  /* validation */

  _.assert( _.arrayIs( recipe.after ) );
  _.assert( _.arrayIs( recipe.before ) );
  // _.assertMapHasOnly( recipe,maker.RecipeFields[ 'recipe processed' ] );

  recipe._formed = 1;
}

//

function subFrom( name )
{
  var recipe = this;
  var maker = recipe.maker;
  var subRecipe;

  // debugger;

  _.assert( arguments.length === 1 );

  // var name = recipe.before[ d ];
  // var subRecipe = map[ name ];
  // if( subRecipe )
  // throw _.err( 'Taget',recipe.name,'already has dependency',name );

  if( maker.env.tree.recipe[ name ] )
  subRecipe = maker.env.tree.recipe[ name ];
  else
  subRecipe = Self({ kind : 'file', _filePath : name, _dirs : recipe.beforeDirs, maker : maker });

  // recipe.beforeNodes[ name ] = { kind : 'file', filePath : name, dirs : recipe.beforeDirs };

  _.assert( subRecipe instanceof Self );
  _.assert( subRecipe.kind );

  // debugger;

  return subRecipe;
}

//

function isDone()
{
  var recipe = this;
  var maker = recipe.maker;
  var result = Object.create( null );
  result.ok = 0;

  _.assert( arguments.length === 0 );

  var pathes = maker.pathesFor( recipe.after );
  for( var a = 0 ; a < recipe.after.length ; a++ )
  {
    if( !maker.fileProvider.fileStat( pathes[ a ] ) )
    {
      result.missing = pathes[ a ];
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
  _.assert( arguments.length === 0 );
  return recipe._investigateUpToDate( null );
}

//

function _investigateUpToDate( parent )
{
  var recipe = this;
  var result = true;

  _.assert( arguments.length === 1 );

  if( recipe.kind === 'recipe' )
  result = recipe.investigateUpToDateRecipe() && result;
  else if( recipe.kind === 'file' )
  result = recipe.investigateUpToDateFile( parent ) && result;
  else _.assert( 0,'unknown recipe kind',recipe.kind );

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

  _.assert( recipe );
  _.assert( arguments.length === 1 );

  if( file.upToDate !== undefined )
  {
    var result = file.upToDate;
    // debugger;
    // logger.log( '! investigateUpToDateFile',recipe.after,':',result );
    return result;
  }

  var dst = maker.pathesFor( recipe.after );
  var src = maker.pathesFor( file._filePath );

  var result = maker.fileProvider.filesAreUpToDate( dst,src );

  if( maker.verbosity > 1 )
  // if( !result )
  logger.log( 'investigateUpToDateFile(',recipe.after.join( ',' ),') :',result );
  // logger.log( 'investigateUpToDateFile(',dst,'<-',src,') :',result );

  return result;
}

//

function makeTarget()
{
  var recipe = this;
  var maker = recipe.maker;
  var con = new wConsequence();

  _.assert( arguments.length === 0 );
  // console.log( 'maker.env.tree',maker.env.tree );

  // if( _.strIs( recipe ) )
  // {
  //   if( !maker.env.tree.recipe[ recipe ] )
  //   throw _.errBriefly( 'Recipe',recipe,'does not exist!' );
  //   recipe = maker.env.tree.recipe[ recipe ];
  // }

  // logger.log( 'making recipe',recipe.name,recipe );

  if( recipe.investigateUpToDate() )
  {
    logger.log( 'Recipe',recipe.name,'is up to date' );
    return con.give();
  }

  return recipe._makeTarget();
}

//

function _makeTarget()
{
  var recipe = this;
  var maker = recipe.maker;
  var con = new wConsequence().give();

  _.assert( arguments.length === 0 );

  if( _.strIs( recipe ) )
  recipe = maker.env.tree.recipe[ recipe ];

  if( maker.verbosity )
  logger.logUp( 'making recipe',maker.env.resolve( recipe.name ) );

  if( recipe.upToDate )
  {
    logger.logDown( '' );
    return con;
  }

  /* pre */

  if( recipe.pre )
  con.ifNoErrorThen( function()
  {
    return recipe.pre.call( maker,recipe );
  });

  /* dependencies */

  recipe._makeTargetDependencies( con );

  /* shell */

  if( recipe.shell )
  con.ifNoErrorThen( function()
  {
    if( recipe.shell )
    return _.shell
    ({
      path : maker.env.resolve( recipe.shell ),
      throwingBadExitCode : 1,
      applyingExitCode : 1,
      outputColoring : 1,
      outputPrefixing : 1,
    });
  });

  /* post */

  if( recipe.post )
  con.ifNoErrorThen( function()
  {
    debugger;
    throw _.err( 'not tested' );
    return recipe.post();
  });

  /* validation */

  con.ifNoErrorThen( function()
  {
    var done = recipe.isDone();

    if( !done.ok )
    throw _.errBriefly( 'Recipe "' + recipe.name +'" failed to produce "' + done.missing + '"' );

  });

  /* end */

  con.doThen( function( err,data )
  {

    if( err )
    {
      debugger;
      _.appExitCode( -1 );
      err = _.errLogOnce( err );
    }

    if( maker.verbosity )
    logger.logDown( '' );

    if( err )
    throw err;
  });

  return con;
}

//

function _makeTargetDependencies( con )
{
  var recipe = this;
  var maker = recipe.maker;

  _.assert( arguments.length === 1 );

  /* */

  for( var d in recipe.beforeNodes )
  {
    var node = recipe.beforeNodes[ d ];

    // logger.log( 'node.kind',node.kind );

    if( node._dirs && node._dirs.length )
    debugger;

    if( node.kind === 'recipe' )
    {
      con.ifNoErrorThen( _.routineSeal( node,node._makeTarget ) );
    }
    else if( node.kind === 'file' )
    {
      // if( !maker.fileProvider.fileStat( maker.pathesFor( node._filePath )[ 0 ] ) )
      // if( !recipe.filesExist( node._filePath , node._dirs ) )
      if( !node.filesExist() )
      throw _.err( 'not made :',node._filePath );
    }
    else throw _.err( 'unknown recipe kind',recipe.kind );

  }

  return con;
}

//

function filesExist()
{
  var recipe = this;
  var maker = recipe.maker;
  var dirs = recipe._dirs.length ? recipe._dirs : [ '.' ];
  var path = recipe._filePath;

  _.assert( arguments.length === 0 );

  for( var d = 0 ; d < dirs.length ; d++ )
  {
    var pathes = maker.pathesFor( _.pathJoin( dirs[ d ],path ) );

    _.assert( pathes.length >= 1,'not tested' );

    for( var f = 0 ; f < pathes.length ; f++ )
    if( !maker.fileProvider.fileStat( pathes[ f ] ) )
    break;

    if( f === pathes.length )
    return true;

  }

  return false;
}

// --
// relationship
// --

var Composes =
{
  name : null,

  shell : null,
  before : null,
  after : null,
  pre : null,
  post : null,
  debug : 0,
  beforeDirs : null,

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
}

var Restricts =
{
  _formed : 0,
}

var Statics =
{
}

var Forbids =
{
  verbosity : 'verbosity',
}

// --
// proto
// --

var Proto =
{

  form : form,

  subFrom : subFrom,

  isDone : isDone,

  investigateUpToDate : investigateUpToDate,
  _investigateUpToDate : _investigateUpToDate,
  investigateUpToDateRecipe : investigateUpToDateRecipe,
  investigateUpToDateFile : investigateUpToDateFile,

  makeTarget : makeTarget,
  _makeTarget : _makeTarget,
  _makeTargetDependencies : _makeTargetDependencies,

  filesExist : filesExist,

  //

  constructor : Self,
  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

}

//

_.classMake
({
  cls : Self,
  extend : Proto,
  parent : Parent,
});

wCopyable.mixin( Self );

_.accessorForbid( Self.prototype,Forbids );

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

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
