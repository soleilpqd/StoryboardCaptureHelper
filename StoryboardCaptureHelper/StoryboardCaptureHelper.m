//
//  StoryboardCaptureHelper.m
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 03/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import "StoryboardCaptureHelper.h"
#import <objc/runtime.h>
#import "SCHImageSavePanelAccessoryViewController.h"
#import "SCHExportSavePanelAccessoryViewController.h"
#import "SCHStoryboardZoomViewController.h"

typedef NS_ENUM( NSUInteger, SCHMenuOperationTarget ){
    kSCHOperationChupAnhStoryboard,
    kSCHOperationChupAnhProjectTree
};

static StoryboardCaptureHelper *sharedPlugin;

@interface StoryboardCaptureHelper()<NSOpenSavePanelDelegate>

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property ( nonatomic, strong ) SCHImageSavePanelAccessoryViewController *savePanelAccessoryView;
@property ( nonatomic, strong ) SCHExportSavePanelAccessoryViewController *exportPanelAccesoryView;
@property ( nonatomic, readonly ) BOOL isWindowUnlimtedSize;

@property ( nonatomic, strong ) NSMenuItem *mnuStoryboardContextItem;

@property ( nonatomic, weak ) NSMenuItem *mnuChupAnhStoryboard;
@property ( nonatomic, strong ) NSArray *arrStoryboardPath;
@property ( nonatomic, strong ) NSArray *arrStoryboardIdentifiers;

@property ( nonatomic, strong ) NSMenuItem *mnuChupAnhPrjTree;
@property ( nonatomic, strong ) NSArray *arrPrjTreePath;
@property ( nonatomic, strong ) NSArray *arrPrjTreeIdentifiers;

@property ( nonatomic, weak ) NSMenuItem *mnuXuatRaHTML;

@property ( nonatomic, strong ) NSMenuItem *mnuSetZoomScale;
@property ( nonatomic, strong ) NSEvent *lastContextMenuEvent;

@property ( nonatomic, strong ) NSWindow *winZoomer;
@property ( nonatomic, strong ) SCHStoryboardZoomViewController *schZoomer;

@property ( nonatomic, assign ) NSRect originalWinFrame;
@property ( nonatomic, assign ) BOOL shouldRestoreWinFrame;

@property ( nonatomic, weak ) NSWindow *targetWindow;

@end

@implementation StoryboardCaptureHelper

#pragma mark - Life cycle

NSMenu* ( *_original_storyboard_menuForEvent )( id, SEL, NSEvent* );
// Insert "Custom zoom scale" into storyboard context menu
NSMenu* SCH_storyboard_menuForEvent( id object, SEL selector, NSEvent* event ) {
    NSMenu *menu = _original_storyboard_menuForEvent( object, selector, event );
    if ( menu && [ menu.title isEqualToString:@"Xcode.InterfaceBuilderKit.MenuDefinition.ContextualMenu" ]){
        [[ StoryboardCaptureHelper sharedPlugin ] setLastContextMenuEvent:event ];
        if (![ menu.itemArray containsObject:[[ StoryboardCaptureHelper sharedPlugin ] mnuSetZoomScale ]]) {
            [ menu insertItem:[[ StoryboardCaptureHelper sharedPlugin ] mnuSetZoomScale ]
                      atIndex:menu.itemArray.count - 2 ];
        }
        if (![ menu.itemArray containsObject:[[ StoryboardCaptureHelper sharedPlugin ] mnuStoryboardContextItem ]]) {
            [ menu addItem:[[ StoryboardCaptureHelper sharedPlugin ] mnuStoryboardContextItem ]];
        }
    }
    return menu;
}

NSMenu* ( *_original_projectTree_menuForEvent )( id, SEL, NSEvent* );
NSMenu* SCH_projectTree_menuForEvent( id object, SEL selector, NSEvent* event ) {
    NSMenu *menu = _original_projectTree_menuForEvent( object, selector, event );
    if ( menu && [ menu.title isEqualToString:@"Project navigator contextual menu" ]){
        if (![ menu.itemArray containsObject:[[ StoryboardCaptureHelper sharedPlugin ] mnuChupAnhPrjTree ]]) {
            [ menu addItem:[[ StoryboardCaptureHelper sharedPlugin ] mnuChupAnhPrjTree ]];
        }
    }
    return menu;
}

