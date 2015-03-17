//
//  SCHExportSavePanelAccessoryViewController.h
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 15/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import "SCHImageSavePanelAccessoryViewController.h"

@interface SCHExportSavePanelAccessoryViewController : SCHImageSavePanelAccessoryViewController

@property ( nonatomic, weak ) IBOutlet NSButton *btnChonHTML;
@property ( nonatomic, weak ) IBOutlet NSButton *btnChonJSON;
@property ( nonatomic, weak ) IBOutlet NSButton *btnChonPLIST;
@property ( nonatomic, weak ) IBOutlet NSButton *btnChonNhieuMau;

@property ( nonatomic, readonly ) BOOL isHTMLDuocChon;
@property ( nonatomic, readonly ) BOOL isJSONDuocChon;
@property ( nonatomic, readonly ) BOOL isPLISTDuocChon;
@property ( nonatomic, readonly ) BOOL isNhieuMauDuocChon;

@end
