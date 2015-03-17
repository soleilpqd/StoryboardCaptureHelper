//
//  SCHImageSavePanelAccessoryViewController.m
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 04/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import "SCHImageSavePanelAccessoryViewController.h"

NSString * const kSCHConfigKeyImgType       = @"SCH_IMG_TYPE";
NSString * const kSCHConfigKeyLastFolder    = @"SCH_SAVE_DIR";

@interface SCHImageSavePanelAccessoryViewController ()

@end

@implementation SCHImageSavePanelAccessoryViewController

-( NSString* )fileExtensionForCurrentImageType {
    switch ( _imageType ) {
        case NSJPEGFileType:
        case NSJPEG2000FileType:
            return @"jpg";
            break;
        case NSPNGFileType:
            return @"png";
            break;
        case NSGIFFileType:
            return @"gif";
            break;
        case NSBMPFileType:
            return @"bmp";
            break;
        case NSTIFFFileType:
            return @"tif";
            break;
        default:
            break;
    }
    return nil;
}

-( void )capNhatNutKieuAnh {
    switch ( _imageType ) {
        case NSJPEGFileType:
        case NSJPEG2000FileType:
            [ self.pubType selectItemAtIndex:0 ];
            break;
        case NSPNGFileType:
            [ self.pubType selectItemAtIndex:1 ];
            break;
        case NSGIFFileType:
            [ self.pubType selectItemAtIndex:2 ];
            break;
        case NSBMPFileType:
            [ self.pubType selectItemAtIndex:3 ];
            break;
        case NSTIFFFileType:
            [ self.pubType selectItemAtIndex:4 ];
            break;
        default:
            break;
    }
}

-( IBAction)pubType_khiDuocChon:( id )sender {
    switch ( self.pubType.indexOfSelectedItem ) {
        case 0:
            _imageType = NSJPEGFileType;
            break;
        case 1:
            _imageType = NSPNGFileType;
            break;
        case 2:
            _imageType = NSGIFFileType;
            break;
        case 3:
            _imageType = NSBMPFileType;
            break;
        case 4:
            _imageType = NSTIFFFileType;
            break;
        default:
            break;
    }
}

-( void )setImageType:(NSBitmapImageFileType)imageType {
    _imageType = imageType;
    [ self capNhatNutKieuAnh ];
}

-( void )saveConfigWithDestinationPath:(NSString *)destination {
    [[ NSUserDefaults standardUserDefaults ] setObject:[ destination stringByDeletingLastPathComponent ]
                                                forKey:kSCHConfigKeyLastFolder ];
    [[ NSUserDefaults standardUserDefaults ] setObject:[ NSNumber numberWithUnsignedInteger:self.imageType ]
                                                forKey:kSCHConfigKeyImgType ];
}

-( void )showSavePanelWithTitle:(NSString *)title
                   panelMessage:(NSString *)message
                suggestFileName:(NSString *)fileName
                     onComplete:(void (^)( NSString* ))completion {
    if ( _savePanel == nil ) {
        _savePanel = [ NSSavePanel savePanel ];
        _savePanel.canCreateDirectories = YES;
        _savePanel.allowsOtherFileTypes = NO;
        _savePanel.accessoryView = self.view;
    }
    _savePanel.message = message;
    _savePanel.title =  title;
    
    NSNumber *lastImgType = [[ NSUserDefaults standardUserDefaults ] objectForKey:kSCHConfigKeyImgType ];
    if ( lastImgType )
        [ self setImageType:[ lastImgType unsignedIntegerValue ]];
    else
        [ self setImageType:NSJPEGFileType ];
    
    NSString *defaultFolder = [[ NSUserDefaults standardUserDefaults ] objectForKey:kSCHConfigKeyLastFolder ];
    if ( defaultFolder == nil || ![[ NSFileManager defaultManager ] fileExistsAtPath:defaultFolder ])
        defaultFolder = [ NSHomeDirectory() stringByAppendingPathComponent:@"Pictures" ];
    [ _savePanel setDirectoryURL:[ NSURL fileURLWithPath:defaultFolder ]];
    [ _savePanel setNameFieldStringValue:fileName ];
    [ _savePanel beginSheetModalForWindow:[ NSApp keyWindow ]
                        completionHandler:^(NSInteger result) {
        NSString *destination = nil;
        if ( result ) {
            destination = [ NSString stringWithFormat:@"%@.%@",
                           [[ NSString stringWithUTF8String:[ _savePanel.URL fileSystemRepresentation ]] stringByDeletingPathExtension ],
                           [ self fileExtensionForCurrentImageType ]];
            [ self saveConfigWithDestinationPath:destination ];
        }
        if (  completion ) completion( destination );
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-( void )viewWillAppear {
    [ super viewWillAppear ];
    [ self capNhatNutKieuAnh ];
}

@end