// Allow XCode window can be resize bigger than screen
CGRect SCH_constrainFrameRect_toScreen( id object, SEL selector, CGRect rect, NSScreen *screen ){
    if ([[ StoryboardCaptureHelper sharedPlugin ] isWindowUnlimtedSize ]) {
        return rect;
    } else {
        CGRect (*constrainFrameRectSuper)( id, SEL, CGRect, NSScreen* ) = ( CGRect (*)( id, SEL, CGRect, NSScreen* ))class_getMethodImplementation([ object superclass ], @selector( constrainFrameRect:toScreen: ));
        return constrainFrameRectSuper( object, selector, rect, screen );
    }
}

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

-( void )infectXCodeMenu {
    Class ideWorkspaceWindowClass = NSClassFromString( @"IDEWorkspaceWindow" );
    class_addMethod( ideWorkspaceWindowClass, @selector( constrainFrameRect:toScreen: ),
                    ( IMP )&SCH_constrainFrameRect_toScreen, "{{dd}{dd}}@:{{dd}{dd}}@" );
    Class IBStoryboardCanvasViewClass = NSClassFromString( @"IBStoryboardCanvasView" );
    _original_storyboard_menuForEvent = ( NSMenu*(*)( id, SEL, NSEvent* ))class_getMethodImplementation( IBStoryboardCanvasViewClass, @selector( menuForEvent: ));
    Method method = class_getInstanceMethod( IBStoryboardCanvasViewClass, @selector( menuForEvent: ));
    method_setImplementation( method, ( IMP )&SCH_storyboard_menuForEvent );
    Class IDENavigatorOutlineViewClass = NSClassFromString( @"IDENavigatorOutlineView" );
    _original_projectTree_menuForEvent = ( NSMenu*(*)( id, SEL, NSEvent* ))class_getMethodImplementation( IDENavigatorOutlineViewClass, @selector( menuForEvent: ));
    method = class_getInstanceMethod( IDENavigatorOutlineViewClass, @selector( menuForEvent: ));
    method_setImplementation( method, ( IMP )&SCH_projectTree_menuForEvent );
}

-( void )makeMyMenu {
    self.mnuStoryboardContextItem = [[ NSMenuItem alloc ] initWithTitle:@"Capture to image"
                                                                 action:nil
                                                          keyEquivalent:@"" ];
    self.mnuStoryboardContextItem.submenu = [[ NSMenu alloc ] initWithTitle:self.mnuStoryboardContextItem.title ];
    // Menu capture storyboard (xib)
    NSMenuItem *actionMenuItem = [[ NSMenuItem alloc ] initWithTitle:@"Storyboard capture"
                                                              action:@selector( menuChupAnh_duocChon: )
                                                       keyEquivalent:@"" ];
    [ actionMenuItem setTarget:self ];
    [ self.mnuStoryboardContextItem.submenu addItem:actionMenuItem ];
    self.mnuChupAnhStoryboard = actionMenuItem;
    // Menu capture project tree
    actionMenuItem = [[ NSMenuItem alloc ] initWithTitle:@"Project tree capture"
                                                  action:@selector( menuChupAnh_duocChon: )
                                           keyEquivalent:@"" ];
    [ actionMenuItem setTarget:self ];
    self.mnuChupAnhPrjTree = actionMenuItem;
    // Export
    actionMenuItem = [[ NSMenuItem alloc ] initWithTitle:@"Export all frames"
                                                  action:@selector( menuXuatRaHTML_duocChon: )
                                           keyEquivalent:@"" ];
    [ actionMenuItem setTarget:self ];
    [ self.mnuStoryboardContextItem.submenu addItem:actionMenuItem ];
    self.mnuXuatRaHTML = actionMenuItem;
    
    // Menu set xib zoom scale
    actionMenuItem = [[ NSMenuItem alloc ] initWithTitle:@"Custom zoom sclae"
                                                  action:@selector( menuZoom_duocChon: )
                                           keyEquivalent:@"" ];
    [ actionMenuItem setTarget:self ];
    self.mnuSetZoomScale = actionMenuItem;
}

-( void )makeSearchPath {
    self.arrStoryboardPath = @[ @"NSTabView", @"DVTControllerContentView", @"DVTSplitView", @"DVTReplacementView",
                                @"DVTControllerContentView", @"DVTSplitView", @"DVTLayoutView_ML", @"NSView",
                                @"DVTControllerContentView", @"DVTControllerContentView", @"NSView", @"DVTBorderedView",
                                @"DVTControllerContentView", @"IBStructureAreaDockLabelContainer", @"DVTSplitView",
                                @"DVTReplacementView", @"DVTControllerContentView", @"DVTStackView_AppKitAutolayout",
                                @"IBCanvasScrollView" ];
    self.arrStoryboardIdentifiers = @[ @"IBStoryboardCanvasView", @"IBCanvasView" ];
    
    self.arrPrjTreePath = @[ @"NSTabView", @"DVTControllerContentView", @"DVTSplitView", @"DVTReplacementView",
                             @"DVTControllerContentView", @"DVTBorderedView", @"DVTReplacementView",
                             @"DVTControllerContentView", @"DVTScrollView" ];
    self.arrPrjTreeIdentifiers = @[ @"IDENavigatorOutlineView" ];
}

