/*
 * Delancey, a del.icio.us enhancement
 *
 * Copyright (C) 2005 DeWitt Clinton, All Rights Reserved
 *
 * This software is provided under the Creative Commons Attribution-ShareAlike
 * License.
 * 
 * http://www.unto.net/
 */
 

//
// Global Utility Functions
//

CLAIM_HEADER = 'X-Delancey-Claim';
DEBUG = 0;

// Build on Prototype's Event code

Object.extend( Event, {

  getKey: function( event )
  {
    var e = ( event ? event : window.event );
    return ( e.keyCode ? e.keyCode : e.which );
  },

  getTarget: function( event )
  {
    var e = ( event ? event : window.event );
    var t = ( e.target ? e.target : ( e.srcElement ? e.srcElement : null ) );
    return ( t ? ( ( t.nodeType == 3 ? t.parentNode : t ) ) : null );
  },

  isShift: function( event )
  {
    var e = ( event ? event : window.event );
    return e.shiftKey;
  },

  isTab: function( event )
  {
    return ( ( Event.getKey( event ) == Event.KEY_TAB ) && !Event.isShift( event ) );
  },

  isReturn: function( event )
  {
    return ( ( Event.getKey( event ) == Event.KEY_RETURN ) && !Event.isShift( event ) );
  }

} );


// Similar to Prototype's "$" function, but aware of frames

function $$() {
  switch( arguments.length )
  {
    case 1:
     var element = document.getElementById( arguments[0] );
     if ( !element )
     {
       throw new Error( "Couldn't find element '" + arguments[0] + 
                        "' in default frame." );
     }
     return element;
    case 2:
     if ( !window[arguments[0]] )
     {
       throw new Error( "Couldn't find frame: " + arguments[0] );
     }
     var element = window[arguments[0]].document.getElementById( arguments[1] );
     if ( !element )
     {
       throw new Error( "Couldn't find element '" + arguments[0] + 
                        "' in '" + arguments[0] + "' frame." );
     }
     return element;
    default:
     throw new Error( "Usage: %( [frame], id )" );
  }
}


// Fix for Safari bug in Position.cumulativeOffset
 
Position.cumulativeOffset = function( element ) 
{
  var valueT = 0, valueL = 0;
  do 
  {
    valueT += element.offsetTop  || 0;
    valueL += element.offsetLeft || 0;
    element = element.offsetParent;
  } 
  while ( element && ( element != document.body ) );
  return [ valueL, valueT ];
}


// Utility for finding the size of the viewport

Position.frameSize = function( )
{
  if ( self.innerWidth )
  {
    return [ self.innerWidth, self.innerHeight ];
  }
  else if ( document.documentElement && document.documentElement.clientWidth )
  {
    return [ document.documentElement.clientWidth, document.documentElement.clientHeight ];
  }
  else if ( document.body )
  {
    return [ document.body.clientWidth, document.body.clientHeight ];
  }
  else
  {
    throw new Error( "Can't get frame size" );
  }
}



//
// Main 
//

window.onload = start;
window.onerror = reportError;

function start( ) 
{
  if ( !browserIsCompatible( ) )
  {
    setTimeout( 'window.location = "http://www.unto.net/unto/get-firefox"', 0 );
    return;
  }

  try
  {
    DelanceyApplication.getInstance( ).start( );
  }
  catch ( e )
  {
    reportError( e );
  }
}

function reportError( e, url, line )
{
  var m = "Caught Error: ";

  if ( url && line )
  {
    m += e + " at line " + line + " in " + url;
  }
  else if ( e instanceof Error )
  {
    m += e.message + ":";
    m += '\n';
    for ( var p in e )
    {
      m += p + ": " + e[p] + "\n";
    }
  }
  else if ( e )
  {
    m += e;
  }
  else
  {
    m += "Unknown error";
  }
 
  if ( DEBUG )
  {
    debug( m );
  }
  else
  {
    alert( m );
  }

  return true;  
}

function end( )
{
  DelanceyApplication.getInstance( ).end( );
}

function browserIsCompatible( )
{
  return true;
}

function debug( m )
{
  if ( DEBUG && $( 'debug' ) )
  {
    $( 'debug' ).style.display = 'block';
    $( 'debug' ).innerHTML += '<div><pre>' + m + '</pre></div>';
  }
}

//
// @BookmarkDisplay Class
//

var BookmarkDisplay = Class.create( );

