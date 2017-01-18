( function _Maker_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  if( typeof wBase === 'undefined' )
  try
  {
    require( '../include/BackTools.s' );
  }
  catch( err )
  {
  }

  if( typeof wBase === 'undefined' )
  try
  {
    require( '../include/wTools.s' );
  }
  catch( err )
  {
    require( 'wTools' );
  }

  if( !wTools.FileProvider  )
  try
  {
    require( '../include/amid/file/Files.ss' );
  }
  catch( err )
  {
    require( 'wFiles' );
  }

  if( !wTools.TemplateTree  )
  try
  {
    require( '../include/amid/mapping/TemplateTree.s' );
  }
  catch( err )
  {
    require( 'wTemplateTree' );
  }

  if( typeof wLogger === 'undefined' )
  try
  {
    require( '../include/abase/object/printer/printer/Logger.s' );
  }
  catch( err )
  {
    require( 'wLogger' );
  }

}

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

  if( !self.env )
  throw _.err( 'Maker expects ( env )' );
  if( !self.env.target )
  throw _.err( 'Maker expects ( env.target )' );
  if( !self.env.opt )
  throw _.err( 'Maker expects ( env.opt )' );

  /* */

  if( !self.currentPath )
  self.currentPath = _.pathMainDir();

  if( !self.fileProvider )
  self.fileProvider = _.FileProvider.HardDrive();

  if( !self.templateTree )
  self.templateTree = wTemplateTree({});

  /* */

  // logger.log( 'make' );
  // logger.log( 'process.argv :',process.argv );

  self.targetsAdjust();

  var nameOfTarget = process.argv[ 2 ] || 'all';

  self.makeTarget( nameOfTarget );

}

//

var makeTarget = function makeTarget( target )
{
  var self = this;
  var con = new wConsequence();

  if( _.strIs( target ) )
  target = self.env.target[ target ];

  // logger.log( 'making target',target.name,target );

  if( self.targetInvestigateUpToDate( target ) )
  {
    logger.log( 'Recipe',target.name,'is up to date' );
    return;
  }

  self._makeTargetAct( target );

}

//

var _makeTargetAct = function _makeTargetAct( target )
{
  var self = this;
  var con = new wConsequence().give();

  if( _.strIs( target ) )
  target = self.env.target[ target ];

  debugger;
  if( self.usingLogging )
  logger.logUp( 'making target',target.name );

  // if( self.usingLogging )
  // logger.log( target );
  // if( self.usingLogging )
  // logger.log( 'target.upToDate',target.upToDate );

  if( target.upToDate )
  {
    logger.logDown( '' );
    return con;
  }

  /* */

  for( var d in target.dependencies )
  {
    var dep = target.dependencies[ d ];

    // logger.log( 'dep.kind',dep.kind );

    if( dep.kind === 'recipe' )
    {
      con.ifNoErrorThen( _.routineSeal( self,self._makeTargetAct, [ dep ] ) );
    }
    else if( dep.kind === 'file' )
    {
      debugger;
      // logger.log( 'file',dep.filePath,self.pathesFor( dep.filePath ) );
      if( !self.fileProvider.fileStat( self.pathesFor( dep.filePath )[ 0 ] ) )
      throw _.err( 'not made :',dep.filePath );
    }
    else throw _.err( 'unknown target kind',target.kind );

  }

  /* */

  con
  .ifNoErrorThen( function()
  {
    if( target.shell )
    return _.shell( target.shell );
  })
  .thenDo( function( err,data )
  {
    if( self.usingLogging )
    logger.logDown( '' );
    if( err )
    throw _.errLogOnce( err );
  });

  return con;
}

//

var targetsAdjust = function targetsAdjust()
{
  var self = this;

  _.assert( _.objectIs( self.env.target ) );

  for( var t in self.env.target )
  {

    var target = self.env.target[ t ];

    if( target.target === undefined )
    target.target = t;

    self.targetAdjust( target );

  }

  self.templateTree.tree = self.env;
  self.env = self.templateTree.assignAndResolve( self.env );
  debugger;

}

//

var targetAdjust = function targetAdjust( target )
{
  var self = this;

  _.assert( _.strIs( target.target ) );
  _.assert( _.strIs( target.shell ) );
  _.assert( _.strIs( target.dep ) || _.arrayIs( target.dep ) );
  _.assert( target.kind === undefined );

  if( target.name === undefined )
  if( _.strIs( target.target ) )
  target.name = target.target;
  else if( _.arrayIs( target.target ) )
  target.name = target.target.join( ',' );
  else throw _.err( 'unknown type target',target.target );

  target.kind = 'recipe';

  target.dep = _.arrayFlatten( target.dep );

  target.dependencies = {};

  for( var d = 0 ; d < target.dep.length ; d++ )
  {
    var dep = target.dep[ d ];
    if( self.env.target[ dep ] )
    target.dependencies[ dep ] = self.env.target[ dep ];
    else
    target.dependencies[ dep ] = { kind : 'file', filePath : dep };
  }

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

  for( var d in target.dependencies )
  {
    var dep = target.dependencies[ d ];
    result = self.targetInvestigateUpToDate( dep,target ) && result;
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
    logger.log( '! targetInvestigateUpToDateFile',dst,':',result );
    return result;
  }

  var dst = self.pathesFor( recipe.target );
  var src = self.pathesFor( file.filePath );

  // logger.log( 'dst',dst );
  // logger.log( 'src',src );

  var result = self.fileProvider.filesIsUpToDate( dst,src );

  if( self.usingLogging )
  if( !result )
  logger.log( 'targetInvestigateUpToDateFile',dst,':',result );
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

// --
// relationship
// --

var Composes =
{
  usingLogging : 1,
  currentPath : null,
}

var Aggregates =
{
  // target : null,
  // param : null,
  env : null,
}

var Associates =
{
  fileProvider : null,
  templateTree : null,
}

var Restricts =
{
}

var Statics =
{
}

// --
// proto
// --

var Proto =
{

  make : make,
  makeTarget : makeTarget,
  _makeTargetAct : _makeTargetAct,

  targetsAdjust : targetsAdjust,
  targetAdjust : targetAdjust,

  targetInvestigateUpToDate : targetInvestigateUpToDate,
  targetInvestigateUpToDateRecipe : targetInvestigateUpToDateRecipe,
  targetInvestigateUpToDateFile : targetInvestigateUpToDateFile,


  // etc

  pathesFor : pathesFor,


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
});

//

_global_[ Self.name ] = wTools[ Self.nameShort ] = Self;

})( );
