( function _Maker_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  if( typeof wBase === 'undefined' )
  try
  {
    require( '../include/wTools.s' );
  }
  catch( err )
  {
    require( 'wTools' );
  }

  var _ = wTools;

  _.include( 'wFiles' );
  _.include( 'wTemplateTree' );
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

var make = function make()
{
  var self = this;

  _.assert( arguments.length === 0 );

  if( !self.target )
  throw _.err( 'Maker expects ( target )' );
  // if( !self.opt )
  // throw _.err( 'Maker expects ( opt )' );

  /* */

  if( !self.currentPath )
  self.currentPath = _.pathMainDir();

  if( !self.fileProvider )
  self.fileProvider = _.FileProvider.HardDrive();

  if( !self.env )
  self.env = wTemplateTree({ tree : { opt : self.opt, target : self.target } });

  /* */

  // logger.log( 'make' );
  // logger.log( 'process.argv :',process.argv );

  self.targetsAdjust();

  var nameOfTarget = process.argv[ 2 ] || self.defaultTargetName;

  if( nameOfTarget )
  return self.makeTarget( nameOfTarget );
}

//

var makeTarget = function makeTarget( target )
{
  var self = this;
  var con = new wConsequence();

  // console.log( 'self.env.tree',self.env.tree );

  if( _.strIs( target ) )
  {
    if( !self.env.tree.target[ target ] )
    throw _.err( 'Target',target,'deos not exist!' );
    target = self.env.tree.target[ target ];
  }

  // logger.log( 'making target',target.name,target );

  if( self.targetInvestigateUpToDate( target ) )
  {
    logger.log( 'Recipe',target.name,'is up to date' );
    return con.give();
  }

  return self._makeTarget( target );

}

//

var _makeTarget = function _makeTarget( target )
{
  var self = this;
  var con = new wConsequence().give();

  if( _.strIs( target ) )
  target = self.env.tree.target[ target ];

  debugger;
  if( self.usingLogging )
  logger.logUp( 'making target',target.name );

  if( target.upToDate )
  {
    logger.logDown( '' );
    return con;
  }

  /* pre */

  if( target.pre )
  con.ifNoErrorThen( function()
  {
    return target.pre.call( self,target );
  });

  /* dependencies */

  self._makeTargetDependencies( target,con );

  /* shell */

  if( target.shell )
  con.ifNoErrorThen( function()
  {
    if( target.shell )
    return _.shell( target.shell );
  });

  /* post */

  if( target.post )
  con.ifNoErrorThen( function()
  {
    return target.post.call( self,target );
  });

  /* validation */

  con.ifNoErrorThen( function()
  {

    var pathes = self.pathesFor( target.after );
    for( var a = 0 ; a < target.after.length ; a++ )
    {
      logger.log( 'checking',pathes[ a ] );
      if( !self.fileProvider.fileStat( pathes[ a ] ) )
      throw _.err( 'Target',target.name,'failed to produce',pathes[ a ] );
    }

  });

  /* end */

  con.doThen( function( err,data )
  {

    if( self.usingLogging )
    logger.logDown( '' );

    if( err )
    throw _.errLogOnce( err );
  });

  return con;
}

//

var _makeTargetDependencies = function _makeTargetDependencies( target,con )
{
  var self = this;

  /* */

  for( var d in target.beforeNodes )
  {
    var node = target.beforeNodes[ d ];

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
    else throw _.err( 'unknown target kind',target.kind );

  }

  return con;
}

//

var _targetName = function _targetName( target )
{
  var result;

  if( target.name !== undefined )
  result = target.name;
  else if( _.strIs( target.after ) )
  result = target.after;
  else if( _.arrayIs( target.after ) )
  result = target.after.join( ',' );
  else throw _.err( 'no name for target',target );

  if( !_.strIsNotEmpty( result ) )
  throw _.err( 'no name for target',target );

  return result;
}

//

var targetsAdjust = function targetsAdjust()
{
  var self = this;

  /* */

  if( _.objectIs( self.env.tree.target ) )
  for( var t in self.env.tree.target )
  {

    var target = self.env.tree.target[ t ];

    if( target.after === undefined )
    target.after = t;

    target.name = self._targetName( target );

    if( t !== target.name )
    throw _.err( 'Name of target',target.name,'does not match key',t );

    if( self.defaultTargetName === null )
    self.defaultTargetName = target.name;

  }
  else if( _.arrayIs( self.env.tree.target ) )
  {
    var result = {};
    for( var t = 0 ; t < self.env.tree.target.length ; t++ )
    {
      var target = self.env.tree.target[ t ];

      target.name = self._targetName( target );
      result[ target.name ] = target;

      if( self.defaultTargetName === null )
      self.defaultTargetName = target.name;

    }

    self.env.tree.target = result;
  }

  /* */

  if( !_.objectIs( self.env.tree.target ) )
  throw _.err( 'Maker expects map of targets ( target )' )

  for( var t in self.env.tree.target )
  self.targetAdjust( self.env.tree.target[ t ] );

  self.env.resolveAndAssign();

}

//

var targetAdjust = function targetAdjust( target )
{
  var self = this;

  /* verification */

  var but = _.mapKeys( _.mapBut( target,self.Target[ 'recipe' ] ) );
  if( but.length )
  throw _.err( 'Target',target.name,'should not have fields',but );

  if( target.shell && !_.strIs( target.shell ) )
  throw _.err( 'Target',target.name,'expects string ( shell )' );

  if( target.pre && !_.routineIs( target.pre ) )
  throw _.err( 'Target',target.name,'expects routine ( pre )' );

  if( target.post && !_.routineIs( target.post ) )
  throw _.err( 'Target',target.name,'expects routine ( post )' );

  if( target.after && !_.arrayIs( target.after ) && !_.strIs( target.after ) )
  throw _.err( 'Target',target.name,'expects string or array ( target )' );

  if( !_.arrayIs( target.before ) && !_.strIs( target.before ) )
  throw _.err( 'Target',target.name,'expects array or string ( before )' );

  if( target.kind !== undefined )
  throw _.err( 'Target',target.name,'should not have ( kind )' );

  /* */

  target.after = _.arrayAs( target.after );
  target.before = _.arrayFlatten( target.before );
  target.beforeNodes = {};
  target.kind = 'recipe';

  for( var d = 0 ; d < target.before.length ; d++ )
  {
    var name = target.before[ d ];

    if( target.beforeNodes[ name ] )
    throw _.err( 'Taget',target.name,'already has dependency',name );

    if( self.env.tree.target[ name ] )
    target.beforeNodes[ name ] = self.env.tree.target[ name ];
    else
    target.beforeNodes[ name ] = { kind : 'file', filePath : name };
  }

  /* validation */

  _.assert( _.arrayIs( target.after ) );
  _.assert( _.arrayIs( target.before ) );
  _.assertMapHasOnly( target,self.Target[ 'recipe processed' ] );

}

//

var targetInvestigateUpToDate = function targetInvestigateUpToDate( target,parent )
{
  var self = this;
  var result = true;

  if( target.kind === 'recipe' )
  result = self.targetInvestigateUpToDateRecipe( target ) && result;
  else if( target.kind === 'file' )
  result = self.targetInvestigateUpToDateFile( target,parent ) && result;
  else throw _.err( 'unknown target kind',target.kind );

  target.upToDate = result;

  return result;
}

//

var targetInvestigateUpToDateRecipe = function targetInvestigateUpToDateRecipe( target )
{
  var self = this;
  var result = true;

  _.assert( target.kind === 'recipe' );

  for( var d in target.beforeNodes )
  {
    var node = target.beforeNodes[ d ];
    result = self.targetInvestigateUpToDate( node,target ) && result;
  }

  target.upToDate = result;

  return result;
}

//

var targetInvestigateUpToDateFile = function targetInvestigateUpToDateFile( file,recipe )
{
  var self = this;

  _.assert( recipe );
  _.assert( arguments.length === 2 );

  if( file.upToDate !== undefined )
  {
    var result = file.upToDate;
    debugger;
    logger.log( '! targetInvestigateUpToDateFile',recipe.after,':',result );
    return result;
  }

  var dst = self.pathesFor( recipe.after );
  var src = self.pathesFor( file.filePath );

  var result = self.fileProvider.filesIsUpToDate( dst,src );

  if( self.usingLogging )
  if( !result )
  logger.log( 'targetInvestigateUpToDateFile(',recipe.after.join( ',' ),') :',result );
  // logger.log( 'targetInvestigateUpToDateFile(',dst,'<-',src,') :',result );

  return result;
}

// --
// etc
// --

var pathesFor = function pathesFor( pathes )
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

  var result = _.pathJoin( self.currentPath,pathes );

  return [ result ];
}