BookmarkDisplay.prototype = 
{
  SHORT_NAME_LENGTH: 124,
  MAX_ACCESS_KEYS: 15,

  initialize: function( div ) 
  { 
    if ( !div )
    {
      throw new Error( "Bookmarks div required" );
    }
    this.div = div;
    this.modified = true;
    this.visible = false;
    this.columns = [];
    Event.observe( window, "resize", this.onResize.bindAsEventListener( this ) );
  },

  clearBookmarks: function( )
  {
    this.bookmarks = null;
    this.modified = false;
    this.hide( );
  },

  setBookmarks: function( bookmarks )
  {    
    this.bookmarks = bookmarks;
    this.updateBookmarksArray( );
    this.modified = true;
  },

  updateBookmarksArray: function( )
  {
    this.bookmarksArray = this.toArray( this.bookmarks ).sort( this.bookmarkSort );
  },

  areBookmarksLoaded: function( )
  {
    return this.hasValues( this.bookmarks );
  },

  hasValues: function( hash )
  {
    if ( hash )
    { 
      for ( var i in hash )
      {
        return true;
      }
    }
    return false;
  },

  hide: function( )
  {
    this.visible = false;
    this.modified = true;
    this.render( );
  },
 
  reveal: function( )
  {
    this.visible = true;
    this.modified = true;
    this.render( );
  },


  render: function( )
  {
    if ( !this.modified )
    {
      return;
    }
    else if ( !this.hasValues( this.bookmarks ) )
    {      
      // TODO: return DelanceyApplication.getInstance( ).loadBookmarks( );
    }
    else if ( !this.visible )
    {
      this.div.style.display = 'none';
      this.modified = false;
    } 
    else
    {
      this.layout( );
      this.fill( );
      this.div.style.display = 'block';
      this.modified = false;
    }
  },
  
  layout: function( )
  {
    this.clear( );
    this.createColumns( );
  },

  getNumColumns: function( )
  {
    return 3;
  },

  createColumns: function( )
  {
    var numColumns = this.getNumColumns( );
    for ( var i = 0; i < numColumns; i++ )
    {    
      var column = document.createElement( 'ul' );
      this.columns.push( column );
      this.div.appendChild( column );
    }
  },

  fill: function( )
  {
    var numColumns = this.getNumColumns( );
    var lengths = this.getLengthsArray( numColumns );
    var numItems = this.bookmarksArray.length;
    var lastColumn = -1;
    this.accessKeys = [];
    this.now = DelanceyApplication.getInstance( ).getCurrentServerTime( );
    for ( var i = 0; i < numItems; i++ )
    {
      var thisColumn = 
        this.diagonalFill( i, lastColumn, numColumns, numItems, lengths );
      var bookmark = this.bookmarksArray[i];
      this.columns[thisColumn].appendChild( this.getBookmarkLi( i, bookmark ) );
      lengths[thisColumn]++;
      lastColumn = thisColumn;
    }
  },

  getLengthsArray: function( numColumns )
  {
    var lengths = [];
    for ( var i = 0; i < numColumns; i++ )
    {
      lengths.push( 0 );
    }
    return lengths;
  },

  getFillFunction: function( )
  {
    return this.boxFill;
  },

  // 1 2 3  fill in line, left to right
  // 4 5 6 
  // 7 8 9 

  leftToRightFill: 
    function( thisItem, lastColumn, numColumns, numItems, lengths )
  {
    return ( ( lastColumn + 1 ) % numColumns );
  },

  // 1 4 7  fill down each column, top to bottom
  // 2 5 8 
  // 3 6 9

  topToBottomFill: 
    function( thisItem, lastColumn, numColumns, numItems, lengths )
  {
    if ( lastColumn == -1 )
    {
      return 0;
    }
    else if ( lengths[lastColumn] >= ( numItems / numColumns ) )
    {
      return lastColumn + 1;
    }
    else
    {
      return lastColumn;
    }
  },

  // 1 3 6 fill diagonally bottom left to top right
  // 2 5 8
  // 4 7 9 

  diagonalFill: function( thisItem, lastColumn, numColumns, numItems, lengths )
  {
    var right = Math.min( numColumns, Math.max( 1, lengths[0] ) );
    var thisColumn = ( lastColumn + 1 ) % right;
    var maxHeight = Math.ceil( numItems / ( right ) );
    while ( lengths[thisColumn] == maxHeight )
    {
      thisColumn++;
    }
    this.assert( thisColumn < numColumns, "thisColumn < numColumns" );
    this.assert( thisColumn >= 0, "thisColumn >= 0" );
    return thisColumn;
  },

  // 1 3 6  fill nearest to the origin
  // 2 4 8  
  // 5 7 9   

  boxFill: function( thisItem, lastColumn, numColumns, numItems, lengths )
  {
    var right = Math.min( numColumns, Math.max( 1, lengths[0] ) );
    var thisColumn = ( lastColumn + 1 ) % right;
    for ( var i = 0; i < right; i++ )
    {
      if ( lengths[i] < lengths[thisColumn] )
      {
        return i;
      }
    }

    this.assert( right > 0, "right > 0" );
    this.assert( right <= numColumns, "right <= numColumns" );
    this.assert( thisColumn < right, "thisColumn < right" );
    this.assert( thisColumn < numColumns, "thisColumn < numColumns" );
    this.assert( thisColumn >= 0, "thisColumn >= 0" );
    return thisColumn;
  },
        
  assert: function( b, message )
  {
    if ( !b )
    {
      throw new Error( message );
    }
  },

  getBookmarkLi: function( position, bookmark )
  {
    var li = document.createElement( 'li' );
    var a = this.getLinkAnchor( position, bookmark );
    li.appendChild( a );
    li.appendChild( this.getInfoSpan( a, bookmark ) );
    return li;
  },

  getLinkAnchor: function( position, bookmark )
  {
    var a = document.createElement( 'a' );
    if ( !bookmark.h )
    {
      throw new Error( "Bookmark for " + bookmark.u + " lacks a hash" );
    }
    a.display = this;
    a.id = bookmark.h;
    a.className = 'bookmark';
    a.href= bookmark.u;
    a.title = bookmark.d;
    a.shortName = bookmark.s;
    var linkText = this.getLinkText( bookmark.s, bookmark.d );
    var accessKey = this.getAccessKey( position, linkText );
    if ( accessKey ) 
    {
      a.accessKey = accessKey;
      linkText = this.highlightFirstCharacter( accessKey, linkText );
    }
    a.onclick = function( ) 
    { 
      return DelanceyApplication.getInstance( ).bookmarkDisplay.onIncrement( a ); 
    }    
    a.onmousedown = function( ) 
    { 
      return DelanceyApplication.getInstance( ).bookmarkDisplay.onIncrement( a ); 
    }    
    a.innerHTML = linkText;
    return a;
  },

  getInfoSpan: function( a, bookmark )
  {
    var infoSpan = document.createElement( 'span' );
    infoSpan.className = 'info-span'; 
    infoSpan.appendChild( this.getCountSpan( a, bookmark ) );
    infoSpan.appendChild( this.getLastClickSpan( a, bookmark ) );
    return infoSpan;
  },

  getCountSpan: function( a, bookmark )
  {
    var countSpan = document.createElement( 'span' );
    countSpan.className = 'count';
    countSpan.innerHTML = this.getCountText( bookmark.c );
    countSpan.title = 'Click here to edit bookmark name';
    countSpan.onclick = function( ) 
    { 
      return DelanceyApplication.getInstance( ).bookmarkDisplay.onEdit( a ); 
    }
    return countSpan;
  },

  getCountText: function( count )
  {
    switch( count )
    {
      case 0:
        return 'No clicks';
      case 1:
        return '1 click';
      default:
        return count + ' clicks';
    }
  },

  getLastClickSpan: function( a, bookmark )
  {
    var lastClickSpan = document.createElement( 'span' );
    if ( this.now && bookmark.l ) 
    {
      lastClickSpan.innerHTML = this.getLastClickText( this.now - bookmark.l );
      lastClickSpan.style.color = this.getLastClickColor( this.now - bookmark.l );
    }
    lastClickSpan.className = 'last-clicked';
    return lastClickSpan;
  },

  getLastClickText: function( delta )
  {
    delta = Math.floor( delta );

    if ( delta < 0 )
    {
      return '';
    }
    else if ( delta == 0 )
    {
      return 'Now';
    }
    else if ( delta < ( 60 ) )
    {
      return '+' + delta + 's';
    }
    else if ( delta < ( 60 * 60 ) )
    {
      return '+' + Math.floor( delta / 60 ) + 'm';
    }
    else if ( delta < ( 60 * 60 * 24 ) )
    {
      return '+' + Math.floor( delta / ( 60 * 60 ) ) + 'h';
    }
    else if ( delta < ( 60 * 60 * 24 * 7 ) )
    {
      return '+' + Math.floor( delta / ( 60 * 60 * 24 ) ) + 'd';
    }
    else if ( delta < ( 60 * 60 * 24 * 7 * 52 ) )
    {
      return '+' + Math.floor( delta / ( 60 * 60 * 24 * 7 ) ) + 'w';
    }
    else
    {
      return '+' + Math.floor( delta / ( 60 * 60 * 24 * 7 * 52 ) ) + 'y';
    }
  },

  getLastClickColor: function( delta )
  {
    return this.getColorFromRange( delta, 0, ( 60 * 60 * 24 * 7 ), '#7777FF', '#DDDDDD' );
  },

  getColorFromRange: function( value, min, max, lowColor, highColor )
  {
    if ( min > max )
    {
      var temp = min;
      min = max;
      max = temp;
    }

    value = Math.max( Math.min( value, max ), min );
    
    var lowRgb = this.rgbToArray( lowColor );
    var highRgb = this.rgbToArray( highColor );
   
    if ( !lowRgb || !highRgb || ( lowRgb.length != 3 ) || ( highRgb.length != 3 ) )
    {
      return '#000000';
    }
  
    var arr = [];

    for ( var i = 0; i < lowRgb.length; i++ )
    {
      arr.push( Math.floor( 
       ( ( ( value - min ) * ( highRgb[i] - lowRgb[i] ) ) / ( max - min ) ) + lowRgb[i] ) );
    }
    
    return this.arrayToRgb( arr );
  },


  rgbToArray: function( rgb )
  {
    if ( !rgb ) 
    {
      return null;
    }
    rgb = rgb.toLowerCase( );
    rgb = rgb.replace( /[^0-9a-f]/, '' );
 
    if ( rgb.length == 3 )
    {
      rgb = rgb[0] + rgb[0] + rgb[1] + rgb[1] + rgb[2] + rgb[2];
    }

    if ( rgb.length != 6 )
    {
      return null;
    }
    
    return [ parseInt( rgb.substring( 0, 2 ), 16 ), 
             parseInt( rgb.substring( 2, 4 ), 16 ), 
             parseInt( rgb.substring( 4, 6 ), 16 ) ];
  },  

  arrayToRgb: function( arr )
  {
    if ( !arr || ( arr.length != 3 ) )
    {
      return '#000000';
    }
    
    var rgb = '#';
    
    for ( var i = 0; i < arr.length; i++ )
    {
      var c = arr[i].toString(16);
      rgb += c.length < 2 ? '0' + c : c;
    } 

    return rgb;
  },

  getAccessKey: function( position, text )
  {
    if ( position > this.MAX_ACCESS_KEYS )
    {
      return null;
    }
    for ( var i = 0; i < text.length; i++ )
    {
      if ( text[i] )
      {
        var c = text[i].toLowerCase( );
        if ( c.match( /\w/ ) && !this.accessKeys[c] )
        {
          this.accessKeys[c] = true;
          return text[i];
        }
      }
    }
    return null;
  },

  highlightFirstCharacter: function( c, s )
  {
    return s.replace( new RegExp( c, "i" ), 
      '<span style="text-decoration: underline">' + c + '</span>' );
  },

  getLinkText: function( shortName, longName )
  {
    var text = shortName ? shortName : longName;
    if ( text.length > this.SHORT_NAME_LENGTH )
    {
      text = text.substr( 0, this.SHORT_NAME_LENGTH ) + '&#133;';
    }
    return text;
  },

  onEdit: function( a )
  {
    if ( a.input ) 
    {
      return this.onEditBlur( a );
    }
    var input = document.createElement( 'input' );
    input.type = 'text';
    input.value = a.shortName ? a.shortName : a.title;
    input.style.width = Math.max( 40, a.offsetWidth ) + 'px';
    input.onblur = function( event ) 
    { 
      return DelanceyApplication.getInstance( ).bookmarkDisplay.onEditBlur( a ); 
    };
    input.onkeydown = function( event )
    {
      if ( Event.isReturn( event ) || Event.isTab( event ) )
      {
        return DelanceyApplication.getInstance( ).bookmarkDisplay.onEditBlur( a );
      }
    }
    a.input = input;
    a.oldDisplay = a.style.display;
    a.style.display = 'none';
    a.parentNode.insertBefore( input, a );
    return false;
  },

  onEditBlur: function( a )
  {
    if ( !a.input )
    {
      return false;
    }
    var username = DelanceyApplication.getInstance( ).getUsername( );
    if ( !username )
    {
      return DelanceyApplication.getInstance( ).promptForUsername( );
    }

    if ( ( a.input.value == a.title ) || !a.input.value )
    {
      a.shortName = null;
      a.innerHTML = this.getLinkText( shortName, a.title );
      this.sendShortname( username, a.id );
    }
    else if ( a.input.value != a.shortName )
    {
      var shortName = a.input.value ? a.input.value : a.title;
      a.shortName = shortName;
      a.innerHTML = this.getLinkText( shortName, a.title );
      this.sendShortname( username, a.id, shortName );
    }

    a.style.display = a.oldDisplay;
    a.input.parentNode.removeChild( a.input );
    a.input = null;
  },

  sendShortname: function( username, hash, shortName )
  {
    var usernameHash = hex_md5( username );
    var url = DelanceyApplication.getInstance( ).getBaseUrl( ) + 
      "/shortname/" + usernameHash + '/' + hash + '/' + ( shortName ? encodeURIComponent( shortName ) : '' );
    new Ajax.Request( url, { method: 'post', asynchronous: true } );
  },
  
  onResize: function( event )
  {
    this.modified = true;
    this.render( );
    return false;
  },

  clear: function( )
  {
    this.div.innerHTML = '';
    this.columns = [];
  },

    
  toArray: function( hash )
  {
    var array = [];
    for ( h in hash )
    {
      array.push( hash[h] );
    }
    return array;
  },

  bookmarkSort: function( left, right )
  {
    return ( left.c == right.c ) ?
           ( ( ( left.s ? left.s.toUpperCase( ) : left.d.toUpperCase( ) ) > 
               ( right.s ? right.s.toUpperCase( ) : right.d.toUpperCase( ) ) ) ?
                1 : -1 ) :
           ( right.c - left.c );
  },

  onIncrement: function( a )
  { 
    if ( a.clicked )
    {
      return; // already counted
    }

    if ( !a )
    {
      throw new Error( "Element 'a' required" );
    }

    if ( !a.id ) 
    {
      throw new Error( "No id" );
    }

    var username = DelanceyApplication.getInstance( ).username;
    if ( !username )
    {
      throw new Error( "No username" );
    }
    this.sendPostIncrement( username, a.id );
    this.bookmarks[a.id].c++;
    this.bookmarks[a.id].l = DelanceyApplication.getInstance( ).getCurrentServerTime( );
    this.updateBookmarksArray( );
    this.modified = true;
    setTimeout( 'DelanceyApplication.getInstance( ).bookmarkDisplay.render( )', 1000 );
    a.clicked = true;
    return true;
  },

  sendPostIncrement: function( username, hash )
  {
    var usernameHash = hex_md5( username );
    var url = DelanceyApplication.getInstance( ).getBaseUrl( ) + 
      "/increment/" + usernameHash + '/' + hash + '/';
    new Ajax.Request( url, { method: 'post', asynchronous: true } );
  }
};


