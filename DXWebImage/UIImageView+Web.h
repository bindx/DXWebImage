//
//  UIImageView+Web.h
//  networktest
//
//  Created by Bindx on 14/9/27.
//  Copyright (c) 2014年 Bindx. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, WebImageOptions){
    WebImageRetryNone = 1 << 0,
    WebImageRetryFailed = 1 << 1,
    WebImageLowPriority = 1 << 2,
    WebImageCacheMemoryOnly = 1 << 3,
    WebImageProgressiveDownload = 1 << 4
};

@interface UIImageView(Web)

/**
 * 下载图片，不支持显示默认图片
 *
 * @param url 图片的下载URL
 */
- (void)setImageWithURL:(NSString *)url;
/**
 * 下载图片并且可以设置默认图片（推荐）
 *
 * @param url 图片的下载URL
 *
 * @param placeholder 默认显示的图片
 */
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder;
/**
 * 下载图片并且可以设置默认图片
 *
 * @param url 图片的下载URL
 *
 * @param placeholder 默认显示的图片
 *
 * @param options 获取图片的模式(暂无效，与setImageWithURL:placeholderImage:同功能)
 */
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder options:(WebImageOptions)options;
#pragma mark - 以下的方法暫未实现
/**
 * 删除指定的图片缓存，同时删除磁盘的图片
 *
 * @param url 图片的下载URL
 */
- (void)removeImageWithURL:(NSString *)url;
/**
 * 只删除指定的图片缓存
 *
 * @param url 图片的下载URL
 */
- (void)removeImageCacheWithURL:(NSString *)url;
/**
 * 删除指定的图片缓存，选着是否删除磁盘的图片
 *
 * @param url 图片的下载URL
 *
 * @param toDisk YES 删除磁盘中的图片
 */
- (void)removeImageCacheWithURL:(NSString *)url toDisk:(BOOL)toDisk;
/**
 * 删除全部的图片缓存和磁盘图片
 */
- (void)removeAllImage;

@end