//

var _optSet = function _optSet( src )
{
  var self = this;

  self[ optSymbol ] = src;

  if( self.env )
  self.env.tree.opt = src;

}

//

var _targetSet = function _targetSet( src )
{
  var self = this;

  self[ targetSymbol ] = src;

  if( self.env )
  self.env.tree.target = src;

}

// --
// targets
// --

var target = _.like()
.also
({
  name : '',
})
.end

var recipe = _.like( target )
.also
({
  shell : null,
  after : null,
  before : null,
  pre : null,
  post : null,
})
.end

var recipeProcessed = _.like( recipe )
.also
({
  kind : '',
  beforeNodes : null,
})
.end

var Target =
{
  'target' : target,
  'recipe' : recipe,
  'recipe processed' : recipeProcessed,
}

// --
// relationship
// --

var optSymbol = Symbol.for( 'opt' );
var targetSymbol = Symbol.for( 'target' );

var Composes =
{
  defaultTargetName : null,
  usingLogging : 1,
  currentPath : null,
}

var Aggregates =
{
  opt : null,
  target : null,
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
  Target : Target,
}

// --
// proto
// --

var Proto =
{

  make : make,
  makeTarget : makeTarget,
  _makeTarget : _makeTarget,
  _makeTargetDependencies : _makeTargetDependencies,

  _targetName : _targetName,

  targetsAdjust : targetsAdjust,
  targetAdjust : targetAdjust,

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

_.protoMake
({
  constructor : Self,
  extend : Proto,
  parent : Parent,
});

wCopyable.mixin( Self );

 //

_.accessor( Self.prototype,
{
  opt : 'opt',
  target : 'target',
});

//

_global_[ Self.name ] = wTools[ Self.nameShort ] = Self;

})( );