//
// @AutocompleteBox Class
//

AutocompleteBox = Class.create( );

AutocompleteBox.prototype = 
{
  max_autocomplete: 15,

  initialize: function( input, originalValues, submitFunction )
  {
    if ( !input )
    {
      throw new Error( "input required" );
    }
    if ( !submitFunction )
    {
      throw new Error( "submit function required" );
    } 
    this.input = input;
    this.input.setAttribute( 'autocomplete', 'off' );
    this.box = this.createBox( this.input );
    this.originalValues = originalValues;
    this.filteredValues = [];
    this.submitFunction = submitFunction;
    this.addObservers( this.input );
  },

  enable: function( )
  {
    this.disabled = false;
    this.drawBox( );
  },

  disable: function( )
  {
    this.disabled = true;
    this.hideBox( );
  },

  setValues: function( values )
  {
    this.originalValues = values;
    this.updateFilteredValues( );
  },

  createBox: function( input )
  {
    var box = document.createElement( 'div' );
    box.className = 'autocomplete';
    box.style.display = 'none';
    input.parentNode.insertBefore( box, input );
    return box;
  },

  addObservers: function( input )
  {
    Event.observe( input,
                   "keyup",
                   this.onKeyUp.bindAsEventListener( this ) );

    Event.observe( input,
                   "keypress",
                   this.onKeyPress.bindAsEventListener( this ) );

    Event.observe( input,
                   "focus",
                   this.onFocus.bindAsEventListener( this ) );

    Event.observe( input,
                   "blur",
                   this.onBlur.bindAsEventListener( this ) );
  },

  getInput: function( inputName )
  {
    var input = $( inputName );
    if ( !input )
    {
      throw new Error( "Couldn't find " + inputName );
    }
    return input;
  },

  onFocus: function( event )
  {
    this.enable( );
    this.drawBox( );
    return false;
  },

  onBlur: function( event )
  {
    this.disable( );
    this.hideBox( );
    return false;
  },

  onKeyPress: function( event )
  {
    if ( Event.isTab( event ) || 
         Event.isReturn( event ) ||
         ( Event.getKey( event ) == Event.KEY_RIGHT ) )
    {
      this.completeCurrent( );
      Event.stop( event );
      return false;
    }
    else if ( Event.getKey( event ) == Event.KEY_DOWN )
    {
      this.unhighlightSelected( );
      this.selectNext( );
      this.highlightSelected( );
      Event.stop( event );
      return false;
    }
    else if ( Event.getKey( event ) == Event.KEY_UP )
    {
      this.unhighlightSelected( );
      this.selectPrevious( );
      this.highlightSelected( );
      Event.stop( event );
      return false;
    }

    return true;
  },

  onKeyUp: function( event )
  {
    if ( Event.getKey( event ) == Event.KEY_ESC )
    {
      this.hideBox( );
    }
    else if ( ( Event.getKey( event ) == Event.KEY_DOWN ) || 
              ( Event.getKey( event ) == Event.KEY_UP ) )
    {
      return false;
    }
    else
    {
      this.drawBox( );
    }

    return true;
  },

  insertAfter: function( newElement, targetElement )
  {
    if ( targetElement.nextSibling )
    {
      targetElement.nextSibling.parentNode.insertBefore( newElement, 
        targetElement.nextSibling );
    }
    else
    {
      targetElement.parentNode.appendChild( newElement );
    }
  },

  drawBox: function( )
  {
    this.updateFilteredValues( );
    
    if ( !this.disabled && this.filteredValues && this.filteredValues.length >= 1 )
    {
      this.positionBox( );
      this.removeChildNodes( this.box );
      this.box.appendChild( this.getBoxItemsUl( this.filteredValues ) );
      this.unhighlightSelected( );
      this.selectFirst( );
      this.highlightSelected( );
    }
    else
    {
      this.hideBox( );
    }
  },

  hideBox: function( )
  {
    this.box.style.display = 'none';
  },

  removeChildNodes: function ( element )
  {
    if ( !element || !element.hasChildNodes( ) )
    {
      return;
    }

    var childNodes = element.childNodes;

    for ( var i = 0; i < childNodes.length; i++ )
    {
      element.removeChild( childNodes.item(i) );
    }
  },

  positionBox: function( )
  {
    var frameSize = Position.frameSize( );
    var inputOffset = Position.cumulativeOffset( this.input );
//    if ( inputOffset[1] > ( frameSize[1] / 2 ) )
//    {
      this.box.style.bottom = ( frameSize[1] - inputOffset[1] ) + 'px';
//    }
//    else
//    {
//      this.box.style.top = ( inputOffset[1] + this.input.offsetHeight ) + 'px';
//    }
    this.box.style.left = inputOffset[0] + 'px';
    this.box.style.width = ( this.input.offsetWidth - 2 ) + 'px';
    this.box.style.position = this.hasBug167801( ) ? 'fixed' : 'absolute';
    this.box.style.display = 'block';
  },

  // https://bugzilla.mozilla.org/show_bug.cgi?id=167801
 
  hasBug167801: function( )
  {
    return navigator.userAgent.match( /Gecko/ );
  },

  updateFilteredValues: function( )
  {
    var prefix = this.input.value || '';
    var filteredValues = [];
    var originalValues = this.originalValues || [];
    var count = 0;

    for ( var i = 0; i < originalValues.length; i++ )
    {
      if ( this.startsWith( originalValues[i], prefix ) )
      {
        filteredValues.push( originalValues[i] );
        if ( ++count >= this.max_autocomplete )
        {
          break;
        }
      }
    }

    this.filteredValues = filteredValues;
    this.selectFirst( );
  },
  
  startsWith: function( haystack, needle )
  {
    return ( '' + haystack ).toUpperCase( ).indexOf( ( '' + needle ).toUpperCase( ) ) === 0;
  },

  getBoxItemsUl: function( values )
  {
    var ul = document.createElement( 'ul' );

    if ( !values )
    {
      return ul;
    }

    for ( var i = 0; i < values.length; i++ )
    {
      var li = document.createElement( 'li' );
      li.setAttribute( 'position', i );
      li.innerHTML = values[i];
      Event.observe( li, "mouseover", 
        this.onMouseOver.bindAsEventListener( this ) );
      Event.observe( li, "mousedown", 
        this.onMouseDown.bindAsEventListener( this ) );
      ul.appendChild( li );
    }

    return ul;
  },

  onMouseOver: function( event )
  {
    this.unhighlightSelected( );
    this.selected = Event.element( event );
    this.highlightSelected( );
    return true;
  },

  onMouseDown: function( event )
  {
    this.completeCurrent( );
    this.disable( );
    this.submitFunction( );
    return true;
  },

  completeCurrent: function( )
  {
    if ( this.selected && 
         this.selected.innerHTML &&
         ( this.selected.innerHTML.indexOf( this.input.value ) > -1 ) )
    {
      this.input.value = this.selected.innerHTML;
    }
  },
 
  unhighlightSelected: function( )
  {
    if ( this.selected )
    {
      this.selected.className = ''; 
    }
  },

  highlightSelected: function( )
  {
    if ( this.selected )
    {
      this.selected.className = 'autocomplete-selected';
    }
  },

  selectFirst: function( )
  {
    if ( this.selected )
    {
      this.selected.className = '';
    }
    var liNodes = this.box.getElementsByTagName( 'li' );
    if ( liNodes && ( liNodes.length > 0 ) )
    {
      this.selected = liNodes[0];
    }
  },

  selectNext: function( )
  {
    if ( this.selected && this.selected.nextSibling )
    {
      this.selected.className = '';
      this.selected = this.selected.nextSibling;
    }
    else
    {
      this.selectFirst( );
    }
  },

  selectPrevious: function( )
  {
    if ( this.selected && this.selected.previousSibling )
    {
      this.selected.className = '';
      this.selected = this.selected.previousSibling;
    }
    else
    {
      this.selectLast( );
    }
  },

  selectLast: function( )
  {
    var liNodes = this.box.getElementsByTagName( 'li' );
    if ( liNodes && ( liNodes.length > 0 ) )
    {
      this.selected = liNodes[liNodes.length - 1];
    }
  }
};