-( void )makeMyComponents {
    self.savePanelAccessoryView = [[ SCHImageSavePanelAccessoryViewController alloc ] initWithNibName:@"SCHImageSavePanelAccessoryViewController"
                                                                                               bundle:self.bundle ];
    self.exportPanelAccesoryView = [[ SCHExportSavePanelAccessoryViewController alloc ] initWithNibName:@"SCHExportSavePanelAccessoryViewController"
                                                                                                 bundle:self.bundle ];
    self.schZoomer = [[ SCHStoryboardZoomViewController alloc ] initWithNibName:@"SCHStoryboardZoomViewController"
                                                                         bundle:self.bundle ];
    self.winZoomer = [ NSWindow windowWithContentViewController:self.schZoomer ];
    self.winZoomer.styleMask &= ~NSResizableWindowMask;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [ self makeMyMenu ];
        [ self makeMyComponents ];
        [ self makeSearchPath ];
        [ self performSelector:@selector( infectXCodeMenu ) withObject:nil afterDelay:0.5 ];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Utils

// Format NSDate into string
-( NSString* )stringFromTimeDate:(NSDate *)date
                      withFormat:(NSString *)pattern
                    withTimeZone:(NSTimeZone *)timeZone {
    NSDateFormatter *dateFormat = [[ NSDateFormatter alloc ] init ];
    dateFormat.timeZone = timeZone;
    [ dateFormat setDateFormat:pattern ];
    NSString *res = [ dateFormat stringFromDate:date ];
    return res;
}

#pragma mark - Save panel

// Show save panel for Image Capture
-( void )showSavePanelWithSuggestFileName:( NSString* )suggestName
                            captureTarget:( SCHMenuOperationTarget )targetId {
    self.targetWindow = [ NSApp keyWindow ];
    
    NSScrollView *targetScrollview = nil;
    NSString *title = nil;
    switch ( targetId ) {
        case kSCHOperationChupAnhStoryboard:
            targetScrollview = [ self searchForTargetScrollViewWithPath:self.arrStoryboardPath
                                                        contentViewType:self.arrStoryboardIdentifiers ];
            title = [ NSString stringWithFormat:@"Save Capture of [%@]", self.targetWindow.title ];
            break;
        case kSCHOperationChupAnhProjectTree:
            targetScrollview = [ self searchForTargetScrollViewWithPath:self.arrPrjTreePath
                                                        contentViewType:self.arrPrjTreeIdentifiers ];
            title = @"Save Capture of Project tree";
            break;
        default:
            break;
    }
    [ self fitWindowToTargetScrollview:targetScrollview ];
    [ self.savePanelAccessoryView showSavePanelWithTitle:title
                                            panelMessage:@"Set output file (not including extension)"
                                         suggestFileName:[ NSString stringWithFormat:@"%@ %@",
                                                          suggestName,
                                                          [ self stringFromTimeDate:[ NSDate date ]
                                                                         withFormat:@"y-MM-dd HH.mm.ss.SSS"
                                                                       withTimeZone:[ NSTimeZone defaultTimeZone ]]]
                                              onComplete:^(NSString *resultPath) {
                                                  if ( resultPath ) {
                                                      BOOL res = NO;
                                                      switch ( targetId ) {
                                                          case kSCHOperationChupAnhStoryboard:
                                                              res = [ self captureImageOfView:targetScrollview
                                                                                       toFile:resultPath
                                                                                       format:self.savePanelAccessoryView.imageType ];
                                                              break;
                                                          case kSCHOperationChupAnhProjectTree:
                                                              res = [ self captureImageOfView:[ targetScrollview documentView ]
                                                                                       toFile:resultPath
                                                                                       format:self.savePanelAccessoryView.imageType ];
                                                              break;
                                                          default:
                                                              break;
                                                      }
                                                      if ( res ) {
                                                          [[ NSWorkspace sharedWorkspace ] selectFile:resultPath
                                                                             inFileViewerRootedAtPath:@"" ];
                                                      } else {
                                                          NSAlert *alert = [[ NSAlert alloc ] init ];
                                                          alert.alertStyle = NSCriticalAlertStyle;
                                                          alert.messageText = [ NSString stringWithFormat:@"Fail to capture image to\n%@", resultPath ];
                                                          [ alert runModal ];
                                                      }
                                                  }
                                                  [ self restoreWinFrameIfNeeded ];
                                                  self.targetWindow = nil;
                                              }];
}

#pragma mark - Screen shot target view

// Expand window to make editor area showing everything (=> hide all scrollbars)
-( void )fitWindowToTargetScrollview:( NSScrollView* )targetScrollview {
    _isWindowUnlimtedSize = YES;
    NSView *canvasView = [ targetScrollview documentView ];
    self.originalWinFrame = self.targetWindow.frame;
    self.shouldRestoreWinFrame = NO;
    NSSize scrollerSize = NSZeroSize;
    if ([ targetScrollview respondsToSelector:NSSelectorFromString( @"scrollerDimensions" )])
        [[ targetScrollview valueForKey:@"scrollerDimensions" ] sizeValue ];
    if ( canvasView.frame.size.height != targetScrollview.frame.size.height ||
        canvasView.frame.size.width != targetScrollview.frame.size.width ) {
        self.shouldRestoreWinFrame = YES;
        NSRect newFrame = self.targetWindow.frame;
        newFrame.size.height += canvasView.frame.size.height - targetScrollview.frame.size.height + scrollerSize.height;
        newFrame.size.width += canvasView.frame.size.width - targetScrollview.frame.size.width + scrollerSize.width;
        [ self.targetWindow setFrame:newFrame display:YES animate:NO ];
    }
}

// Restore window frame
-( void )restoreWinFrameIfNeeded {
    _isWindowUnlimtedSize = NO;
    if ( self.shouldRestoreWinFrame ) {
        [ self.targetWindow setFrame:self.originalWinFrame
                             display:YES
                             animate:NO ];
    }
}

// Capture image of a view
-( BOOL )captureImageOfView:( NSView* )targetView toFile:( NSString* )path format:( NSBitmapImageFileType )fileType {
    NSBitmapImageRep *bitmap = [ targetView bitmapImageRepForCachingDisplayInRect:targetView.bounds ];
    [ targetView cacheDisplayInRect:targetView.bounds toBitmapImageRep:bitmap ];
    NSData *imageData = [ bitmap representationUsingType:fileType
                                              properties:nil ];
    return [ imageData writeToFile:path
                        atomically:YES ];
}

#pragma mark - Search for target view

// Check current view's class is valid with class name specified in viewPath
-( NSView* )validateView:( NSView* )view withPath:( NSArray* )viewPath currentPathIndex:( NSUInteger )pathId {
    NSString *pathName = [ viewPath objectAtIndex:pathId ];
    if ([ NSStringFromClass([ view class ]) isEqualToString:pathName ]) {
        if ( pathId == [ viewPath count ] - 1 ) {
            return view;
        } else {
            for ( NSView *v in view.subviews ) {
                NSView *resView = [ self validateView:v withPath:viewPath currentPathIndex:pathId + 1 ];
                if ( resView != nil ) {
                    return resView;
                    break;
                }
            }
        }
    }
    return nil;
}

// From the root view of XCode window, search for target scrollview by compare class name of each child view with class name in path
// Also check the scrollview's content view class name to make sure we get right target
-( id )searchForTargetScrollViewWithPath:( NSArray* )path contentViewType:( NSArray* )contentViewClasses {
    if ( self.targetWindow ) {
        NSWindowController *keyWinCtrl = [ self.targetWindow windowController ];
        if ( keyWinCtrl && [ NSStringFromClass([ keyWinCtrl class ]) isEqualToString:@"IDEWorkspaceWindowController" ]) {
            Ivar tabViewIvar = class_getInstanceVariable([ keyWinCtrl class ], "_tabView" );
            if ( tabViewIvar ) {
                NSTabView *tabView = object_getIvar( keyWinCtrl, tabViewIvar );
                if ( tabView && [ tabView.subviews count ] >  0 ) {
                    NSScrollView *scrollView = ( NSScrollView* )[ self validateView:tabView
                                                                           withPath:path
                                                                   currentPathIndex:0 ];
                    if ( scrollView ) {
                        @try {
                            id contentView = [ scrollView documentView ];
                            if ( contentView ) {
                                if ( contentViewClasses && contentViewClasses.count ) {
                                    for ( NSString *className in contentViewClasses ) {
                                        if ([ contentView isKindOfClass:NSClassFromString( className )]) {
                                            return scrollView;
                                            break;
                                        }
                                    }
                                } else {
                                    return scrollView;
                                }
                            }
                        }
                        @catch (NSException *exception) {
                            return nil;
                        }
                    }
                }
            }
        }
    }
    return nil;
}

#pragma mark - Menu action

// Enable menu if we can find target scrollview
-( BOOL )validateMenuItem:(NSMenuItem *)menuItem {
    self.targetWindow = [ NSApp keyWindow ];
    if ( menuItem == self.mnuChupAnhStoryboard ||
        menuItem == self.mnuXuatRaHTML ||
        menuItem == self.mnuSetZoomScale ) {
        return [ self searchForTargetScrollViewWithPath:self.arrStoryboardPath
                                        contentViewType:self.arrStoryboardIdentifiers ] != nil;
    } else if ( menuItem == self.mnuChupAnhPrjTree ) {
        return [ self searchForTargetScrollViewWithPath:self.arrPrjTreePath
                                        contentViewType:self.arrPrjTreeIdentifiers ] != nil;
    }
    return NO;
}

-( void )menuChupAnh_duocChon:( id )sender {
    if ( sender == self.mnuChupAnhStoryboard )
        [ self showSavePanelWithSuggestFileName:[[ NSApp keyWindow ] title ]
                                  captureTarget:kSCHOperationChupAnhStoryboard ] ;
    else if ( sender == self.mnuChupAnhPrjTree ) {
        NSWindowController *windowCtrl = [[ NSApp keyWindow ] windowController ];
        NSString *suggestName = [( NSDocument* )[ windowCtrl document ] displayName ];
        [ self showSavePanelWithSuggestFileName:suggestName ? [ suggestName stringByDeletingPathExtension ] : @""
                                  captureTarget:kSCHOperationChupAnhProjectTree ];
    }
}

-( void )menuZoom_duocChon:( id )sender {
    self.targetWindow = [ NSApp keyWindow ];
    NSScrollView *targetScrollview = [ self searchForTargetScrollViewWithPath:self.arrStoryboardPath
                                                              contentViewType:self.arrStoryboardIdentifiers ];
    NSView *canvasView = [ targetScrollview documentView ];
    NSPoint point = [ self.lastContextMenuEvent locationInWindow ];
    [ self.schZoomer openZoomerWithTargetView:canvasView
                             targetScrollview:targetScrollview
                                  anchorPoint:[ canvasView convertPoint:point fromView:nil ]
                                     onWindow:[ NSApp keyWindow ]];
}

-( void )showError:( NSString* )message {
    NSAlert *alert = [[ NSAlert alloc ] init ];
    alert.alertStyle = NSCriticalAlertStyle;
    alert.messageText = message;
    [ alert runModal ];
}

-( BOOL )createAndValidateDirectory:( NSString* )path {
    NSFileManager *fileMan = [ NSFileManager defaultManager ];
    [ fileMan createDirectoryAtPath:path
        withIntermediateDirectories:YES
                         attributes:nil
                              error:nil ];
    BOOL isDirectory = YES;
    if (![ fileMan fileExistsAtPath:path isDirectory:&isDirectory ]) {
        [ self showError:[ NSString stringWithFormat:@"Can not create directory at path \"%@\".", path ]];
        return NO;
    }
    if ( !isDirectory ) {
        [ self showError:[ NSString stringWithFormat:@"\"%@\" is not directory.", path ]];
        return NO;
    }
    return YES;
}

-( void )exportStoryboardImagesToPath:( NSString* )destinationPath {
    NSScrollView *targetScrollview = [ self searchForTargetScrollViewWithPath:self.arrStoryboardPath
                                                              contentViewType:self.arrStoryboardIdentifiers ];
    NSView *canvasView = [ targetScrollview documentView ];
    NSArray *allCanvasFrames = [ canvasView valueForKey:@"canvasFramesFromBackToFront" ];
    for ( id canvasFrame in allCanvasFrames ) {
        NSString *identifier = [ NSString stringWithFormat:@"VC%p", canvasFrame ];
        NSString *frameImageName = [ NSString stringWithFormat:@"%@.%@", identifier, [ self.exportPanelAccesoryView fileExtensionForCurrentImageType ]];
        [ self captureImageOfView:canvasFrame
                           toFile:[ destinationPath stringByAppendingPathComponent:frameImageName ]
                           format:self.exportPanelAccesoryView.imageType ];
    }
    [[ NSWorkspace sharedWorkspace ] selectFile:destinationPath
                       inFileViewerRootedAtPath:@"" ];
}



-( void )exportStoryboardToPath:( NSString* )destinationPath {
    NSString *imagePath = [ destinationPath stringByAppendingPathComponent:@"images" ];
    if (![ self createAndValidateDirectory:imagePath ]) return;
    NSString *iconsPath = [ destinationPath stringByAppendingPathComponent:@"icons" ];
    if (![ self createAndValidateDirectory:iconsPath ]) return;
    NSArray *seguesColors = @[ @"gray" ];
    if ( self.exportPanelAccesoryView.isNhieuMauDuocChon ) {
        seguesColors = [ NSArray arrayWithContentsOfFile:[ self.bundle pathForResource:@"HTML_Colors"
                                                                                ofType:@"plist" ]];
    }
    
    NSScrollView *targetScrollview = [ self searchForTargetScrollViewWithPath:self.arrStoryboardPath
                                                              contentViewType:self.arrStoryboardIdentifiers ];
    NSView *canvasView = [ targetScrollview documentView ];
    id canvasViewDelegate = [ canvasView valueForKey:@"delegate" ];
    NSMutableDictionary *storyboardInfo = [ NSMutableDictionary dictionary ];
    NSRect canvasViewBounds = [ canvasView bounds ];
    [ storyboardInfo setObject:NSStringFromSize( canvasViewBounds.size )
                        forKey:@"size" ];
    
    NSString *projectName = [[[ self.targetWindow  windowController ] document ] displayName ];
    NSString *author = NSFullUserName();
    NSString *createdDate = [ self stringFromTimeDate:[ NSDate date ]
                                           withFormat:@"y/MM/dd"
                                         withTimeZone:[ NSTimeZone defaultTimeZone ]];
    double zoomeScale = [[ canvasView valueForKey:@"zoomFactor" ] doubleValue ];
    NSString *boardName = [ self.targetWindow title ];
    
    NSString *htmlFramePattern = nil;
    NSString *htmlRadioPattern = nil;
    NSString *htmlSegueIconPattern = nil;
    NSString *jsSeguePattern = nil;
    NSString *cssSeguePattern = nil;
    NSString *cssSegueClassPattern = nil;
    NSString *cssFramePattern = nil;
    
    NSMutableDictionary *allCanvasFramesDic = [ NSMutableDictionary dictionary ];
    NSArray *allCanvasFrames = [ canvasView valueForKey:@"canvasFramesFromBackToFront" ];
    NSMutableString *htmlAllFrames = nil;
    NSMutableString *htmlAllSeuges = nil;
    NSMutableString *htmlAllRadios = nil;
    NSMutableString *jsAllSegues = nil;
    NSMutableString *cssAllSegues = nil;
    NSMutableString *cssAllSegueClasses = nil;
    NSMutableString *cssAllFrames = nil;
    if ( self.exportPanelAccesoryView.isHTMLDuocChon ) {
        htmlAllFrames = [ NSMutableString string ];
        htmlAllSeuges = [ NSMutableString string ];
        htmlAllRadios = [ NSMutableString string ];
        jsAllSegues = [ NSMutableString string ];
        cssAllFrames = [ NSMutableString string ];
        cssAllSegueClasses = [ NSMutableString string ];
        cssAllSegues = [ NSMutableString string ];
        htmlFramePattern = @"    <div id=\"%@\" title=\"%@\" onClick=\"frameViewDidSelected( this );\"></div>\n";
        htmlRadioPattern = @"        <input type=\"radio\" id=\"opt_%@\" name=\"frame\" value=\"%@\" onClick=\"radioButtonDidSelect( this.value );\">%@<br/><hr/>\n";
        htmlSegueIconPattern = @"    <div id=\"%@\" class=\"%@\" title=\"%@\" onClick=\"segueIconDidSelected( this )\"></div>\n";
        jsSeguePattern = @"allSegues[\"%@\"] = { from:\"%@\", to:\"%@\" };\n";
        cssSeguePattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"style_segue"
                                                                                     ofType:@"css" ]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil ];
        cssSegueClassPattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"style_segueClass"
                                                                                          ofType:@"css" ]
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil ];
        cssFramePattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"style_frame"
                                                                                     ofType:@"css" ]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil ];
    }
    
    for ( id canvasFrame in allCanvasFrames ) {
        NSString *identifier = [ NSString stringWithFormat:@"VC%p", canvasFrame ];
        NSMutableDictionary *frameDic = [ NSMutableDictionary dictionary ];
        [ frameDic setObject:identifier forKey:@"identifier" ];
        NSRect frame = [ canvasFrame frame ];
        frame.origin.x -= canvasViewBounds.origin.x;
        frame.origin.y -= canvasViewBounds.origin.y;
        [ frameDic setValue:NSStringFromRect( frame )
                     forKey:@"frame" ];
        NSString *title = [ canvasFrame valueForKey:@"title" ];
        if ( title )[ frameDic setObject:title forKey:@"title" ];
        [ allCanvasFramesDic setObject:frameDic forKey:identifier ];
        NSString *frameImageName = [ NSString stringWithFormat:@"%@.%@", identifier, [ self.exportPanelAccesoryView fileExtensionForCurrentImageType ]];
        [ self captureImageOfView:canvasFrame
                           toFile:[ imagePath stringByAppendingPathComponent:frameImageName ]
                           format:self.exportPanelAccesoryView.imageType ];
        if ( self.exportPanelAccesoryView.isHTMLDuocChon ) {
            [ htmlAllFrames appendFormat:htmlFramePattern, identifier, title ];
            [ htmlAllRadios appendFormat:htmlRadioPattern, identifier, identifier, title ];
            [ cssAllFrames appendFormat:cssFramePattern,
             identifier, frame.origin.y, frame.origin.x, frame.size.width, frame.size.height, frameImageName ];
        }
    }
    
    // Segue
    SEL selector = NSSelectorFromString( @"storyboardCanvasFrameForViewController:" );
    id (*frameViewFromController)( id, SEL, id ) = ( id (*)( id, SEL, id ))class_getMethodImplementation([ canvasViewDelegate class ], selector );
    Ivar segueMapIvar = class_getInstanceVariable([ canvasViewDelegate class ], "_canvasLinkToLinkPathMap" );
    NSDictionary *seguesMap = object_getIvar( canvasViewDelegate, segueMapIvar );
    NSMutableArray *allSeguesArray = [ NSMutableArray array ];
    NSMutableDictionary *seguesIconDic = [ NSMutableDictionary dictionary ];
    for ( id segueLink in seguesMap.allKeys ) {
        NSMutableDictionary *segueDic = [ NSMutableDictionary dictionary ];
        NSString *identifier = [ NSString stringWithFormat:@"S%p", segueLink ];
        [ segueDic setObject:identifier forKey:@"identifier" ];
        id seguePath = [ seguesMap objectForKey:segueLink ];
        NSString *segueClassName = NSStringFromClass([ segueLink class ]);
        [ segueDic setObject:segueClassName forKey:@"class" ];
        NSImage *segueIcon = [ seguePath valueForKey:@"badge" ];
        if ( segueIcon )
            [ seguesIconDic setObject:segueIcon forKey:segueClassName ];
        else if (![ seguesIconDic.allKeys containsObject:segueClassName ])
            [ seguesIconDic setObject:[ NSNull null ] forKey:segueClassName ];
        
        id source = [ segueLink valueForKey:@"canvasLinkSource" ];
        id sourceFrame = source ? frameViewFromController( canvasViewDelegate, selector, source ) : nil;
        NSString *sourceFrameId = sourceFrame ? [ NSString stringWithFormat:@"VC%p", sourceFrame ] : nil;
        id destination = [ segueLink valueForKey:@"canvasLinkDestination" ];
        id destinationFrame = destination ? frameViewFromController( canvasViewDelegate, selector, destination ) : nil;
        NSString *destFrameId = destinationFrame ? [ NSString stringWithFormat:@"VC%p", destinationFrame ] : nil;
        if ( sourceFrameId )[ segueDic setObject:sourceFrameId forKey:@"source" ];
        if ( destFrameId )[ segueDic setObject:destFrameId forKey:@"destination" ];
        [ allSeguesArray addObject:segueDic ];
        [ jsAllSegues appendFormat:jsSeguePattern, identifier, sourceFrameId ? sourceFrameId : @"", destFrameId ? destFrameId : @"" ];
        [ cssAllSegues appendFormat:cssSeguePattern, identifier, segueIcon ? segueIcon.size.width : 0, segueIcon ? segueIcon.size.height : 0 ];
        [ htmlAllSeuges appendFormat:htmlSegueIconPattern, identifier, segueClassName,  segueClassName ];
    }
    NSInteger colorId = 0;
    for ( NSString *segueName in seguesIconDic.allKeys ) {
        NSImage *segueIcon = [ seguesIconDic objectForKey:segueName ];
        NSString *iconName = @"";
        if (![ segueIcon isEqual:[ NSNull null ]]) {
            iconName = [ NSString stringWithFormat:@"%@.%@", segueName, [ self.exportPanelAccesoryView fileExtensionForCurrentImageType ]];
            CGRect rect = NSMakeRect( 0, 0, segueIcon.size.width, segueIcon.size.height );
            NSBitmapImageRep *bitmap = [[ NSBitmapImageRep alloc ] initWithCGImage:[ segueIcon CGImageForProposedRect:&rect
                                                                                                              context:nil
                                                                                                                hints:nil ]];
            NSData *data = [ bitmap representationUsingType:self.exportPanelAccesoryView.imageType
                                                 properties:nil ];
            [ data writeToFile:[ iconsPath stringByAppendingPathComponent:iconName ] atomically:YES ];
        }
        [ cssAllSegueClasses appendFormat:cssSegueClassPattern, segueName, iconName, [ seguesColors objectAtIndex:colorId ]];
        colorId += 1;
        if ( colorId >= seguesColors.count ) colorId = 0;
    }
    [ storyboardInfo setObject:allCanvasFramesDic forKey:@"view" ];
    [ storyboardInfo setObject:allSeguesArray forKey:@"segue" ];
    // Write to file
    if ( self.exportPanelAccesoryView.isHTMLDuocChon ) {
        NSString *pattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"drawing"
                                                                                       ofType:@"js" ]
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil ];
        NSString *content = [ NSString stringWithFormat:pattern, projectName, author, createdDate, zoomeScale, jsAllSegues ];
        [ content writeToFile:[ destinationPath stringByAppendingPathComponent:@"drawing.js" ]
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil ];
        pattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"selection"
                                                                             ofType:@"js" ]
                                             encoding:NSUTF8StringEncoding
                                                error:nil ];
        content = [ NSString stringWithFormat:pattern, projectName, author, createdDate ];
        [ content writeToFile:[ destinationPath stringByAppendingPathComponent:@"selection.js" ]
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil ];
        pattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"styles"
                                                                             ofType:@"css" ]
                                             encoding:NSUTF8StringEncoding
                                                error:nil ];
        content = [ NSString stringWithFormat:pattern, projectName, author, createdDate, cssAllSegueClasses, cssAllSegues, canvasViewBounds.size.width, canvasViewBounds.size.height, cssAllFrames ];
        [ content writeToFile:[ destinationPath stringByAppendingPathComponent:@"styles.css" ]
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil ];
        pattern = [ NSString stringWithContentsOfFile:[ self.bundle pathForResource:@"index"
                                                                             ofType:@"html" ]
                                             encoding:NSUTF8StringEncoding
                                                error:nil ];
        content = [ NSString stringWithFormat:pattern, projectName, author, createdDate, boardName, htmlAllSeuges, htmlAllFrames, projectName, boardName, htmlAllRadios ];
        [ content writeToFile:[ destinationPath stringByAppendingPathComponent:@"index.html" ]
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil ];
    }
    if ( self.exportPanelAccesoryView.isPLISTDuocChon ) {
        [ storyboardInfo writeToFile:[ destinationPath stringByAppendingPathComponent:@"info.plist" ]
                          atomically:YES ];
    }
    if ( self.exportPanelAccesoryView.isJSONDuocChon ){
        NSData *data = [ NSJSONSerialization dataWithJSONObject:storyboardInfo
                                                        options:0
                                                          error:nil ];
        [ data writeToFile:[ destinationPath stringByAppendingPathComponent:@"info.json" ]
                atomically:YES ];
    }
    [[ NSWorkspace sharedWorkspace ] selectFile:destinationPath
                       inFileViewerRootedAtPath:@"" ];
}

