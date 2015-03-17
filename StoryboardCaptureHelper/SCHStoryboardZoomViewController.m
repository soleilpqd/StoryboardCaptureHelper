//
//  SCHStoryboardZoomViewController.m
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 12/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import "SCHStoryboardZoomViewController.h"
#import <objc/runtime.h>

NSString * const kSCHConfigKeyIsLiveZooming    = @"SCH_LIVE_ZOOM";

@interface SCHStoryboardZoomViewController ()

@property (weak) IBOutlet NSSlider *sldScale;
@property (weak) IBOutlet NSTextField *txfScale;
@property (weak) IBOutlet NSButton *btnCheckLiveZooming;
@property (weak) IBOutlet NSButton *btnApply;

@property (weak) id canvasView;
@property (weak) id canvasScrollview;
@property (assign) CGPoint anchorPoint;

@end

@implementation SCHStoryboardZoomViewController

-( void )applyLiveZoom {
    self.btnApply.enabled = !( self.btnCheckLiveZooming.state == NSOnState );
    [[ NSUserDefaults standardUserDefaults ] setInteger:self.btnCheckLiveZooming.state
                                                 forKey:kSCHConfigKeyIsLiveZooming ];
}

-( void )doZooming {
    id canvasDelegate = [ self.canvasView valueForKey:@"delegate" ];
    Class targetClass = NSClassFromString( @"IBStoryboardCanvasViewController" );
    SEL selector = NSSelectorFromString( @"zoomToFactor:anchor:animated:userInitiated:" );
    if ( targetClass && selector && canvasDelegate ) {
        void (*original)( id, SEL, double, CGPoint, bool, bool ) =
        ( void(*)( id, SEL, double, CGPoint, bool, bool ))class_getMethodImplementation( targetClass, selector );
        if ( original  ) {
            original( canvasDelegate, selector,
                     self.txfScale.doubleValue, self.anchorPoint,
                     ( self.btnCheckLiveZooming.state != NSOnState ), 0 );
        } else {
            NSLog( @"Implement not found" );
        }
    } else {
        NSLog( @"IBStoryboardCanvasViewController not found" );
    }
}

-( void )openZoomerWithTargetView:(id)canvasView
                 targetScrollview:(id)canvasScrollview
                      anchorPoint:(CGPoint)targetPoint
                         onWindow:(NSWindow *)targetWindow {
    self.canvasView = canvasView;
    self.canvasScrollview = canvasScrollview;
    self.anchorPoint = targetPoint;
    id canvasDelegate = [ canvasView valueForKey:@"delegate" ];
    double minFactor = [[ canvasDelegate valueForKey:@"minPreferredZoomFactor" ] doubleValue ];
    double maxFactor = [[ canvasDelegate valueForKey:@"maxPreferredZoomFactor" ] doubleValue ];
    self.sldScale.minValue = minFactor;
    self.sldScale.maxValue = maxFactor;
    [( NSNumberFormatter* )self.txfScale.formatter setMinimum:@( minFactor )];
    [( NSNumberFormatter* )self.txfScale.formatter setMaximum:@( maxFactor )];
    double currentFactor = [[ canvasView valueForKey:@"zoomFactor" ] doubleValue ];
    self.sldScale.doubleValue = currentFactor;
    self.txfScale.doubleValue = currentFactor;
    [ targetWindow beginSheet:self.view.window
                completionHandler:nil ];
}

- (IBAction)btnApply_onTap:(NSButton *)sender {
    [ self doZooming ];
}

- (IBAction)btnClose_onTap:(NSButton *)sender {
    [ self.view.window.sheetParent endSheet:self.view.window
                     returnCode:0 ];
}

- (IBAction)btnCheck_onTap:(NSButton *)sender {
    [ self applyLiveZoom ];
}

- (IBAction)txfScale_onChanged:(NSTextField *)sender {
    self.sldScale.doubleValue = self.txfScale.doubleValue;
    [ self doZooming ];
}

- (IBAction)sldScale_onChanged:(NSSlider *)sender {
    self.txfScale.doubleValue = self.sldScale.doubleValue;
    if ( self.btnCheckLiveZooming.state == NSOnState ) {
        [ self doZooming ];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSNumber *num = [[ NSUserDefaults standardUserDefaults ] objectForKey:kSCHConfigKeyIsLiveZooming ];
    if ( num )
        self.btnCheckLiveZooming.state = [ num integerValue ];
    else
        self.btnCheckLiveZooming.state = NSOffState;
    [( NSNumberFormatter* )self.txfScale.formatter setNumberStyle:NSNumberFormatterPercentStyle ];
//    [( NSNumberFormatter* )self.txfScale.formatter setAllowsFloats:NO ];
    [( NSNumberFormatter* )self.txfScale.formatter setMaximumFractionDigits:0 ];
    self.sldScale.altIncrementValue = 1.0f;
    [ self applyLiveZoom ];
}

@end