//
// @ToggledLink Class
//

var ToggledLink = Class.create( );

ToggledLink.prototype =
{
  initialize: function( element )
  {
    if ( !element )
    {
      throw new Error( "ToggledLink element required" );
    }
    this.element = element;
  },

  setHref: function( href )
  {
    this.element.href = href;
    if ( !href )
    {
      this.disable( );
    }
  },

  setText: function( text )
  {
    this.element.innerHTML = text;
  },

  setClassName: function( name )
  {
    this.element.className = name;
  },

  enable: function( )
  {
    if ( !this.element.parentNode ) 
    {
      throw new Error( 'Element ' + this.element + ' is an orphan' );
    }
    if ( ( this.element.nodeName == 'a' ) || ( !this.element.href ) )
    {
      return;
    }
    var a = document.createElement( 'a' );
    a.href = this.element.href;
    a.id = this.element.id;
    a.title = this.element.title;
    a.innerHTML = this.element.innerHTML;
    a.className = this.element.className;
    this.element.parentNode.insertBefore( a, this.element );
    this.element.parentNode.removeChild( this.element );
    this.element = a;
  },

  disable: function( )
  {
    if ( !this.element.parentNode ) 
    {
      throw new Error( 'Element ' + this.element + ' is an orphan' );
    }
    if ( this.element.nodeName == 'span' )
    {
      return;
    }
    var span = document.createElement( 'span' );
    span.href = this.element.href;
    span.id = this.element.id;
    span.title = this.element.title;
    span.innerHTML = this.element.innerHTML;
    span.className = this.element.className;
    this.element.parentNode.insertBefore( span, this.element );
    this.element.parentNode.removeChild( this.element );
    this.element = span;
  }
}


//
// @TextInput Class
//

var TextInput = Class.create( );

