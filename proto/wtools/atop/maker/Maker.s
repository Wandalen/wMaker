( function _Maker_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../wtools/Tools.s' );

  _.include( 'wLogger' );
  _.include( 'wFiles' );
  _.include( 'wTemplateTreeResolver' );
  _.include( 'wTemplateTreeEnvironment' );

}

//

let _ = _global_.wTools;
let Parent = null;
let Self = function wMaker( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.shortName = 'Maker';

//

function form()
{
  var maker = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  // if( !maker.opt )
  // throw _.err( 'Maker expects {-opt-}' );

  /* */

  if( !maker.currentPath )
  maker.currentPath = _.path.realMainDir();

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
  throw _.err( 'Maker expects {-recipe-}' );

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

  _.assert( arguments.length === 0, 'Expects no arguments' );

  var recipeName = _.process.args().subject;

  return maker.make( recipeName );
}

//

function recipeFor( recipe )
{
  var maker = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( _.strIs( recipe ) )
  {
    if( !maker.recipies[ recipe ] )
    throw _.errBrief( 'Recipe',recipe,'does not exist!' );
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

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( recipe.name !== undefined )
  result = recipe.name;
  else if( _.strIs( recipe.after ) )
  result = recipe.after;
  else if( _.arrayIs( recipe.after ) )
  result = recipe.after.join( ',' );
  else throw _.err( 'no name for recipe',recipe );

  // debugger;
  // result = recipe.env.resolve( result );

  if( !_.strDefined( result ) )
  debugger;

  if( !_.strDefined( result ) )
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
  throw _.err( 'Maker expects map {-recipe-}' )

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

  _.assert( arguments.length === 1, 'Expects single argument' );
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
//   _.assert( arguments.length === 1, 'Expects single argument' );
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
//   result = _.path.resolve( maker.currentPath,result );
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
// declare
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


  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

}

//

_.classDeclare
({
  cls : Self,
  extend : Proto,
  parent : Parent,
});

_.Copyable.mixin( Self );

_.accessor.declare( Self.prototype,Accessors );
_.accessor.declare( Self.prototype,Forbids );

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

_global_[ Self.name ] = _[ Self.shortName ] = Self;
if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

//

if( typeof module !== 'undefined' )
{
  require( './Recipe.s' );
}

})( );
