//
//  SCHExportSavePanelAccessoryViewController.m
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 15/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import "SCHExportSavePanelAccessoryViewController.h"

NSString * const kSCHConfigKeyExportHTML    = @"SCH_EXPORT_HTML";
NSString * const kSCHConfigKeyExportJSON    = @"SCH_EXPORT_JSON";
NSString * const kSCHConfigKeyExportPLIST   = @"SCH_EXPORT_PLIST";
NSString * const kSCHConfigKeyExportNhieuMau   = @"SCH_EXPORT_MULTI_COLORS";

@interface SCHExportSavePanelAccessoryViewController ()

@end

@implementation SCHExportSavePanelAccessoryViewController

-( IBAction )btnCheckHTML_khiDuocClick:( NSButton* )sender {
    _isHTMLDuocChon = ( self.btnChonHTML.state == NSOnState );
    self.btnChonNhieuMau.enabled = _isHTMLDuocChon;
}

-( IBAction )btnCheckJSON_khiDuocClick:( NSButton* )sender {
    _isJSONDuocChon = ( self.btnChonJSON.state == NSOnState );
}

-( IBAction )btnCheckPLIST_khiDuocClick:( NSButton* )sender {
    _isPLISTDuocChon = ( self.btnChonPLIST.state == NSOnState );
}

-( IBAction )btnChonNhieuMau_khiDuocClick:( NSButton* )sender {
    _isNhieuMauDuocChon = ( self.btnChonNhieuMau.state == NSOnState );
}

-( void )saveConfigWithDestinationPath:(NSString *)destination {
    [ super saveConfigWithDestinationPath:destination ];
    NSUserDefaults *configurator = [ NSUserDefaults standardUserDefaults ];
    [ configurator setBool:self.isHTMLDuocChon forKey:kSCHConfigKeyExportHTML ];
    [ configurator setBool:self.isJSONDuocChon forKey:kSCHConfigKeyExportJSON ];
    [ configurator setBool:self.isPLISTDuocChon forKey:kSCHConfigKeyExportPLIST ];
    [ configurator setBool:self.isNhieuMauDuocChon forKey:kSCHConfigKeyExportNhieuMau ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *configurator = [ NSUserDefaults standardUserDefaults ];
    NSNumber *value = [ configurator objectForKey:kSCHConfigKeyExportHTML ];
    if ( value )
        _isHTMLDuocChon = [ value boolValue ];
    else
        _isHTMLDuocChon = NO;
    self.btnChonNhieuMau.enabled = _isHTMLDuocChon;
    self.btnChonHTML.state = _isHTMLDuocChon ? NSOnState : NSOffState;
    value = [ configurator objectForKey:kSCHConfigKeyExportJSON ];
    if ( value )
        _isJSONDuocChon = [ value boolValue ];
    else
        _isJSONDuocChon = NO;
    self.btnChonJSON.state = _isJSONDuocChon ? NSOnState : NSOffState;
    value = [ configurator objectForKey:kSCHConfigKeyExportPLIST ];
    if ( value )
        _isPLISTDuocChon = [ value boolValue ];
    else
        _isPLISTDuocChon = NO;
    self.btnChonPLIST.state = _isPLISTDuocChon ? NSOnState : NSOffState;
    value = [ configurator objectForKey:kSCHConfigKeyExportNhieuMau ];
    if ( value )
        _isNhieuMauDuocChon = [ value boolValue ];
    else
        _isNhieuMauDuocChon = NO;
    self.btnChonNhieuMau.state = _isNhieuMauDuocChon ? NSOnState : NSOffState;
}

@end