TextInput.prototype =
{
  invalidRegex: /[^\w]/,

  initialPromptMessage: 'Please enter a value.',

  promptMessage: 'Please hit return when done.',

  invalidMessage: 'Illegal characters.',

  initialize: function( input, messageBox )
  {
 
    this.initializeInput( input );
    this.initializeMessageBox( messageBox );
    this.initializeEvents( );
  },
  
  initializeInput: function( input )
  {
    if ( !input )
    {
      throw new Error( "input required" );
    }
    this.input = input;
  },
 
  initializeMessageBox: function( messageBox )
  {
    if ( !messageBox )
    {
      throw new Error( "messageBox undefined" );
    }
    this.messageBox = messageBox;
  },

  // Assign the instance of TextInput (or subclass) to the
  // target element's "textInput" property.  When the event
  // fires, pass it off to the appropriate handler inside
  // the textInput instance.

  initializeEvents: function( )
  {
    this.input.textInput = this;

    this.input.onkeypress = function( event ) 
    { 
      return !Event.isTab( event );
    };

    this.input.ondown = function( event ) 
    { 
      return !Event.isTab( event );
    };

    this.input.onkeyup = function( event ) 
    {
      return this.textInput.edit( this, event );
    };

    this.input.onfocus = function( event ) 
    { 
      return this.textInput.edit( this, event );
    };
  },

  focus: function( )
  {
    this.input.focus( );
    if ( this.input.select )
    {
      this.input.select( );
    }
  },

  isSubmitEvent: function( event )
  {
    return Event.isTab( event ) || Event.isReturn( event );
  },

  edit: function( element, event )
  {
    if ( !this.preconditionsMet( ) )
    {
      return false;
    }
    if ( !this.input.value )
    {
      this.instruction( this.initialPromptMessage );
    }
    else if ( this.isInvalid( this.input.value ) )
    {
      this.error( this.invalidMessage );
    }
    else if ( this.isSubmitEvent( event ) )
    {
      this.submit( element, event );
    }
    else
    {
      this.instruction( this.promptMessage );
    }
    return false;
  },
  
  preconditionsMet: function( )
  {
    return true; // can be overridden
  },

  submit: function( element, event )
  {
    throw new Error( "TextInput abstract submit method not implemented" );
  },

  isInvalid: function( string )
  {
    return string && string.match( this.invalidRegex );
  },

  error: function( message )
  { 
    this.messageBox.error( message );
  },

  notice: function( message )
  { 
    this.messageBox.notice( message );
  },

  instruction: function( message )
  { 
    this.messageBox.instruction( message );
  },

  enable: function( )
  {
    this.input.disabled = '';
  },
 
  disable: function( )
  {
    this.input.blur( );
    this.input.disabled = 'true';
  }
};


//
// A note on prototype.js's Object.extend:
//
// To truly subclass a class, you must first copy the entire superclass
// into the subclass prototype.  Then you must overwrite the methods
// selectively.  Hence the awkward two-pass Object.extend.  
//

//
// @UsernameInput Class
//

var UsernameInput = Class.create( );

UsernameInput.prototype = 
  Object.extend( Object.extend( UsernameInput.prototype, 
                                TextInput.prototype ),
{
  invalidRegex: /[^\w\.]/,

  initialPromptMessage: "Please enter your del.icio.us username.",

  initialize: function( messageBox )
  {
    this.initializeInput( $$( 'username' ) );
    this.initializeMessageBox( messageBox );
    this.initializeEvents( );
  },

  submit: function( element, event )
  {
    var username = this.input.value;

    if ( username && !this.isInvalid( username ) )
    {
      DelanceyApplication.getInstance( ).loadTagList( );
    }
    else
    {
      this.error( "Username not complete." );
    }
  }
} );



//
// @TagInput Class
//

var TagInput = Class.create( );

TagInput.prototype = 
  Object.extend( Object.extend( TagInput.prototype,
                                TextInput.prototype ), 
{
  tagValues: [],

  initialPromptMessage: "Please enter a del.icio.us tag.",

  invalidRegex: /[^\w\:\.\-\!\@\*\%\,\+]/,

  initialize: function( messageBox )
  {
    this.initializeInput( $$( 'tag' ) );
    this.initializeMessageBox( messageBox );
    this.initializeEvents( );
    this.initializeAutocompleteBox( );
  },

  initializeAutocompleteBox: function( )
  {
    this.autocompleteBox = new AutocompleteBox( $$( 'tag' ), [], this.submit );
  },

  preconditionsMet: function( )
  {
    if ( !DelanceyApplication.getInstance( ).getUsername( ) )
    {
      return DelanceyApplication.getInstance( ).promptForUsername( );
    }
    else if ( !this.isTagListLoaded( ) )
    {
      return DelanceyApplication.getInstance( ).loadTagList( );
    }
    else
    {
      return true;
    }
  },

  submit: function( )
  {
    return DelanceyApplication.getInstance( ).loadBookmarks( );
  },

  getTagList: function( )
  {
    return this.tagList;
  },

  setTagList: function( tagList )
  {
    this.tagList = tagList;
    var tagValues = [];
    for ( var i = 0; i < tagList.length; i++ )
    { 
      tagValues.push( tagList[i].t );
    }
    this.autocompleteBox.setValues( tagValues );
    this.autocompleteBox.enable( );
  },

  clearTagList: function( )
  {
    this.tagList = null;
    this.autocompleteBox.setValues( [ ] );
  },

  isTagListLoaded: function( )
  {
    return ( this.tagList && ( this.tagList.length > 0 ) );
  }

} );


//
// @MessageBox Class
//

var MessageBox = Class.create( );

MessageBox.prototype =
{
  initialize: function( box )
  {
    this.initializeBox( box );
  },

  initializeBox: function( box )
  {  
    if ( !box )
    {
      throw new Error( "Message box div required" );
    }
    this.box = box;
  },

  setMessage: function( message, className )
  {
    if ( ( this.box.innerHTML != message ) || 
         ( this.box.style.className != className ) )
    {
      this.box.innerHTML = message;
      this.box.className = className;
    }
  },

  error: function( message )
  {
    this.setMessage( message, 'error-message' );    
  },

  notice: function( message )
  {
    this.setMessage( message, 'notice-message' );    
  },

  instruction: function( message )
  {
    this.setMessage( message, 'instruction-message' );    
  },

  append: function( message )
  {
    this.box.innerHTML += message;
  }
};


//
// @ProgressBar Class
//

var ProgressBar = Class.create( );

ProgressBar.prototype =
{
  initialize: function( messageBox )
  {
    this.messageBox = messageBox;
    if ( !this.messageBox )
    {
      throw Error( "messageBox required" );
    }
  },

  start: function( message, updatePeriod, timeoutPeriod, timeoutFunction )
  {
    if ( this.updateInterval || this.timeout || this.message || this.timeoutFunction )
    {
      this.stop( );
    }
    this.message = message;
    this.updateInterval = setInterval( this.onupdate.bind( this ), updatePeriod );
    this.timeoutFunction = timeoutFunction;
    this.timeout = setTimeout( this.ontimeout.bind( this ), timeoutPeriod );
    DelanceyApplication.getInstance( ).hideWelcome( );
    this.reveal( );
  },

  stop: function( )
  {
    if ( this.updateInterval )
    {
      clearInterval( this.updateInterval );
      this.updateInterval = null;
    }
    if ( this.timeout )
    {
      clearTimeout( this.timeout );
      this.timeout = null;
    }
    if ( this.timeoutFunction )
    {
      this.timeoutFunction = null;
    }
    this.hide( );
  },

  reveal: function( )
  {
    if ( this.message )
    {
      this.messageBox.notice( this.message );
    }
  },

  hide: function( )
  {
    this.messageBox.notice( 'Completed.' );
  },

  onupdate: function( )
  {
    this.messageBox.append( ' . ' );
  },

  ontimeout: function( )
  {
    this.stop( );
    if ( this.timeoutFunction )
    {
      this.timeoutFunction( );
    }
  }
};


//
// @PasswordDialog Class
//

var PasswordDialog = Class.create( );

