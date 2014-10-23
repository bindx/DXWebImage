//
//  DXWebImageOperation.h
//  DXWebImage
//
//  Created by Bindx on 9/28/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DXImageDownloaderDelegate

@optional
- (void)imageDidFinished:(UIImage *)image;
- (void)imageDidError:(NSError *)error;

@end

typedef  void (^DXImageDownloadComplete)(UIImage *image);

@interface DXWebImageOperation : NSOperation

@property (nonatomic, assign) id<DXImageDownloaderDelegate> delegate;
@property (nonatomic, copy  ) DXImageDownloadComplete   downloadComplete;

+ (id)statusWithURLString:(NSURL *)url Withblock:(DXImageDownloadComplete)block;
+ (id)statusWithURLString:(NSURL *)url Withdelegate:(id<DXImageDownloaderDelegate>)delegate;


- (id)initWithURLString:(NSURL *)url Withblock:(DXImageDownloadComplete)block;
- (id)initWithURLString:(NSURL *)url Withdelegate:(id<DXImageDownloaderDelegate>)delegate;
- (id)initWithURLString:(NSURL *)url WithBlock:(DXImageDownloadComplete)block Withdelegate:(id<DXImageDownloaderDelegate>)delegate;

@end

