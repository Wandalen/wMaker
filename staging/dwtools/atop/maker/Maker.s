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

function form( targetName )
{
  var self = this;

  _.assert( arguments.length <= 1 );

  if( !self.recipe )
  throw _.err( 'Maker expects ( recipe )' );
  // if( !self.opt )
  // throw _.err( 'Maker expects ( opt )' );

  /* */

  if( !self.currentPath )
  self.currentPath = _.pathRealMainDir();

  if( !self.fileProvider )
  self.fileProvider = _.FileProvider.HardDrive();

  if( !self.env )
  self.env = wTemplateTreeResolver({ tree : { opt : self.opt, recipe : self.recipe } });

  /* */

  // logger.log( 'make' );
  // logger.log( 'process.argv :',process.argv );

  self.targetsAdjust();

  debugger

  var nameOfTarget = targetName || self.defaultTargetName;

  if( nameOfTarget )
  return self.makeTarget( nameOfTarget );
}

//

function exec()
{
  var self = this;

  _.assert( arguments.length === 0 );

  var targetName = _.appArgs().subject;
  return self.form( targetName );
}

//

function makeTarget( recipe )
{
  var self = this;
  var con = new wConsequence();

  _.assert( arguments.length === 1 );
  // console.log( 'self.env.tree',self.env.tree );

  if( _.strIs( recipe ) )
  {
    if( !self.env.tree.recipe[ recipe ] )
    throw _.errBriefly( 'Recipe',recipe,'does not exist!' );
    recipe = self.env.tree.recipe[ recipe ];
  }

  // logger.log( 'making recipe',recipe.name,recipe );

  if( self.targetInvestigateUpToDate( recipe ) )
  {
    logger.log( 'Recipe',recipe.name,'is up to date' );
    return con.give();
  }

  return self._makeTarget( recipe );
}

//

function _makeTarget( recipe )
{
  var self = this;
  var con = new wConsequence().give();

  if( _.strIs( recipe ) )
  recipe = self.env.tree.recipe[ recipe ];

  if( self.verbosity )
  logger.logUp( 'making recipe',recipe.name );

  if( recipe.upToDate )
  {
    logger.logDown( '' );
    return con;
  }

  /* pre */

  if( recipe.pre )
  con.ifNoErrorThen( function()
  {
    return recipe.pre.call( self,recipe );
  });

  /* dependencies */

  self._makeTargetDependencies( recipe,con );

  /* shell */

  if( recipe.shell )
  con.ifNoErrorThen( function()
  {
    if( recipe.shell )
    return _.shell( recipe.shell );
  });

  /* post */

  if( recipe.post )
  con.ifNoErrorThen( function()
  {
    return recipe.post.call( self,recipe );
  });

  /* validation */

  con.ifNoErrorThen( function()
  {

    debugger;
    var done = self.targetIsDone( recipe );
    if( !done.ok )
    throw _.errBriefly( 'Recipe "' + recipe.name +'" failed to produce "' + done.missing + '"' );

  });

  /* end */

  con.doThen( function( err,data )
  {

    debugger;

    if( err )
    {
      debugger;
      _.appExitCode( -1 );
      err = _.errLogOnce( err );
    }

    if( self.verbosity )
    logger.logDown( '' );

    if( err )
    throw err;
  });

  return con;
}

//

function _makeTargetDependencies( recipe,con )
{
  var self = this;

  /* */

  for( var d in recipe.beforeNodes )
  {
    var node = recipe.beforeNodes[ d ];

    // logger.log( 'node.kind',node.kind );

    if( node.kind === 'recipe' )
    {
      con.ifNoErrorThen( _.routineSeal( self,self._makeTarget, [ node ] ) );
    }
    else if( node.kind === 'file' )
    {
      debugger;
      // logger.log( 'file',node.filePath,self.pathesFor( node.filePath ) );
      if( !self.fileProvider.fileStat( self.pathesFor( node.filePath )[ 0 ] ) )
      throw _.err( 'not made :',node.filePath );
    }
    else throw _.err( 'unknown recipe kind',recipe.kind );

  }

  return con;
}

//