PasswordDialog.prototype =
{
  initialize: function( element )
  {
    this.initializeElement( element );
    this.initializeOriginalHtml( );
  },

  initializeElement: function( element )
  {
    this.element = element;
    if ( !this.element )
    {
      throw new Error( "element required" ); 
    }
  },


  initializeOriginalHtml: function( )
  {
    this.originalHtml = this.element.innerHTML;
    if ( !this.originalHtml )
    {
      throw Error( "Password element had no HTML" );
    }
  },

  updateForm: function( )
  {
    this.form = this.element.getElementsByTagName( 'form' )[0];
    if ( !this.form )
    {
      throw Error( "Couldn't find form element." );
    }
  },

  updatePasswordInput: function( )
  {
    this.input = this.form.getElementsByTagName( 'input' )[0];
    if ( !this.input )
    {
      throw Error( "Couldn't find password input element." );
    }
  },
  
  updateHtml: function( username )
  {
    if ( !username )
    {
      throw new Error( "Username required" );
    }
    var html = this.originalHtml;
    html = html.replace( /%username/g, username );
    this.element.innerHTML = html;
  },

  hide: function( )
  {
    this.element.style.display = 'none';
  },

  reveal: function( username )
  {
    this.updateHtml( username );
    this.updateForm( );
    this.updatePasswordInput( );
    DelanceyApplication.getInstance( ).disableAllInput( );
    Event.observe( this.form, "submit", this.onSubmit.bindAsEventListener( this ) );
    Event.observe( this.form, "reset", this.onReset.bindAsEventListener( this ) );
    this.element.style.display = 'block';
    Form.focusFirstElement( this.form );
  },

  onSubmit: function( event )
  {
    Event.stop( event );

    if ( this.input.value )
    { 
      DelanceyApplication.getInstance( ).setPassword( this.input.value );
      this.hide( );
      DelanceyApplication.getInstance( ).promptForUsername( );
    }
    else
    {   
      Form.focusFirstElement( this.form );
    }

    return true;
  },

  onReset: function( event )
  {
    Event.stop( event );
    DelanceyApplication.getInstance( ).clear( );
    return true;
  }
};


//
// @DelanceyApplication Class
//

var DelanceyApplication = Class.create( );

