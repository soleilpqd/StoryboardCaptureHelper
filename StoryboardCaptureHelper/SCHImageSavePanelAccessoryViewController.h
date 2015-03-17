//
//  SCHImageSavePanelAccessoryViewController.h
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 04/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SCHImageSavePanelAccessoryViewController : NSViewController

@property ( nonatomic, weak ) IBOutlet NSPopUpButton *pubType;
@property ( nonatomic, readonly ) NSSavePanel *savePanel;
@property ( nonatomic, readonly ) NSBitmapImageFileType imageType;

-( NSString* )fileExtensionForCurrentImageType;
-( void )showSavePanelWithTitle:( NSString* )title
                   panelMessage:( NSString* )message
                suggestFileName:( NSString* )fileName
                     onComplete:(void (^)( NSString *resultPath ))completion;
-( void )saveConfigWithDestinationPath:( NSString* )destination;

@end