function _targetName( recipe )
{
  var result;

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

function targetsAdjust()
{
  var self = this;

  /* */

  if( _.objectIs( self.env.tree.recipe ) )
  for( var t in self.env.tree.recipe )
  {

    var recipe = self.env.tree.recipe[ t ];

    if( recipe.after === undefined )
    recipe.after = t;

    recipe.name = self._targetName( recipe );

    if( t !== recipe.name )
    throw _.err( 'Name of recipe',recipe.name,'does not match key',t );

    if( self.defaultTargetName === null )
    self.defaultTargetName = recipe.name;

  }
  else if( _.arrayIs( self.env.tree.recipe ) )
  {
    var result = Object.create( null );
    for( var t = 0 ; t < self.env.tree.recipe.length ; t++ )
    {
      var recipe = self.env.tree.recipe[ t ];

      recipe.name = self._targetName( recipe );
      result[ recipe.name ] = recipe;

      if( self.defaultTargetName === null )
      self.defaultTargetName = recipe.name;

    }

    self.env.tree.recipe = result;
  }

  /* */

  if( !_.objectIs( self.env.tree.recipe ) )
  throw _.err( 'Maker expects map of targets ( recipe )' )

  for( var t in self.env.tree.recipe )
  self.targetAdjust( self.env.tree.recipe[ t ] );

  self.env.resolveAndAssign();

}

//

function targetAdjust( recipe )
{
  var self = this;

  /* verification */

  var but = _.mapKeys( _.mapBut( recipe,self.Recipe[ 'recipe' ] ) );
  if( but.length )
  throw _.err( 'Recipe',recipe.name,'should not have fields',but );

  if( recipe.shell && !_.strIs( recipe.shell ) )
  throw _.err( 'Recipe',recipe.name,'expects string ( shell )' );

  if( recipe.pre && !_.routineIs( recipe.pre ) )
  throw _.err( 'Recipe',recipe.name,'expects routine ( pre )' );

  if( recipe.post && !_.routineIs( recipe.post ) )
  throw _.err( 'Recipe',recipe.name,'expects routine ( post )' );

  if( recipe.after && !_.arrayIs( recipe.after ) && !_.strIs( recipe.after ) )
  throw _.err( 'Recipe',recipe.name,'expects string or array ( recipe )' );

  if( !_.arrayIs( recipe.before ) && !_.strIs( recipe.before ) )
  throw _.err( 'Recipe',recipe.name,'expects array or string ( before )' );

  if( recipe.kind !== undefined )
  throw _.err( 'Recipe',recipe.name,'should not have ( kind )' );

  /* */

  recipe.after = _.arrayAs( recipe.after );
  recipe.before = _.arrayAs( recipe.before );
  recipe.before = _.arrayAs( _.arrayFlatten( [], recipe.before ) );
  recipe.beforeNodes = Object.create( null );
  recipe.kind = 'recipe';

  if( recipe.debug )
  debugger;

  for( var d = 0 ; d < recipe.before.length ; d++ )
  {
    var name = recipe.before[ d ];

    if( recipe.beforeNodes[ name ] )
    throw _.err( 'Taget',recipe.name,'already has dependency',name );

    if( self.env.tree.recipe[ name ] )
    recipe.beforeNodes[ name ] = self.env.tree.recipe[ name ];
    else
    recipe.beforeNodes[ name ] = { kind : 'file', filePath : name };
  }

  /* validation */

  _.assert( _.arrayIs( recipe.after ) );
  _.assert( _.arrayIs( recipe.before ) );
  _.assertMapHasOnly( recipe,self.Recipe[ 'recipe processed' ] );

}

//

function targetIsDone( recipe )
{
  var self = this;
  var result = Object.create( null );
  result.ok = 0;

  _.assert( arguments.length === 1 );

  var pathes = self.pathesFor( recipe.after );
  for( var a = 0 ; a < recipe.after.length ; a++ )
  {
    // logger.log( 'checking',pathes[ a ] );
    if( !self.fileProvider.fileStat( pathes[ a ] ) )
    {
      result.missing = pathes[ a ];
      return result;
    }
  }

  result.ok = 1;
  return result;
}

//

function targetInvestigateUpToDate( recipe,parent )
{
  var self = this;
  var result = true;

  // console.log( 'targetInvestigateUpToDate',recipe ); debugger;

  if( recipe.kind === 'recipe' )
  result = self.targetInvestigateUpToDateRecipe( recipe ) && result;
  else if( recipe.kind === 'file' )
  result = self.targetInvestigateUpToDateFile( recipe,parent ) && result;
  else throw _.err( 'unknown recipe kind',recipe.kind );

  recipe.upToDate = result;

  return result;
}

//

function targetInvestigateUpToDateRecipe( recipe )
{
  var self = this;
  var result = true;

  _.assert( recipe.kind === 'recipe' );

  if( !Object.keys( recipe.beforeNodes ).length )
  result = false;

  for( var d in recipe.beforeNodes )
  {
    var node = recipe.beforeNodes[ d ];
    result = self.targetInvestigateUpToDate( node,recipe ) && result;
  }

  recipe.upToDate = result;

  return result;
}

//

function targetInvestigateUpToDateFile( file,recipe )
{
  var self = this;

  _.assert( recipe );
  _.assert( arguments.length === 2 );

  if( file.upToDate !== undefined )
  {
    var result = file.upToDate;
    debugger;
    // logger.log( '! targetInvestigateUpToDateFile',recipe.after,':',result );
    return result;
  }

  var dst = self.pathesFor( recipe.after );
  var src = self.pathesFor( file.filePath );

  var result = self.fileProvider.filesAreUpToDate( dst,src );

  if( self.verbosity > 1 )
  // if( !result )
  logger.log( 'targetInvestigateUpToDateFile(',recipe.after.join( ',' ),') :',result );
  // logger.log( 'targetInvestigateUpToDateFile(',dst,'<-',src,') :',result );

  return result;
}

// --
// etc
// --

function pathesFor( pathes )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( _.arrayIs( pathes ) || _.strIs( pathes ) );

  // console.log( 'pathes',pathes );
  // debugger;

  if( _.arrayIs( pathes ) )
  {
    var result = [];
    for( var p = 0 ; p < pathes.length ; p++ )
    result[ p ] = self.pathesFor( pathes[ p ] )[ 0 ];
    return result;
  }

  var result = _.pathResolve( self.currentPath,pathes );

  return [ result ];
}