DelanceyApplication.prototype = 
{
  USERNAME_COOKIE: 'delancey-username',
  TAG_COOKIE: 'delancey-tag',
  PASSWORD_COOKIE: 'delancey-password',
  REQUEST_TIMEOUT: 60000,

  // initialization functions

  initialize: function( )
  {  
    this.initializeTime( );
    this.initializeBaseUrl( );
    this.initializeMessageBox( );
    this.initializeUsernameInput( );
    this.initializeTagInput( );
    this.initializeLoginForm( );
    this.initializePermalink( );
    this.initializeClearButton( );
    this.initializeClaimButton( );
    this.initializeBookmarklet( );
    this.initializeProgressBar( );
    this.initializeContentDiv( );
    this.initializePasswordDialog( );
    this.initializeBookmarkDisplay( );
    this.initializeWelcome( );
  },

  start: function( )
  {
    this.restoreState( );
    this.updateState( );
    this.bookmarkDisplay.reveal( );
  },

  end: function( )
  {

  },

  initializeTime: function( )
  {
    this.clientTime = ( new Date( ) ).getTime( ) / 1000;
    this.serverTime = serverTime || this.clientTime;
    this.timeDelta = this.clientTime - this.serverTime;    
  },

  initializeBaseUrl: function( )
  {
    if ( !window.baseUrl )
    {
      throw new Error( "Base URL unavailable" );
    }
    this.setBaseUrl( baseUrl );
  },

  initializeMessageBox: function( )
  {
    this.messageBox = new MessageBox( $$( 'message-box' ) );
    if ( !this.messageBox )
    {
      throw new Error( "Couldn't initialize MessageBox" );
    }
    this.messageBox.notice( "Welcome to Delancey." );
  },


  initializeUsernameInput: function( )
  {
    this.usernameInput = new UsernameInput( this.messageBox );
    if ( !this.usernameInput )
    {
      throw new Error( "Couldn't initialize UsernameInput" );
    }
  },

  initializeTagInput: function( )
  {
    this.tagInput = new TagInput( this.messageBox );
    if ( !this.tagInput )
    {
      throw new Error( "Couldn't initialize TagInput" );
    }
  },

  initializeLoginForm: function( )
  {
    var loginForm = $$( 'login-form' );
    if ( !loginForm )
    {
      throw new Error( "Couldn't find login form" );
    }
    loginForm.onsubmit = function( event ) { return false; };
    loginForm.action = '';
  },

  initializePermalink: function( )
  {
    this.permalink = $$( 'permalink' );
    if ( !this.permalink )
    {
      throw new Error( "Couldn't find permalink" );
    }
  },

  initializeClearButton: function( )
  {
    this.clearButton = new ToggledLink( $$( 'clear' ) );
    this.clearButton.enable( );
  },

  initializeClaimButton: function( )
  {
    this.claimButton = new ToggledLink( $$( 'claim' ) );
  },

  initializeBookmarklet: function( )
  {
    this.bookmarklet = new ToggledLink( $$( 'bookmarklet' ) );
    this.bookmarklet.disable( );
  },

  initializeContentDiv: function( )
  {
    this.resizeContent( );
    Event.observe( window, "resize", this.resizeContent.bindAsEventListener( this ) );
  },

  resizeContent: function( )
  { 
    var header = $$( 'header' );
    var content = $$( 'content' );
    var footer = $$( 'footer' );
    var frameSize = Position.frameSize( );
    content.style.top = header.offsetHeight + 'px';
    content.style.bottom = footer.offsetHeight + 'px';
    content.style.height = ( frameSize[1] - ( header.offsetHeight + footer.offsetHeight ) ) + 'px';
  },

  initializeBookmarkDisplay: function( )
  {
    this.bookmarkDisplay = new BookmarkDisplay( $$( 'bookmarks' ) );
  },

  initializeWelcome: function( )
  {
    this.welcome = $$( 'welcome' );
  },

  initializeProgressBar: function( )
  {
    this.progressBar = new ProgressBar( this.messageBox );
    if ( !this.progressBar )
    {
      throw new Error( "Couldn't initialize Progress Bar" );
    }
  },

  initializePasswordDialog: function( )
  {
    this.passwordDialog = new PasswordDialog( $$( 'password-dialog' ) );
    if ( !this.passwordDialog )
    {
      throw new Error( "Couldn't initialize password dialog" );
    }
  },

  // Welcome Functions

  revealWelcome: function( )
  {
    this.welcome.style.display = 'block';
  },

  hideWelcome: function( )
  {
    this.welcome.style.display = 'none';
  },

  // Search Box Functions
  
  promptForSearch: function( )
  {
     this.tagInput.autocompleteBox.disable( );
     var searchInput = $$( 'search-input' );
     searchInput.focus( );
  },

  // Username Functions

  clearUsername: function( )
  {
    this.setUsername( );
  },

  getUsername: function( )
  {
    return this.username;
  },

  setUsername: function( username )
  {
    username = username || '';
    this.username = username;
    this.usernameInput.input.value = username;
  },

  promptForUsername: function( )
  {
    DelanceyApplication.getInstance( ).usernameInput.enable( );
    DelanceyApplication.getInstance( ).usernameInput.focus( );
    return false;
  },

  // Password Functions

  promptForPassword: function( )
  {
    this.updateClaimButton( );
    this.hideWelcome( );
    this.bookmarkDisplay.hide( );
    this.passwordDialog.reveal( this.usernameInput.input.value );
  },

  setPassword: function( password )
  {
    if ( password )
    {
      this.setCookie( this.PASSWORD_COOKIE, hex_md5( password ), 356, '/' );
    }
    else
    {
      this.deleteCookie( this.PASSWORD_COOKIE, '/' );
    }
  },

  clearPassword: function( )
  {
    this.setPassword( );
  },

  // TagList Functions

  loadTagList: function( )
  {
    var username = this.usernameInput.input.value;
    if ( !username )
    {
      return this.promptForUsername( );
    }

    this.progressBar.start( 'Loading tag list from del.icio.us', 100, 
                            this.REQUEST_TIMEOUT,
                            function( ) 
      { 
        DelanceyApplication.getInstance( ).onTagListFailure( ); 
      } );

    this.disableAllInput( );
    this.usernameInput.input.blur( );
    this.messageBox.notice( "Loading tag list for " + username );
    var url = this.getBaseUrl( ) + "/tags/" + username;
    var parameters = 'format=json';
    var request = new Ajax.Request( url, {
        method: 'get',
        parameters: parameters,
        onFailure: function( request ) {
          DelanceyApplication.getInstance( ).onTagListFailure( request ) },
        onSuccess: function( request ) { 
          DelanceyApplication.getInstance( ).onTagListSuccess( request ) }
      } );
    if ( !request )
    {
      throw new Error( "Couldn't create new Ajax.Request for " + url );
    }
    return false; 
  },

  onTagListSuccess: function( request )
  {
    this.progressBar.stop( );

    if ( !request )
    {
      debug( "Invalid state.  No request object." );
      return this.onTagListFailure( );
    }

    window.delanceyClaim = request.getResponseHeader( CLAIM_HEADER );

    var username = this.usernameInput.input.value;

    if ( !username ) 
    {
      debug( "Invalid state.  No username." );
      return this.promptForUsername( );
    }

    if ( !this.isJsonResponse( request ) )
    {
      debug( "Invalid state.  Not a JSON response." );
      return this.onTagListFailure( request );
    }

    eval( 'var tagList = ' + request.responseText );

    if ( tagList[ CLAIM_HEADER ] )
    {
      debug( "Failing loadTagList: " + CLAIM_HEADER );
      this.workAroundSafariResponseHeaderBug( request, tagList );
      return this.onTagListFailure( request );
    }

    this.tagInput.setTagList( tagList );

    if ( !this.tagInput.isTagListLoaded( ) )
    {
      debug( "Invalid state.  Tags would not load." );
      return this.onTagListFailure( request );
    }

    this.setUsername( username );
    this.messageBox.notice( 'Tag list for  ' + username + ' loaded.' );
    this.tagInput.input.value = '';
    this.updateState( );
    return this.promptForTag( );
  },

  onTagListFailure: function( request )
  {
    this.progressBar.stop( );

    var username = this.usernameInput.input.value;

    if ( !request )
    {
      debug( "Invalid state.  No request" );
      this.messageBox.error( "Couldn't make request for tags." );
      return this.promptForUsername( );
    }

    if ( !username ) 
    {
      debug( "Invalid state.  No username" );
      this.messageBox.error( "Couldn't load tags." );
      return this.promptForUsername( );
    }

    this.messageBox.error( "Couldn't load tags for " + username + "." );

    window.delanceyClaim = request.getResponseHeader( CLAIM_HEADER );

    if ( window.delanceyClaim == 'denied' )
    {
      debug( "Access denied.  Prompting for password" );
      return this.promptForPassword( );
    }

    this.setTag( '' );
    this.setUsername( '' );
    this.updateState( );
    return this.promptForUsername( );
  },
  
  // Tag Functions

  clearTag: function( )
  {
    this.setTag( );
  },

  getTag: function( )
  {
    return this.tag;
  },

  setTag: function( tag )
  {
    tag = tag || '';
    this.tag = tag;
    this.tagInput.input.value = tag;
  },

  promptForTag: function( )
  {
    DelanceyApplication.getInstance( ).usernameInput.enable( );
    DelanceyApplication.getInstance( ).tagInput.enable( );
    DelanceyApplication.getInstance( ).tagInput.focus( );
    return false;
  },

  // Bookmarks Functions

  loadBookmarks: function( )
  {
    var username = this.getUsername( );
    if ( !username )
    {
      return this.promptForUsername( );
    }
    var tag = this.tagInput.input.value;
    if ( !tag )
    {
      return this.promptForTag( );
    }

    this.progressBar.start( 'Loading bookmarks from del.icio.us', 100, 
                            this.REQUEST_TIMEOUT, function( ) 
      {
         DelanceyApplication.getInstance( ).onBookmarksFailure( ); 
      } );

    this.tagInput.input.blur( );
    this.disableAllInput( );
    this.messageBox.notice( 'Loading ' + tag + ' for ' + username );
    var url = this.getBaseUrl( ) + '/bookmarks/' + username + '/' + tag;
    var parameters = 'format=json';
    var request = new Ajax.Request( url, {
        method: 'get',
        parameters: parameters,
        onFailure: function( request ) {
          DelanceyApplication.getInstance( ).onBookmarksFailure( request ) },
        onSuccess: function( request ) { 
          DelanceyApplication.getInstance( ).onBookmarksSuccess( request ) }
      } );
    if ( !request )
    {
      throw new Error( "Couldn't create new Ajax.Request for " + url );
    }
    return false; 
  },

  onBookmarksSuccess: function( request )
  {
    this.hideWelcome( );
    this.progressBar.stop( );

    if ( !request )
    {
      debug( "Invalid state.  No request object." );
      return this.onTagListFailure( );
    }

    window.delanceyClaim = request.getResponseHeader( CLAIM_HEADER );

    var username = this.usernameInput.input.value;

    if ( !username ) 
    {
      debug( "Invalid state.  No username." );
      return this.promptForUsername( );
    }

    var tag = this.tagInput.input.value;

    if ( !tag ) 
    {
      debug( "Invalid state.  No tag." );
      return this.promptForTag( );
    }

    if ( !this.isJsonResponse( request ) )
    {
      debug( "Invalid state.  Not a JSON response." );
      return this.onTagListFailure( request );
    }

    eval( 'var bookmarks = ' + request.responseText );
     
    if ( bookmarks[ CLAIM_HEADER ] )
    {
      debug( "Failing loadBookmarks: " + CLAIM_HEADER );
      this.workAroundSafariResponseHeaderBug( request, bookmarks );
      return this.onTagListFailure( request );
    }

    this.bookmarkDisplay.setBookmarks( bookmarks );

    if ( !this.bookmarkDisplay.areBookmarksLoaded( ) )
    {
      debug( "Invalid state.  Bookmarks wouldn't load." );
      return this.onBookmarksFailure( request );
    }

    this.setTag( tag );
    this.messageBox.notice( 'Bookmarks on ' + tag + 
                            ' loaded for ' + username );
    this.updateState( );
    this.enableAllInput( );
    this.bookmarkDisplay.reveal( );
    this.promptForSearch( );
  },

  onBookmarksFailure: function( request )
  {
    this.progressBar.stop( );

    if ( !request )
    {
      this.messageBox.error( "Couldn't make request for bookmarks." );
      debug( "Invalid state.  No request." );
      return this.promptForUsername( );
    }

    var username = this.usernameInput.input.value;

    if ( !username ) 
    {
      this.messageBox.error( "Couldn't load bookmarks." );
      debug( "Invalid state.  No username." );
      return this.promptForUsername( );
    }

    var tag = this.tagInput.input.value;

    if ( !tag ) 
    {
      debug( "Invalid state.  No tag." );
      this.messageBox.error( "Couldn't load bookmarks for " + username );
      return this.promptForUsername( );
    }

    this.messageBox.error( "Couldn't load bookmarks on " + tag + " for " + username );

    window.delanceyClaim = request.getResponseHeader( CLAIM_HEADER );

    if ( window.delanceyClaim == 'denied' )
    {
      return this.promptForPassword( );
    }

    this.updateState( );
    return this.promptForTag( );
  },

  // There is a bug in Safari's XmlHttpRequest object that causes 
  // response headers to disappear.  This manually works around the bug.

  workAroundSafariResponseHeaderBug: function( request, hash )
  {
    if ( hash[ CLAIM_HEADER ] && !request.getResponseHeader( CLAIM_HEADER ) )
    {
      request.setResponseHeader( CLAIM_HEADER, hash[ CLAIM_HEADER ] );
    }
  },

  // State Functions

  clear: function( )
  {
    this.clearUsername( );
    this.clearTag( );
    this.clearPassword( );
    this.bookmarkDisplay.clearBookmarks( );
    this.tagInput.clearTagList( );
    this.deleteCookie( this.USERNAME_COOKIE, '/' );
    this.deleteCookie( this.TAG_COOKIE, '/' );
    this.deleteCookie( this.PASSWORD_COOKIE, '/' );
    var start = this.getBaseUrl( ) + '/start/';
    setTimeout( 'window.location = "' + start + '"', 100 );
  },

  restoreState: function( )
  {
    this.disableAllInput( );
    this.overrideVariables( );
   
    if ( this.getCookie( this.USERNAME_COOKIE ) ) 
    {
      this.setUsername( this.getCookie( this.USERNAME_COOKIE ) )
    }
    else
    {
      this.revealWelcome( );
      return this.promptForUsername( );
    }

    if ( this.getCookie( this.TAG_COOKIE ) )
    {
      this.setTag( this.getCookie( this.TAG_COOKIE ) )
    }
    else
    {
      this.revealWelcome( );
      return this.promptForTag( );
    }

    this.loadBookmarks( );
  },

  overrideVariables: function( )
  {
    if ( window.username )
    {
      this.setCookie( this.USERNAME_COOKIE, window.username, 365, '/' );
    }
    if ( window.tag )
    {
      this.setCookie( this.TAG_COOKIE, window.tag, 365, '/' );
    }
  },

  updateState: function( )
  {
    this.updateTitle( );
    this.updateClearButton( );
    this.updateCookies( );
    this.updatePermalink( );
    this.updateBookmarklet( );
    this.updateClaimButton( );
  },

  updateWelcome: function( )
  {
    this.hideWelcome( );
  },

  updateTitle: function( )
  {
    var title = 'Unto.net > Delancey';
    var username = this.getUsername( );
    if ( username )
    {
      title += ' > ' + username;
    }
    var tag = this.getTag( );
    if ( tag )
    {
      title += ' > ' + tag;
    }
    document.title = title;
  },

  updateClearButton: function( )
  {
    this.clearButton.enable( );
  },

  updateClaimButton: function( )
  {
    if ( window.delanceyClaim == 'denied' )
    {
      this.claimButton.setText( 'Claimed' );
      this.claimButton.setClassName( 'claimed-denied' );
    }
    else if ( window.delanceyClaim == 'accepted' )
    {
      this.claimButton.setText( 'Claimed' );
      this.claimButton.setClassName( 'claimed-accepted' );
    }
    else if ( window.delanceyClaim == 'claimed' )
    {
      this.claimButton.setText( 'Claimed' );
      this.claimButton.setClassName( 'claimed' );
    }
    else
    {
      this.claimButton.setText( 'Claim' );
      this.claimButton.setClassName( '' );      
    }

    var username = this.getUsername( );

    if ( username )
    {
      var href = this.getBaseUrl( ) + '/claim/choose/' + username;
      this.claimButton.setHref( href );
      this.claimButton.enable( );
    }
    else
    {
      this.claimButton.disable( );
    }
  },

  updateCookies: function( )
  {
    var username = this.getUsername( );
    if ( username )
    {
      this.setCookie( this.USERNAME_COOKIE, username, 365, '/' );
    }
    else
    {
      this.deleteCookie( this.USERNAME_COOKIE, '/' );
    }
    var tag = this.getTag( );
    if ( tag )
    {
      this.setCookie( this.TAG_COOKIE, tag, 365, '/' );
    }
    else
    {
      this.deleteCookie( this.TAG_COOKIE, '/' );
    }
  },

  updatePermalink: function( )
  {
    var href = this.getBaseUrl( ) + '/start/';
    var username = this.getUsername( );
    var tag = this.getTag( );
    if ( username && tag )
    {
      href += username + '/' + tag + '/';
    }
    else if ( username )
    {
      href += username + '/';
    }
    this.permalink.href = href;
  },

  updateBookmarklet: function( )
  {
    var username = this.getUsername( );
    if ( username )
    {
      var href = "javascript:location.href='http://del.icio.us/" + 
       username + 
      "?v=3&tags=delancey&url='+encodeURIComponent(location.href)+'" +
      "&title='+encodeURIComponent(document.title)";
      this.bookmarklet.setHref( href );
      this.bookmarklet.enable( );
    }
    else
    {
      this.bookmarklet.disable( );
    }
  },

  // Utility Functions

  getCurrentServerTime: function( )
  {
    return ( ( new Date( ) ).getTime( ) / 1000 ) + this.timeDelta;
  },

  setBaseUrl: function( baseUrl )
  {
    if ( !baseUrl )
    {
      throw new Error( "Couldn't set base url" );
    }
    this.baseUrl = baseUrl;
  },

  getBaseUrl: function( )
  {
    if ( !this.baseUrl )
    {
      throw new Error( "Couldn't get base url" );
    }
    return this.baseUrl;
  },

  removeChildNodes: function ( element )
  {
    if ( !element || !element.hasChildNodes( ) )
    {
      return;
    }

    var childNodes = element.childNodes;

    for ( var i = 0; i < childNodes.length; i++ )
    {
      element.removeChild( childNodes[i] );
    }
  },

  // expires is a positive delta in days

  setCookie: function ( name, value, expires, path, domain, secure ) 
  {
    if ( expires )
    {
      var today = new Date( );
      expires = expires * 1000 * 60 * 60 * 24;
      expires = new Date( today.getTime( ) + ( expires ) );
      expires = expires.toGMTString( );
    }

    var curCookie = name + "=" + escape( value ) +
      ( ( expires ) ? "; expires=" + expires : "" ) +
      ( ( path ) ? "; path=" + path : "" ) +
      ( ( domain ) ? "; domain=" + domain : "" ) +
      ( ( secure ) ? "; secure" : "" );

    document.cookie = curCookie;
  },

  getCookie: function ( name ) 
  {
    var start = document.cookie.indexOf( name + "=" );
    var len = start + name.length + 1;
    if ( ( ( !start ) &&
           ( name != document.cookie.substring( 0, name.length ) ) ) ||
         ( start == -1 ) )
    {
      return null;
    }
    var end = document.cookie.indexOf( ";", len );
    if ( end == -1 ) 
    { 
      end = document.cookie.length;
    }
    return unescape( document.cookie.substring( len, end ) );
  }, 

  deleteCookie: function( name, path, domain ) 
  {
    if ( this.getCookie( name ) )
    { 
      document.cookie = name + "=" +
        ( ( path ) ? ";path=" + path : "" ) +
        ( ( domain ) ? ";domain=" + domain : "" ) +
        ";expires=Thu, 01-Jan-1970 00:00:01 GMT";
     }
  },                

  isJsonResponse: function( response )
  {
    return response.responseText && response.responseText.match( /^[\{\[]/ );
  },

  disableAllInput: function( )
  {
    this.usernameInput.disable( );    
    this.tagInput.disable( );    
  },
  
  enableAllInput: function( )
  {
    this.usernameInput.enable( );
    this.tagInput.enable( );
  }
};


DelanceyApplication.getInstance = function( )
{
  if ( !window.delanceyInstance )
  {
    window.delanceyInstance = new DelanceyApplication( );
    if ( !window.delanceyInstance )
    {
      throw new Error( "Couldn't initialize DelanceyApplication" );
    }
  }
  return window.delanceyInstance;
};
