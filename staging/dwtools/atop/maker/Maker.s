( function _Maker_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }


  var _ = _global_.wTools;

  _.include( 'wLogger' );
  _.include( 'wFiles' );
  _.include( 'wTemplateTreeResolver' );
  _.include( 'wTemplateTreeEnvironment' );

}

//

var _ = _global_.wTools;
var Parent = null;
var Self = function wMaker( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  return o;
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'Maker';

//

function form()
{
  var maker = this;

  _.assert( arguments.length === 0 );

  // if( !maker.opt )
  // throw _.err( 'Maker expects ( opt )' );

  /* */

  if( !maker.currentPath )
  maker.currentPath = _.pathRealMainDir();

  if( !maker.fileProvider )
  maker.fileProvider = _.FileProvider.HardDrive();

  if( !maker.env )
  maker.env = wTemplateTreeEnvironment({ tree : { opt : maker.opt, recipe : maker.recipies } });

  /* */

  // logger.log( 'make' );
  // logger.log( 'process.argv :',process.argv );

  maker.recipesAdjust();

  var recipe = maker.recipeName || maker.defaultRecipeName;

  if( !recipe )
  throw _.err( 'Maker expects ( recipe )' );

  recipe = maker.recipeFor( recipe );

  if( recipe )
  return recipe.makeTarget();
}

//

function make( recipeName )
{
  var maker = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  maker.recipeName = recipeName;

  return maker.form();
}

//

function exec()
{
  var maker = this;

  _.assert( arguments.length === 0 );

  var recipeName = _.appArgs().subject;

  return maker.make( recipeName );
}

//

function recipeFor( recipe )
{
  var maker = this;

  _.assert( arguments.length === 1 );

  if( _.strIs( recipe ) )
  {
    if( !maker.recipies[ recipe ] )
    throw _.errBriefly( 'Recipe',recipe,'does not exist!' );
    recipe = maker.recipies[ recipe ];
  }

  _.assert( recipe instanceof Self.Recipe );

  return recipe;
}

//

function recipeNameGet( recipe )
{
  var maker = this;
  var result = recipe;

  _.assert( arguments.length === 1 );

  if( recipe.name !== undefined )
  result = recipe.name;
  else if( _.strIs( recipe.after ) )
  result = recipe.after;
  else if( _.arrayIs( recipe.after ) )
  result = recipe.after.join( ',' );
  else throw _.err( 'no name for recipe',recipe );

  // debugger;
  // result = recipe.env.resolve( result );

  if( !_.strIsNotEmpty( result ) )
  debugger;

  if( !_.strIsNotEmpty( result ) )
  throw _.err( 'no name for recipe',recipe );

  return result;
}

//

function recipesAdjust()
{
  var maker = this;

  /* */

  if( _.objectIs( maker.recipies ) )
  for( var t in maker.recipies )
  {
    var recipe = maker.recipies[ t ];

    if( recipe.after === undefined )
    recipe.after = t;

    recipe.name = maker.recipeNameGet( recipe );
    if( t !== recipe.name )
    throw _.err( 'Name of recipe',recipe.name,'does not match key',t );

    if( maker.defaultRecipeName === null )
    maker.defaultRecipeName = recipe.name;

  }
  else if( _.arrayIs( maker.recipies ) )
  {
    var result = Object.create( null );

    for( var t = 0 ; t < maker.recipies.length ; t++ )
    {
      var recipe = maker.recipies[ t ];

      recipe.name = maker.recipeNameGet( recipe );
      result[ recipe.name ] = recipe;

      if( maker.defaultRecipeName === null )
      maker.defaultRecipeName = recipe.name;
    }

    maker.recipies = result;
  }

  /* */

  if( !_.objectIs( maker.recipies ) )
  throw _.err( 'Maker expects map ( recipe )' )

  for( var t in maker.recipies )
  {
    var recipe = maker.recipies[ t ] = new maker.Recipe( maker.recipies[ t ] );
    recipe.maker = maker;
  }

  for( var t in maker.recipies )
  {
    var recipe = maker.recipies[ t ];
    recipe.preform();
  }

  for( var t in maker.recipies )
  {
    var recipe = maker.recipies[ t ];
    recipe.form();
  }

  // maker.env.resolveAndAssign();

}

//

function recipyWithBefore( before )
{
  var maker = this;

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( before ) || _.arrayIs( before ) );

  if( _.arrayIs( before ) )
  {
    var result = [];
    for( var b = 0 ; b < before.length ; b++ )
    {
      var r = maker.recipyWithBefore( before[ b ] );
      _.arrayAppendArray( result,r );
      return result;
    }
  }

  for( var r in maker.recipies )
  {
    var recipe = maker.recipies[ r ];
    var name = recipe.env.resolve( recipe.name );

    if( name === before )
    return [ recipe ];
    else if( recipe.hasAfter( before ) )
    return [ recipe ];

  }

  return [];
}