//

function _optSet( src )
{
  var self = this;

  self[ optSymbol ] = src;

  if( self.env )
  self.env.tree.opt = src;

}

//

function _targetSet( src )
{
  var self = this;

  self[ targetSymbol ] = src;

  if( self.env )
  self.env.tree.recipe = src;

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
})
.end

var recipeProcessed = _.like( recipe )
.also
({
  kind : '',
  beforeNodes : null,
})
.end

var Recipe =
{
  'abstract' : abstract,
  'recipe' : recipe,
  'recipe processed' : recipeProcessed,
}

// --
// relationship
// --

var optSymbol = Symbol.for( 'opt' );
var targetSymbol = Symbol.for( 'recipe' );

var Composes =
{
  defaultTargetName : null,
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
  Recipe : Recipe,
}

// --
// proto
// --

var Proto =
{

  form : form,
  exec : exec,
  makeTarget : makeTarget,
  _makeTarget : _makeTarget,
  _makeTargetDependencies : _makeTargetDependencies,

  _targetName : _targetName,

  targetsAdjust : targetsAdjust,
  targetAdjust : targetAdjust,
  targetIsDone : targetIsDone,

  targetInvestigateUpToDate : targetInvestigateUpToDate,
  targetInvestigateUpToDateRecipe : targetInvestigateUpToDateRecipe,
  targetInvestigateUpToDateFile : targetInvestigateUpToDateFile,


  // etc

  pathesFor : pathesFor,
  _optSet : _optSet,
  _targetSet : _targetSet,


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

 //

_.accessor( Self.prototype,
{
  opt : 'opt',
  recipe : 'recipe',
});

//

_global_[ Self.name ] = wTools[ Self.nameShort ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})( );
