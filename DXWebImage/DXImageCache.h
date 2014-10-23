//
//  ERImageCache.h
//  ScrollView
//
//  Created by TalkWeb on 14-10-18.
//  Copyright (c) 2014年 TalkWeb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    /**
     *  下载
     */
    ImageCacheTypeNone =0,
    /**
     *  磁盘
     */
    ImageCacheTypeTypeDisk,
    /**
     *  内存
     */
    ImageCacheTypeMemory
} ImageCacheType;

@interface DXImageCache : NSObject
/**
 *  缓存存在的时间
 */
@property (assign ,nonatomic) NSInteger maxCacheAge;
/**
 *  缓存大小
 */
@property (assign ,nonatomic) unsigned long long maxCacheSize;
/**
 *  图片缓存的单例
 */
+ (DXImageCache *)sharedImageCache;

/**
 * 暂未用
 * Add a read-only cache path to search for images pre-cached by SDImageCache
 * Useful if you want to bundle pre-loaded images with your app
 *
 * @param path The path to use for this read-only cache path
 */
- (void)addReadOnlyCachePath:(NSString *)path;
/**
 * 存储图片到缓存和磁盘上
 *
 * @param 需要处理的图片
 * @param 缓存图片的键值
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

/**
 * 存储图片到缓存中，可选择是否存储到磁盘
 *
 * @param 需要处理的图片
 * @param 缓存图片的键值
 * @param YES 存储到磁盘
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * 存储图片 给定一个key 存储到内存，也可选择是否存储到磁盘
 *
 * @param 需要存储的图片
 * @param 图像数据 该属性使用需要把toDisk设为YES 表示存储与磁盘
 * @param 图片缓存的键值，通常用其绝对的URL
 * @param YES 存储到磁盘
 */
- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * 异步查询获取图片  先查询内存后磁盘
 *
 * @param 缓存图片的key
 */
- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(void (^)(UIImage *image, ImageCacheType cacheType))doneBlock;

/**
 * 同步获取图片 只在内存中查找
 *
 * @param  缓存图片的key
 */
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key;
/**
 * 同步获取图片 先查找内存 如果内存中不存在则在磁盘中读取
 *
 * @param 缓存图片的key
 */
- (UIImage *)imageFromDiskCacheForKey:(NSString *)key;
/**
 * 删除缓存的图片 同时删除磁盘对应的图片
 *
 * @param 缓存图片的key
 */
- (void)removeImageForKey:(NSString *)key;
/**
 * 删除缓存中图片 同时是否删除磁盘对应的图片
 *
 * @param 缓存图片的key
 * @param YES 删除磁盘中对应的图片
 */
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;
/**
 *  获取缓存图片的数量
 */
- (int)getDiskCount;
/**
 *  缓存数据的大小
 */
- (unsigned long long)getSize;
/**
 *  异步获取缓存数据的大小
 */
- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, unsigned long long totalSize))completionBlock;
@end
