//
//  StoryboardCaptureHelper.h
//  StoryboardCaptureHelper
//
//  Created by Phạm Quang Dương on 03/03/2015.
//  Copyright (c) Năm 2015 DuongPQ. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface StoryboardCaptureHelper : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end