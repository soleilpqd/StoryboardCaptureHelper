/*
 * %@
 * Created by %@ on %@
 */

var zoomScale = %.2f;
var segueHandleLength = 50 * zoomScale;
var allSegues = {};
%@

function initDrawingSegueContext( canvas ){
  var context = canvas.getContext("2d")
  context.clearRect ( 0 , 0 , canvas.width, canvas.height );
  context.lineWidth	= 5 * zoomScale;
  context.lineCap	= "round";
  context.lineJoin	= "round";
  context.shadowBlur = 0;
  return context;
}

function drawAllSegues( canvas ){
  var ctx = initDrawingSegueContext( canvas );
  for (var segueId in allSegues ){
    drawSegueById( ctx, segueId );
  }
  return ctx;
}

function selectSegue( canvas, segueId ){
  var ctx = drawAllSegues( canvas );
  ctx.shadowBlur = 10 * zoomScale;
  drawSegueById( ctx, segueId );
}

function setupSegueColor( context, segueId ){
  var segueIcon = document.getElementById( segueId );
  var segueIconStyle = document.defaultView.getComputedStyle( segueIcon, null );
  context.strokeStyle = context.shadowColor = segueIconStyle.getPropertyValue( "color" );
}

function drawSegueById( context, segueId ){
  setupSegueColor( context, segueId );
  var segueInfo = allSegues[ segueId ];
  if ( segueInfo.from != "" && segueInfo.to != "" )
	drawSegueBetween2ViewControllers( context, segueInfo.from, segueInfo.to, segueId );
  else if ( segueInfo.to != "" )
    drawSingleSegueToViewController( context, segueInfo.to );
}

function drawSingleSegueToViewController( context, viewId ){
  var view = document.getElementById( viewId );
  var rect = { top:view.offsetTop, left:view.offsetLeft, bottom:view.offsetTop + view.offsetHeight, right:view.offsetLeft + view.offsetWidth }
  var midLeft = { x:rect.left, y:( rect.top + rect.bottom ) / 2 };
  context.beginPath();
  context.moveTo( midLeft.x, midLeft.y );
  context.lineTo( midLeft.x - segueHandleLength, midLeft.y );
  context.stroke();
  // Draw arrow
  context.beginPath();
  context.moveTo( midLeft.x - segueHandleLength / 2, midLeft.y - segueHandleLength / 2 );
  context.lineTo( midLeft.x, midLeft.y );
  context.lineTo( midLeft.x - segueHandleLength / 2, midLeft.y + segueHandleLength / 2 );
  context.stroke();
}

function distanceOfTwoPoints ( point1, point2 ){
  return Math.sqrt( Math.pow( point1.x - point2.x, 2 ) + Math.pow( point1.y - point2.y, 2 ));
}

function getNearestPoints_FromViewTopLeft( destPoints, edges, fromRect, toRect ){
  var midPRight1 = { x:fromRect.right, y:( fromRect.top + fromRect.bottom ) / 2 };
  var midPBottom1 = { x:( fromRect.left + fromRect.right ) / 2, y:fromRect.bottom };
  var midPLeft2 = { x:toRect.left, y:( toRect.top + toRect.bottom ) / 2 };
  var midPTop2 = { x:( toRect.left + toRect.right ) / 2, y:toRect.top };
  
  var dR1L2 = distanceOfTwoPoints( midPRight1, midPLeft2 );
  var dR1T2 = distanceOfTwoPoints( midPRight1, midPTop2 );
  var dB1L2 = distanceOfTwoPoints( midPBottom1, midPLeft2 );
  var dB1T2 = distanceOfTwoPoints( midPBottom1, midPTop2 );
  
  var dMin = Math.min( dR1L2, dR1T2, dB1L2, dB1T2 );
  
  switch ( dMin ){
    case dR1L2:
      destPoints.fromX = midPRight1.x;
      destPoints.fromY = midPRight1.y;
      destPoints.toX = midPLeft2.x;
      destPoints.toY = midPLeft2.y;
      edges.from = "R";
      edges.to = "L";
      break;
    case dR1T2:
      destPoints.fromX = midPRight1.x;
      destPoints.fromY = midPRight1.y;
      destPoints.toX = midPTop2.x;
      destPoints.toY = midPTop2.y;
      edges.from = "R";
      edges.to = "T";
      break;
    case dB1L2:
      destPoints.fromX = midPBottom1.x;
      destPoints.fromY = midPBottom1.y;
      destPoints.toX = midPLeft2.x;
      destPoints.toY = midPLeft2.y;
      edges.from = "B";
      edges.to = "L";
      break;
    case dB1T2:
      destPoints.fromX = midPBottom1.x;
      destPoints.fromY = midPBottom1.y;
      destPoints.toX = midPTop2.x;
      destPoints.toY = midPTop2.y;
      edges.from = "B";
      edges.to = "T";
      break;
  }
}

