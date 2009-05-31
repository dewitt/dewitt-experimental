//
// The Behavior grid, to be loaded by behaviors.js
//

var rivingtonUrl = "";
var rivingtonHintEdited = false;

var rivingtonBehaviours = {

  '#url' : function( element ) {
     element.onblur = function( ) {
       doGetHint( );
     };
     element.onkeyup = function( ) {
       setTimeout( "doGetHint( )", 350 );
     }
   },
   '#hint' : function( element ) {
     element.onkeyup = function( ) {
       rivingtonHintEdited = true;
     }
   }
};

//
// Main
//

initBehaviours( );

//
// Functions
//

function initBehaviours( ) {
  Behaviour.register( rivingtonBehaviours );
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

function doGetHint( ) {

  url = document.getElementById( 'url' );

  if ( ( !url.value ) || ( rivingtonUrl == url.value ) || ( rivingtonHintEdited ) ) {
    return;
  }

  rivingtonUrl = url.value;  

  var xmlHttpRequest = newXmlHttpRequest( );
  var serviceUrl = 'hint/?url=' + url.value;
  xmlHttpRequest.open( "GET", serviceUrl, true );
  xmlHttpRequest.onreadystatechange = function( ) {
    if ( xmlHttpRequest.readyState == 4 ) {
      document.getElementById( 'hint' ).value = xmlHttpRequest.responseText;
    }
  };
  xmlHttpRequest.send( null );
}