// --
// etc
// --

// function pathsFor( paths )
// {
//   var maker = this;
//
//   _.assert( arguments.length === 1 );
//   _.assert( _.arrayIs( paths ) || _.strIs( paths ) );
//
//   /* */
//
//   if( _.arrayIs( paths ) )
//   {
//     var result = [];
//     for( var p = 0 ; p < paths.length ; p++ )
//     result[ p ] = maker.pathsFor( paths[ p ] )[ 0 ];
//     return result;
//   }
//
//   /* */
//
//   var result = paths;
//
//   result = maker.env.resolve( result );
//
//   if( _.arrayIs( result ) )
//   return maker.pathsFor( result );
//
//   result = _.pathResolve( maker.currentPath,result );
//
//   return [ result ];
// }

//

function _optSet( src )
{
  var maker = this;

  maker[ optSymbol ] = src;

  if( maker.env )
  maker.env.tree.opt = src;

}

//

function _recipiesSet( src )
{
  var maker = this;

  maker[ recipiesSymbol ] = src;

  if( maker.env )
  maker.env.tree.recipies = src;

}

// --
// targets
// --

var abstract = _.like()
.also
({
  name : '',
})
.end

var recipe = _.like( abstract )
.also
({
  shell : null,
  before : null,
  after : null,
  pre : null,
  post : null,
  debug : 0,
  beforeDirs : null,
})
.end

var recipeProcessed = _.like( recipe )
.also
({
  kind : '',
  beforeNodes : null,
})
.end

var RecipeFields =
{
  'abstract' : abstract,
  'recipe' : recipe,
  'recipe processed' : recipeProcessed,
}

// --
// relationship
// --

var optSymbol = Symbol.for( 'opt' );
var recipiesSymbol = Symbol.for( 'recipies' );

var Composes =
{
  recipeName : null,
  defaultRecipeName : null,
  verbosity : 1,
  currentPath : null,
}

var Aggregates =
{
  opt : null,
  recipies : null,
}

var Associates =
{
  fileProvider : null,
  env : null,
}

var Restricts =
{
}

var Statics =
{
  RecipeFields : RecipeFields,
}

var Accessors =
{
  opt : 'opt',
  recipies : 'recipies',
}

var Forbids =
{
  target : 'target',
  recipe : 'recipe',
  recipy : 'recipy',
}

// --
// proto
// --

var Proto =
{

  form : form,
  make : make,
  exec : exec,

  recipeFor : recipeFor,
  recipeNameGet : recipeNameGet,
  recipesAdjust : recipesAdjust,

  recipyWithBefore : recipyWithBefore,


  // etc

  // pathsFor : pathsFor,
  _optSet : _optSet,
  _recipiesSet : _recipiesSet,


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

_.Copyable.mixin( Self );

_.accessor( Self.prototype,Accessors );
_.accessor( Self.prototype,Forbids );

_.prototypeCrossRefer
({
  name : 'MakerAndRecipe',
  entities :
  {
    Maker : Self,
    Recipe : null,
  },
});

//

_global_[ Self.name ] = _[ Self.nameShort ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

//

if( typeof module !== 'undefined' )
{
  require( './Recipe.s' );
}

})( );
