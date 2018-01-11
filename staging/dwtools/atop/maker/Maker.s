( function _Maker_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  if( typeof wBase === 'undefined' )
  try
  {
    require( '../../Base.s' );
  }
  catch( err )
  {
    require( 'wTools' );
  }

  var _ = wTools;

  _.include( 'wFiles' );
  _.include( 'wTemplateTreeResolver' );
  _.include( 'wLogger' );

}

//

var _ = wTools;
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
  maker.env = wTemplateTreeResolver({ tree : { opt : maker.opt, recipe : maker.recipe } });

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
    if( !maker.env.tree.recipe[ recipe ] )
    throw _.errBriefly( 'Recipe',recipe,'does not exist!' );
    recipe = maker.env.tree.recipe[ recipe ];
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

  if( !_.strIsNotEmpty( result ) )
  throw _.err( 'no name for recipe',recipe );

  return result;
}

//

function recipesAdjust()
{
  var maker = this;

  /* */

  if( _.objectIs( maker.env.tree.recipe ) )
  for( var t in maker.env.tree.recipe )
  {

    var recipe = maker.env.tree.recipe[ t ];

    if( recipe.after === undefined )
    recipe.after = t;

    recipe.name = maker.recipeNameGet( recipe );

    if( t !== recipe.name )
    throw _.err( 'Name of recipe',recipe.name,'does not match key',t );

    if( maker.defaultRecipeName === null )
    maker.defaultRecipeName = recipe.name;

  }
  else if( _.arrayIs( maker.env.tree.recipe ) )
  {
    var result = Object.create( null );
    for( var t = 0 ; t < maker.env.tree.recipe.length ; t++ )
    {
      var recipe = maker.env.tree.recipe[ t ];

      recipe.name = maker.recipeNameGet( recipe );
      result[ recipe.name ] = recipe;

      if( maker.defaultRecipeName === null )
      maker.defaultRecipeName = recipe.name;

    }

    maker.env.tree.recipe = result;
  }

  /* */

  if( !_.objectIs( maker.env.tree.recipe ) )
  throw _.err( 'Maker expects map of targets ( recipe )' )

  // for( var t in maker.env.tree.recipe )
  // maker.targetAdjust( maker.env.tree.recipe[ t ] );

  for( var t in maker.env.tree.recipe )
  {
    var recipe = maker.env.tree.recipe[ t ] = new maker.Recipe( maker.env.tree.recipe[ t ] );
    recipe.maker = maker;
  }

  for( var t in maker.env.tree.recipe )
  {
    var recipe = maker.env.tree.recipe[ t ];
    recipe.form();
  }

  maker.env.resolveAndAssign();

}

// --
// etc
// --

function pathesFor( pathes )
{
  var maker = this;

  _.assert( arguments.length === 1 );
  _.assert( _.arrayIs( pathes ) || _.strIs( pathes ) );

  // console.log( 'pathes',pathes );
  // debugger;

  if( _.arrayIs( pathes ) )
  {
    var result = [];
    for( var p = 0 ; p < pathes.length ; p++ )
    result[ p ] = maker.pathesFor( pathes[ p ] )[ 0 ];
    return result;
  }

  //

  var result = pathes;

  result = maker.env.resolve( result );

  if( _.arrayIs( result ) )
  return maker.pathesFor( result );

  result = _.pathResolve( maker.currentPath,result );

  return [ result ];
}

//

function _optSet( src )
{
  var maker = this;

  maker[ optSymbol ] = src;

  if( maker.env )
  maker.env.tree.opt = src;

}

//

function _recipeSet( src )
{
  var maker = this;

  maker[ recipeSymbol ] = src;

  if( maker.env )
  maker.env.tree.recipe = src;

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
var recipeSymbol = Symbol.for( 'recipe' );

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
  recipe : null,
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
  recipe : 'recipe',
}

var Forbids =
{
  target : 'target',
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


  // etc

  pathesFor : pathesFor,
  _optSet : _optSet,
  _recipeSet : _recipeSet,


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

_global_[ Self.name ] = wTools[ Self.nameShort ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

//

if( typeof module !== 'undefined' )
{
  require( './Recipe.s' );
}

})( );
