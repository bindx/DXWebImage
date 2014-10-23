//
//  UIImageView+Web.m
//  networktest
//
//  Created by Bindx on 14/9/27.
//  Copyright (c) 2014年 Bindx. All rights reserved.
//

#import "UIImageView+Web.h"
#import "DXWebImageOperation.h"
#import "DXImageCache.h"

@interface UIImageView()

@end

@implementation UIImageView(Web)

- (void)setImageWithURL:(NSString *)url{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder{
    [self setImageWithURL:url placeholderImage:placeholder options:WebImageRetryNone];
}
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder options:(WebImageOptions)options{
    __block DXImageCache *imageCache = [DXImageCache sharedImageCache];
    self.image = placeholder;
    [imageCache queryDiskCacheForKey:url done:^(UIImage *image, ImageCacheType cacheType) {
        NSLog(@"%@",NSHomeDirectory());
        switch (cacheType) {
            case ImageCacheTypeNone:{
                NSLog(@"None");
            }break;
            case ImageCacheTypeMemory:{
                NSLog(@"内存");
            }break;
            case ImageCacheTypeTypeDisk:{
                NSLog(@"磁盘");
            }break;
            default:
                break;
        }
        
        if(image){
            self.image =image;
            return ;
        }
        [self downloadImage:url];
    }];
    return;
    switch (options) {
        case WebImageRetryNone:{
        
        }break;
        case WebImageRetryFailed:{
        
        }break;
        case WebImageLowPriority:{
            
        }break;
        case WebImageCacheMemoryOnly:{
            
        }break;
        case WebImageProgressiveDownload:{

        }break;
        default:
            break;
//TODO: 未完成
    }
}
-(void)downloadImage:(NSString *)url
{
    DXWebImageOperation * imagedownld = [[DXWebImageOperation alloc]initWithURLString:[NSURL URLWithString:url] Withblock:^(UIImage *image) {
        self.image = image;
        [[DXImageCache sharedImageCache] storeImage:image forKey:url];
        NSLog(@"URL下载");
    }];
    NSOperationQueue * operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue addOperation:imagedownld];
}


@end
