/*
 * %@
 * Created by %@ on %@
 */

var lastViewId = null;
function highlightFrame( view ){
  var indicator = document.getElementById( "highlight_indicator" );
  indicator.style.top = view.offsetTop - 5;
  indicator.style.left = view.offsetLeft - 5;
  indicator.style.width = view.offsetWidth + 5;
  indicator.style.height = view.offsetHeight + 5;
  indicator.style.border = "2px dashed red";
  lastViewId = view.id;
  window.location = "#" + view.id;
}
function radioButtonDidSelect( frameId ){
  var view = document.getElementById( frameId );
  highlightFrame( view );
}
function frameViewDidSelected( view ){
  highlightFrame( view );
  var radioButton = document.getElementById( "opt_" + view.id );
  radioButton.checked = 1;
}
function segueIconDidSelected( segueIcon ){
  var canvas = document.getElementById( "background_context" );
  selectSegue( canvas, segueIcon.id );
}
function backgroundDidClicked(){
  var canvas = document.getElementById( "background_context" );
  drawAllSegues( canvas );
  var indicator = document.getElementById( "highlight_indicator" );
  indicator.style.border = "none";
  if ( lastViewId ){
	var radioButton = document.getElementById( "opt_" + lastViewId );
	radioButton.checked = 0;
	lastViewId = null;
  }
}

function displayMenu( shouldShow ){
  var menu = document.getElementById( "frames_list" );
  var mainView = document.getElementById( "main_canvas" );
  if ( shouldShow ){
    menu.style.display = "block";
    mainView.style.paddingRight = 200;
  } else {
	menu.style.display = "none";
    mainView.style.paddingRight = 0;
  }
}