-( void )menuXuatRaHTML_duocChon:( id )sender {
    self.targetWindow = [ NSApp keyWindow ];
    [ self.exportPanelAccesoryView showSavePanelWithTitle:@"Export all frames"
                                             panelMessage:@"Enter the name of folder which will be created to store images"
                                          suggestFileName:[ NSString stringWithFormat:@"%@ %@",
                                                           [[ NSApp keyWindow ] title ],
                                                           [ self stringFromTimeDate:[ NSDate date ]
                                                                          withFormat:@"y-MM-dd HH.mm.ss.SSS"
                                                                        withTimeZone:[ NSTimeZone defaultTimeZone ]]]
                                               onComplete:^(NSString *resultPath) {
                                                   if ( resultPath ) {
                                                       resultPath = [ resultPath stringByDeletingPathExtension ];
                                                       if ([ self createAndValidateDirectory:resultPath ]) {
                                                           if ( self.exportPanelAccesoryView.isHTMLDuocChon ||
                                                               self.exportPanelAccesoryView.isJSONDuocChon ||
                                                               self.exportPanelAccesoryView.isPLISTDuocChon )
                                                               [ self exportStoryboardToPath:resultPath ];
                                                           else
                                                               [ self exportStoryboardImagesToPath:resultPath ];
                                                       }
                                                   }
                                               }];
    return;
}

@end
