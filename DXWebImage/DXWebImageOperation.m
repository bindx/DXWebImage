//
//  DXWebImageOperation.m
//  DXWebImage
//
//  Created by Bindx on 9/28/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//


#import "DXWebImageOperation.h"

@interface DXWebImageOperation (){
    BOOL _isFinished;
}

@property (nonatomic,strong) NSURLRequest* request;
@property (nonatomic,strong) NSURLConnection* connection;
@property (nonatomic,strong) NSMutableData* resultData;//请求的数据

@end

@implementation DXWebImageOperation

- (id)initWithURLString:(NSURL *)url Withdelegate:(id)delegate{
    return [self initWithURLString:url WithBlock:nil Withdelegate:delegate];
}

- (id)initWithURLString:(NSURL *)url Withblock:(DXImageDownloadComplete)block{
    return [self initWithURLString:url WithBlock:[block copy] Withdelegate:nil];
}

+ (id)statusWithURLString:(NSURL *)url Withblock:(DXImageDownloadComplete)block{
    DXWebImageOperation *dxwfb = [[DXWebImageOperation alloc]initWithURLString:url WithBlock:[block copy] Withdelegate:nil];
    return dxwfb;
}
+ (id)statusWithURLString:(NSURL *)url Withdelegate:(id<DXImageDownloaderDelegate>)delegate{
    DXWebImageOperation *dxwfb = [[DXWebImageOperation alloc]initWithURLString:url WithBlock:nil Withdelegate:delegate];
    return dxwfb;
}

/**
    init
 */

- (id)initWithURLString:(NSURL *)url WithBlock:(DXImageDownloadComplete)block Withdelegate:(id<DXImageDownloaderDelegate>)delegate{
    self = [self init];
        if (self) {
            _request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
            _resultData = [NSMutableData data];
            if (block) {
                _downloadComplete = [block copy];
            }
            if (delegate) {
                _delegate = delegate;
            }
        }
    return self;
}

- (void)start {
    if (![self isCancelled]) {
        _connection=[NSURLConnection connectionWithRequest:_request delegate:self];
        while(_connection != nil) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

#pragma mark NSURLConnection delegate Method

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data{
    [_resultData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    _connection=nil;
    UIImage *img = [[UIImage alloc] initWithData:self.resultData];
    if (self.delegate != nil){
        [_delegate imageDidFinished:img];
    }
    if (_downloadComplete) {
        _downloadComplete(img);
    }
}

-(void)connection: (NSURLConnection *) connection didFailWithError: (NSError *) error{
    _connection=nil;
    if (self.delegate != nil){
        [_delegate imageDidError:error];
    }
}

-(BOOL)isConcurrent{
    //返回yes表示支持异步调用，否则为支持同步调用
    return YES;
}
- (BOOL)isExecuting{
    return _connection == nil;
}
- (BOOL)isFinished{
    return _connection == nil;
}


@end