function getNearestPoints_FromViewTopRight( destPoints, edges, fromRect, toRect ){
  var midP1Left = { x:fromRect.left, y:( fromRect.top + fromRect.bottom ) / 2 };
  var midP1Bottom = { x:( fromRect.left + fromRect.right ) / 2, y:fromRect.bottom };
  var midP2Right = { x:toRect.right, y:( toRect.top + toRect.bottom ) / 2 };
  var midP2Top = { x:( toRect.left + toRect.right ) / 2, y:toRect.top };
  
  var d1L2R = distanceOfTwoPoints( midP1Left, midP2Right );
  var d1L2T = distanceOfTwoPoints( midP1Left, midP2Top );
  var d1B2R = distanceOfTwoPoints( midP1Bottom, midP2Right );
  var d1B2T = distanceOfTwoPoints( midP1Bottom, midP2Top );
  
  var dMin = Math.min( d1L2R, d1L2T, d1B2R, d1B2T );
  
  switch ( dMin ){
    case d1L2R:
      destPoints.fromX = midP1Left.x;
      destPoints.fromY = midP1Left.y;
      destPoints.toX = midP2Right.x;
      destPoints.toY = midP2Right.y;
      edges.from = "L";
      edges.to = "R";
      break;
    case d1L2T:
      destPoints.fromX = midP1Left.x;
      destPoints.fromY = midP1Left.y;
      destPoints.toX = midP2Top.x;
      destPoints.toY = midP2Top.y;
      edges.from = "L";
      edges.to = "T";
      break;
    case d1B2R:
      destPoints.fromX = midP1Bottom.x;
      destPoints.fromY = midP1Bottom.y;
      destPoints.toX = midP2Right.x;
      destPoints.toY = midP2Right.y;
      edges.from = "B";
      edges.to = "R";
      break;
    case d1B2T:
      destPoints.fromX = midP1Bottom.x;
      destPoints.fromY = midP1Bottom.y;
      destPoints.toX = midP2Top.x;
      destPoints.toY = midP2Top.y;
      edges.from = "B";
      edges.to = "T";
      break;
  }
}

function getNearestPoints_FromViewBottomLeft( destPoints, edges, fromRect, toRect ){
  var midP1Right = { x:fromRect.right, y:( fromRect.top + fromRect.bottom ) / 2 };
  var midP1Top = { x:( fromRect.left + fromRect.right ) / 2, y:fromRect.top };
  var midP2Left = { x:toRect.left, y:( toRect.top + toRect.bottom ) / 2 };
  var midP2Bottom = { x:( toRect.left + toRect.right ) / 2, y:toRect.bottom };
  
  var d1R2L = distanceOfTwoPoints( midP1Right, midP2Left );
  var d1R2B = distanceOfTwoPoints( midP1Right, midP2Bottom );
  var d1T2L = distanceOfTwoPoints( midP1Top, midP2Left );
  var d1T2B = distanceOfTwoPoints( midP1Top, midP2Bottom );
  
  var dMin = Math.min( d1R2L, d1R2B, d1T2L, d1T2B );
  
  switch ( dMin ){
    case d1R2L:
      destPoints.fromX = midP1Right.x;
      destPoints.fromY = midP1Right.y;
      destPoints.toX = midP2Left.x;
      destPoints.toY = midP2Left.y;
      edges.from = "R";
      edges.to = "L";
      break;
    case d1R2B:
      destPoints.fromX = midP1Right.x;
      destPoints.fromY = midP1Right.y;
      destPoints.toX = midP2Bottom.x;
      destPoints.toY = midP2Bottom.y;
      edges.from = "R";
      edges.to = "B";
      break;
    case d1T2L:
      destPoints.fromX = midP1Top.x;
      destPoints.fromY = midP1Top.y;
      destPoints.toX = midP2Left.x;
      destPoints.toY = midP2Left.y;
      edges.from = "T";
      edges.to = "L";
      break;
    case d1T2B:
      destPoints.fromX = midP1Top.x;
      destPoints.fromY = midP1Top.y;
      destPoints.toX = midP2Bottom.x;
      destPoints.toY = midP2Bottom.y;
      edges.from = "T";
      edges.to = "B";
      break;
  }
}

