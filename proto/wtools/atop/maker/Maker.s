( function _Maker_s_( )
{

'use strict';

if( typeof module !== 'undefined' )
{

  const _ = require( '../../../node_modules/Tools' );

  _.include( 'wLogger' );
  _.include( 'wFiles' );
  _.include( 'wTemplateTreeResolver' );
  _.include( 'wTemplateTreeEnvironment' );

}

//

const _ = _global_.wTools;
const Parent = null;
const Self = wMaker;
function wMaker( o )
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

  var recipeName = _.process.input().subject;

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
    throw _.errBrief( 'Recipe', recipe, 'does not exist!' );
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
  else throw _.err( 'no name for recipe', recipe );

  // result = recipe.env.resolve( result );

  if( !_.strDefined( result ) )
  throw _.err( 'no name for recipe', recipe );

  return result;
}

//

function recipesAdjust()
{
  var maker = this;

  /* */

  if( _.object.isBasic( maker.recipies ) )
  for( let t in maker.recipies )
  {
    var recipe = maker.recipies[ t ];

    if( recipe.after === undefined )
    recipe.after = t;

    recipe.name = maker.recipeNameGet( recipe );
    if( t !== recipe.name )
    throw _.err( 'Name of recipe', recipe.name, 'does not match key', t );

    if( maker.defaultRecipeName === null )
    maker.defaultRecipeName = recipe.name;

  }
  else if( _.arrayIs( maker.recipies ) )
  {
    var result = Object.create( null );

    for( let t = 0 ; t < maker.recipies.length ; t++ )
    {
      var recipe1 = maker.recipies[ t ];

      recipe1.name = maker.recipeNameGet( recipe1 );
      result[ recipe1.name ] = recipe1;

      if( maker.defaultRecipeName === null )
      maker.defaultRecipeName = recipe1.name;
    }

    maker.recipies = result;
  }

  /* */

  if( !_.object.isBasic( maker.recipies ) )
  throw _.err( 'Maker expects map {-recipe-}' )

  for( let t in maker.recipies )
  {
    var recipe2 = maker.recipies[ t ] = new maker.Recipe( maker.recipies[ t ] );
    recipe2.maker = maker;
  }

  for( let t in maker.recipies )
  {
    var recipe3 = maker.recipies[ t ];
    recipe3.preform();
  }

  for( let t in maker.recipies )
  {
    var recipe4 = maker.recipies[ t ];
    recipe4.form();
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
      _.arrayAppendArray( result, r );
      return result;
    }
  }

  for( let r in maker.recipies )
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
//   result = _.path.resolve( maker.currentPath, result );
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
  head : null,
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
  abstract,
  recipe,
  'recipe processed' : recipeProcessed,
}

// --
// relations
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
  RecipeFields,
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

const Proto =
{

  form,
  make,
  exec,

  recipeFor,
  recipeNameGet,
  recipesAdjust,

  recipyWithBefore,


  // etc

  // pathsFor : pathsFor,
  _optSet,
  _recipiesSet,


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

_.accessor.declare( Self.prototype, Accessors );
_.accessor.declare( Self.prototype, Forbids );

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
