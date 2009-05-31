//
// The Behavior grid, to be loaded by behaviors.js
//

var springBehaviours = {

  '#search-form' : function( element ) {
    element.action = 'javascript:doSearchFormSubmit( );';
  },

  '#search-submit' : function( element ) {
    element.onclick = function( ) {
      doSearchFormSubmit( );
    };
  },

  '#search-text' : function( element ) {
    element.onkeyup = function( ) {
      doSearchTextEdit( );
    };
  }

};

//
// Main
//

initBehaviours( );

//
// Functions
//

function initSpringBoard( ) {
  initSearchForm( );
}

function initSearchForm( ) {
  doSearchTextEdit( );
}

function initBehaviours( ) {
  Behaviour.register( springBehaviours );
}


function newXmlHttpRequest( )
{
  var xmlHttpRequest = false;

  /*@cc_on @*/
  /*@if (@_jscript_version >= 5)
  try {
    xmlHttpRequest = new ActiveXObject("Msxml2.XMLHTTP");
  } catch (e) {
    try {
      xmlHttpRequest = new ActiveXObject("Microsoft.XMLHTTP");
    } catch (E) {
      xmlHttpRequest = false;
    }
  }
  @end @*/
  if (!xmlHttpRequest && typeof XMLHttpRequest!='undefined') {
    xmlHttpRequest = new XMLHttpRequest();
  }

  return xmlHttpRequest;
}


function getFirstElementBySelector(selector) {
  list = document.getElementsBySelector(selector);
  if (!list) {
    return;
  }
  return list[0];
}


function doSearchTextEdit( ) {
  var searchSubmit = document.getElementById( 'search-submit' );
  var searchText = document.getElementById( 'search-text' );
  if ( searchText.value.length > 0 ) {
    searchSubmit.style[ 'cursor' ] = 'pointer';
    searchSubmit.style[ 'color' ] = '#111111';
  } else {
    searchSubmit.style[ 'cursor' ] = 'default';
    searchSubmit.style[ 'color' ] = '#999999';
  }
}

function doSearchFormSubmit( ) {
  var xmlHttpRequest = newXmlHttpRequest( );
  var query = document.getElementById( 'search-text' ).value;
  var url = 'amazon/product/html/Books/' + query;
  document.title = 'Search for: ' + query;
  document.getElementById( 'notice' ).style[ 'display' ] = 'default';
  document.getElementById( 'notice' ).innerHTML = 'Loading....';
  xmlHttpRequest.open( "GET", url, true );
  xmlHttpRequest.onreadystatechange = function( ) {
    if ( xmlHttpRequest.readyState == 4 ) {
      document.getElementById( 'notice' ).style[ 'display' ] = 'none';
      document.getElementById( 'items' ).innerHTML = xmlHttpRequest.responseText;
    }
  };
  xmlHttpRequest.send( null );
}