function getNearestPoints_FromViewBottomRight( destPoints, edges, fromRect, toRect ){
  var midP1Left = { x:fromRect.left, y:( fromRect.top + fromRect.bottom ) / 2 };
  var midP1Top = { x:( fromRect.left + fromRect.right ) / 2, y:fromRect.top };
  var midP2Right = { x:toRect.right, y:( toRect.top + toRect.bottom ) / 2 };
  var midP2Bottom = { x:( toRect.left + toRect.right ) / 2, y:toRect.bottom };
  
  var d1L2R = distanceOfTwoPoints( midP1Left, midP2Right );
  var d1L2B = distanceOfTwoPoints( midP1Left, midP2Bottom );
  var d1T2R = distanceOfTwoPoints( midP1Top, midP2Right );
  var d1T2B = distanceOfTwoPoints( midP1Top, midP2Bottom );
  
  var dMin = Math.min( d1L2R, d1L2B, d1T2R, d1T2B );
  
  switch ( dMin ){
    case d1L2R:
      destPoints.fromX = midP1Left.x;
      destPoints.fromY = midP1Left.y;
      destPoints.toX = midP2Right.x;
      destPoints.toY = midP2Right.y;
      edges.from = "L";
      edges.to = "R";
      break;
    case d1L2B:
      destPoints.fromX = midP1Left.x;
      destPoints.fromY = midP1Left.y;
      destPoints.toX = midP2Bottom.x;
      destPoints.toY = midP2Bottom.y;
      edges.from = "L";
      edges.to = "B";
      break;
    case d1T2R:
      destPoints.fromX = midP1Top.x;
      destPoints.fromY = midP1Top.y;
      destPoints.toX = midP2Right.x;
      destPoints.toY = midP2Right.y;
      edges.from = "T";
      edges.to = "R";
      break;
    case d1T2B:
      destPoints.fromX = midP1Top.x;
      destPoints.fromY = midP1Top.y;
      destPoints.toX = midP2Bottom.x;
      destPoints.toY = midP2Bottom.y;
      edges.from = "T";
      edges.to = "B";
      break;
  }
}

