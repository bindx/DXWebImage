//
//  ERImageCache.m
//
//
//  Created by Bindx on 14-10-18.
//  Copyright (c) 2014年 Bindx. All rights reserved.
//

#import "DXImageCache.h"
#import <mach/mach.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach/mach_host.h>
#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread])\
{\
block();\
}\
else\
{\
dispatch_sync(dispatch_get_main_queue(), block);\
}
static const NSInteger kDefaultMaxCacheAge = 60 * 60 * 24 * 7;//1 周

@interface DXImageCache ()
@property (strong ,nonatomic) NSCache *memCache;
@property (strong ,nonatomic) NSString *diskCachePath;
@property (strong ,nonatomic) NSMutableArray *customPaths;
@property (strong, nonatomic) dispatch_queue_t ioQueue;

@end

@implementation DXImageCache
+(DXImageCache *)sharedImageCache
{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance =self.new;
    });
    return instance;
}
- (id)init
{
    return [self initWithNamespace:@"default"];
}
-(id)initWithNamespace:(NSString *)suffix
{
    if(self=[super init]){
        NSString *fullNamespace = [@"com.apricot.ERImageCache." stringByAppendingString:suffix];
        _ioQueue = dispatch_queue_create("com.apricot.ERImageCache", DISPATCH_QUEUE_SERIAL);
        
        _maxCacheAge = kDefaultMaxCacheAge;
        //实例化NSCache对象
        _memCache = [[NSCache alloc] init];
        _memCache.name =fullNamespace;
        //当前指定图片存储的路径
        _diskCachePath =[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                              NSUserDomainMask,
                                                              YES) lastObject] stringByAppendingPathComponent:fullNamespace];
#if TARGET_OS_IPHONE
        //内存警告
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        //
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        //
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
    }
    return self;
}
#pragma mark - 存储图片
- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (!image || !key)
    {
        return;
    }
    
    [self.memCache setObject:image forKey:key cost:image.size.height * image.size.width * image.scale];
    
    if (toDisk)
    {
        dispatch_async(self.ioQueue, ^
                       {
                           NSData *data = imageData;
                           if (!data)
                           {
                               if (image)
                               {
#if TARGET_OS_IPHONE
                                   data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
#else
                                   data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
                               }
                           }
                           
                           if (data)
                           {
                               // Can't use defaultManager another thread
                               NSFileManager *fileManager = NSFileManager.new;
                               
                               if (![fileManager fileExistsAtPath:_diskCachePath])
                               {
                                   [fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                               }
                               
                               [fileManager createFileAtPath:[self defaultCachePathForKey:key] contents:data attributes:nil];
                           }
                       });
    }
}
- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    [self storeImage:image imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk];
}
#pragma mark

- (void)addReadOnlyCachePath:(NSString *)path
{
    if (!self.customPaths)
    {
        self.customPaths = NSMutableArray.new;
    }
    
    if (![self.customPaths containsObject:path])
    {
        [self.customPaths addObject:path];
    }
}
- (void)removeImageForKey:(NSString *)key
{
    [self removeImageForKey:key fromDisk:YES];
}
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk
{
    if (key == nil)
    {
        return;
    }
    
    [self.memCache removeObjectForKey:key];
    
    if (fromDisk)
    {
        dispatch_async(self.ioQueue, ^
                       {
                           [[NSFileManager defaultManager] removeItemAtPath:[self defaultCachePathForKey:key] error:nil];
                       });
    }
}
#pragma mark ERImageCache(Private)
//MD5
- (NSString *)cachedFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL)
    {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}
//拼接对应的PATH
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path
{
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}
//获取图片本地的PATH
- (NSString *)defaultCachePathForKey:(NSString *)key
{
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (unsigned long long)getSize
{
    unsigned long long size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}
- (int)getDiskCount
{
    int count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSLog(@"%@",fileName);
        count += 1;
    }
    
    return count;
}
- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, unsigned long long totalSize))completionBlock
{
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    dispatch_async(self.ioQueue, ^
                   {
                       NSUInteger fileCount = 0;
                       unsigned long long totalSize = 0;
                       
                       NSFileManager *fileManager = [NSFileManager defaultManager];
                       NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheURL
                                                                 includingPropertiesForKeys:@[ NSFileSize ]
                                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                               errorHandler:NULL];
                       
                       for (NSURL *fileURL in fileEnumerator)
                       {
                           NSNumber *fileSize;
                           [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
                           totalSize += [fileSize unsignedLongLongValue];
                           fileCount += 1;
                       }
                       
                       if (completionBlock)
                       {
                           dispatch_main_sync_safe(^
                                                   {
                                                       completionBlock(fileCount, totalSize);
                                                   });
                       }
                   });
}

#pragma mark 读取图片
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key
{
    return [self.memCache objectForKey:key];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key
{
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image)
    {
        return image;
    }
    
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage)
    {
        CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }
    
    return diskImage;
}
//磁盘中读取imageData
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key
{
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data)
    {
        return data;
    }
    
    for (NSString *path in self.customPaths)
    {
        NSString *filePath = [self cachePathForKey:key inPath:path];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData) {
            return imageData;
        }
    }
    
    return nil;
}
- (UIImage *)diskImageForKey:(NSString *)key
{
    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    if (data) {
        UIImage *image = [[UIImage alloc] initWithData:data];
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        {
            CGFloat scale = 1.0;
            if (key.length >= 8)
            {
                // Search @2x. at the end of the string, before a 3 to 4 extension length (only if key len is 8 or more @2x. + 4 len ext)
                NSRange range = [key rangeOfString:@"@2x." options:0 range:NSMakeRange(key.length - 8, 5)];
                if (range.location != NSNotFound)
                {
                    scale = 2.0;
                }
            }
            
            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
//        image = [UIImage decodedImageWithImage:image];
        return image;
    } else {
        return nil;
    }
}
-(NSOperation *)queryDiskCacheForKey:(NSString *)key done:(void (^)(UIImage *, ImageCacheType))doneBlock
{
    NSOperation *operation = NSOperation.new;
    
    if (!doneBlock) return nil;
    
    if (!key)
    {
        doneBlock(nil, ImageCacheTypeNone);
        return nil;
    }
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image)
    {
        doneBlock(image, ImageCacheTypeMemory);
        return nil;
    }
    
    dispatch_async(self.ioQueue, ^
                   {
                       if (operation.isCancelled)
                       {
                           return;
                       }
                       
                       @autoreleasepool
                       {
                           UIImage *diskImage = [self diskImageForKey:key];
                           if (diskImage)
                           {
                               CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
                               [self.memCache setObject:diskImage forKey:key cost:cost];
                           }else{
                               doneBlock(nil,ImageCacheTypeNone);
                               return;
                           }
                           
                           dispatch_main_sync_safe(^
                                                   {
                                                       doneBlock(diskImage, ImageCacheTypeTypeDisk);
                                                   });
                       }
                   });
    
    return operation;
}



#pragma mark - 通知调用的方法
-(void)clearMemory
{
    [self.memCache removeAllObjects];
}
-(void)clearDisk
{
    dispatch_async(self.ioQueue, ^
                   {
                       [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
                       [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:NULL];
                   });
}
-(void)cleanDisk
{
    dispatch_async(self.ioQueue, ^{
        
    });
}
- (void)backgroundCleanDisk
{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^
                                                 {
                                                     [application endBackgroundTask:bgTask];
                                                     bgTask = UIBackgroundTaskInvalid;
                                                 }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       [self cleanDisk];
                       [application endBackgroundTask:bgTask];
                       bgTask = UIBackgroundTaskInvalid;
                   });
}

@end
