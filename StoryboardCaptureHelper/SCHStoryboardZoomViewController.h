//
//  SCHStoryboardZoomViewController.h
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 12/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SCHStoryboardZoomViewController : NSViewController

-( void )openZoomerWithTargetView:( id )canvasView
                 targetScrollview:( id )canvasScrollview
                      anchorPoint:( CGPoint )targetPoint
                         onWindow:( NSWindow* )targetWindow;

@end