function drawSegueBetween2ViewControllers( context, view1ID, view2ID, segueId ){
  var view1 = document.getElementById( view1ID );
  var rect1 = { top:view1.offsetTop, left:view1.offsetLeft, bottom:view1.offsetTop + view1.offsetHeight, right:view1.offsetLeft + view1.offsetWidth }
  var view2 = document.getElementById( view2ID );
  var rect2 = { top:view2.offsetTop, left:view2.offsetLeft, bottom:view2.offsetTop + view2.offsetHeight, right:view2.offsetLeft + view2.offsetWidth }
  if ( rect1.top == rect2.top && rect1.left == rect2.left && rect1.right == rect2.right && rect1.bottom == rect2.bottom ) return;
  // Detect positions-related between 2 view
  var offsetV12 = Math.abs( rect1.bottom - rect2.top );
  var offsetV21 = Math.abs( rect1.top - rect2.bottom );
  var offsetH12 = Math.abs( rect1.right - rect2.left );
  var offsetH21 = Math.abs( rect1.left - rect2.right );
  // The last purpose is finding the shortest line to draw
  var drawPoints = { fromX:0, fromY:0, toX:0, toY:0 };
  var drawEdge = { from:"", to:"" };
  if ( offsetV12 > offsetV21 ){ // view2 above view1
    if ( offsetH12 > offsetH21 ){ // view2 on left of view 1
      getNearestPoints_FromViewBottomRight( drawPoints, drawEdge, rect1, rect2 );
    } else { // view2 on right of view1
      getNearestPoints_FromViewBottomLeft( drawPoints, drawEdge, rect1, rect2 );
    }
  } else { // view1 above view2
    if ( offsetH12 > offsetH21 ){ // view2 on left of view 1
      getNearestPoints_FromViewTopRight( drawPoints, drawEdge, rect1, rect2 );
    } else { // view2 on right of view1
      getNearestPoints_FromViewTopLeft( drawPoints, drawEdge, rect1, rect2 );
    }
  }
  // Star drawing segue
  var curPoint = { x:drawPoints.fromX, y:drawPoints.fromY };
  context.beginPath();
  context.moveTo( curPoint.x, curPoint.y );
  switch ( drawEdge.from ){
    case "T":
      curPoint.y -= segueHandleLength;
      break;
    case "B":
      curPoint.y += segueHandleLength;
      break;
    case "L":
      curPoint.x -= segueHandleLength;
      break;
    case "R":
      curPoint.x += segueHandleLength;
      break;
  }
  context.lineTo( curPoint.x, curPoint.y );
  var p1 = { x:curPoint.x, y:curPoint.y };
  curPoint.x = drawPoints.toX;
  curPoint.y = drawPoints.toY;
  switch ( drawEdge.to ){
    case "T":
      curPoint.y -= segueHandleLength;
      break;
    case "B":
      curPoint.y += segueHandleLength;
      break;
    case "L":
      curPoint.x -= segueHandleLength;
      break;
    case "R":
      curPoint.x += segueHandleLength;
      break;
  }
  context.lineTo( curPoint.x, curPoint.y );
  var p2 = { x:curPoint.x, y:curPoint.y };
  curPoint.x = drawPoints.toX;
  curPoint.y = drawPoints.toY;
  context.lineTo( curPoint.x, curPoint.y );
  context.stroke();
  // Draw arrow
  context.beginPath();
  switch ( drawEdge.to ){
    case "T":
      curPoint.x -= segueHandleLength / 2;
      curPoint.y -= segueHandleLength / 2;
      break;
    case "B":
      curPoint.x -= segueHandleLength / 2;
      curPoint.y += segueHandleLength / 2;
      break;
    case "L":
      curPoint.x -= segueHandleLength / 2;
      curPoint.y -= segueHandleLength / 2;
      break;
    case "R":
      curPoint.x += segueHandleLength / 2;
      curPoint.y -= segueHandleLength / 2;
      break;
  }
  context.moveTo( curPoint.x, curPoint.y );
  curPoint.x = drawPoints.toX;
  curPoint.y = drawPoints.toY;
  context.lineTo( curPoint.x, curPoint.y );
  switch ( drawEdge.to ){
    case "T":
      curPoint.x += segueHandleLength / 2;
      curPoint.y -= segueHandleLength / 2;
      break;
    case "B":
      curPoint.x += segueHandleLength / 2;
      curPoint.y += segueHandleLength / 2;
      break;
    case "L":
      curPoint.x -= segueHandleLength / 2;
      curPoint.y += segueHandleLength / 2;
      break;
    case "R":
      curPoint.x += segueHandleLength / 2;
      curPoint.y += segueHandleLength / 2;
      break;
  }
  context.lineTo( curPoint.x, curPoint.y );
  context.stroke();
  // Segue icon
  var segueIcon = document.getElementById( segueId );
  segueIcon.style.top = ( p1.y + p2.y - segueIcon.offsetHeight ) / 2 ;
  segueIcon.style.left = ( p1.x + p2.x - segueIcon.offsetWidth ) / 2 ;
}
