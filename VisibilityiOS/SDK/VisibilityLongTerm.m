//
//  VisibilityLongTerm.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 5/23/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import "VisibilityLongTerm.h"

#import "VisibilitySocketLogger.h"

#import <MPMessagePack/MPMessagePack.h>

@interface VisibilityLongTerm () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) dispatch_queue_t writeQueue;
@property (strong, nonatomic) NSURLSession *logSession;

@property (weak, nonatomic) SCKLogger *logger;

@end

@implementation VisibilityLongTerm

- (id)initAndWithCache:(NSString *)cacheIdentifier logger:(SCKLogger *)logger {
    self = [super init];
    
    self.writeQueue = dispatch_queue_create("stanky.leg.nation.log.write", DISPATCH_QUEUE_SERIAL);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.stanky.leg.nation"];
    self.logSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[[NSOperationQueue alloc] init]];

    self.messages = [[NSMutableArray alloc] init];
    
    self.logger = logger;

    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[VISIBILITY] [longterm] %@ %@", dataTask, dataString);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"[VISIBILITY] [longterm] %@ %@", task, error);
}

- (void)identify {
    NSMutableDictionary *submissionPayload = [[NSMutableDictionary alloc] init];
    [submissionPayload setObject:[self.logger client_identity_info] forKey:@"client_identity_info"];
    NSError *encodingError;
    NSData *mpjson = [NSJSONSerialization dataWithJSONObject:submissionPayload options:NSJSONWritingPrettyPrinted error:&encodingError];
    if (encodingError) {
        NSLog(@"[VISIBILITY] Cache failed to encode with error %@", encodingError);
        return;
    }
    NSURL *url = [self.logger endpoint:@"/app/identify/"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPBody = mpjson;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)mpjson.length] forHTTPHeaderField:@"Content-Length"];
    [[self.logSession dataTaskWithRequest:request] resume];
}

- (void)receiveNewMessage:(SCKLogMessage *)message {
    if (self.messages) {
        [self.messages addObject:message];
        [self writeCache];
    }
}

- (NSArray *)cacheDumpAndClear:(BOOL)clearCache {
    NSArray *cache = [self xeroxCache];
    if (!cache || [cache count] == 0) {
        return @[];
    }
    if (clearCache) {
        NSError *delError;
        [[NSFileManager defaultManager] removeItemAtPath:[self dataFilePath] error:&delError];
        NSLog(@"[VISIBILITY] failed to delete the cache file %@", delError);
    }

    NSString *existingAPIKey = [self.logger getAPIKey];

    NSMutableDictionary *submissionPayload = [[NSMutableDictionary alloc] init];
    [submissionPayload setObject:cache forKey:@"messages"];
    [submissionPayload setObject:existingAPIKey forKey:@"api_key"];
    [submissionPayload setObject:[self.logger sessionIdentifier] forKey:@"session_identifier"];
    NSError *encodingError;
    NSData *mpjson = [NSJSONSerialization dataWithJSONObject:submissionPayload options:NSJSONWritingPrettyPrinted error:&encodingError];
    if (encodingError) {
        NSLog(@"[VISIBILITY] Cache failed to encode with error %@", encodingError);
        return cache;
    }
    NSURL *url = [self.logger endpoint:@"/app/passive/"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPBody = mpjson;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)mpjson.length] forHTTPHeaderField:@"Content-Length"];
    [[self.logSession dataTaskWithRequest:request] resume];

    return cache;
}

- (void)writeCache {
    dispatch_async(self.writeQueue, ^{
        NSError *error;
        
        NSArray *copied = [self.messages copy];
        NSMutableArray *encodable = [[NSMutableArray alloc] initWithCapacity:copied.count];
        [copied enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SCKLogMessage *message = (SCKLogMessage *)obj;
            [encodable addObject:[message full]];
        }];
        NSData *data = [NSJSONSerialization dataWithJSONObject:encodable options:NSJSONWritingPrettyPrinted error:&error];
        NSLog(@"[VISIBILITY] cache write encode error %@",error);
        [data writeToFile:[self dataFilePath] atomically:YES];
    });
}

- (NSArray *)xeroxCache {
    NSString *logsCacheFilePath = [self dataFilePath];
    NSData *data = [[NSData alloc] initWithContentsOfFile:logsCacheFilePath];
    if (!data) {
        NSLog(@"[VISIBILITY] Warning: No log cache file found");
        return @[];
    }
    NSError *error;
    NSArray *cache = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"[VISIBILITY] Warning: No log cache file found");
        return @[];
    }
    return cache;
}

-(void)removeFile:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [[self cacheDirectoryPath] stringByAppendingString:fileName];
    NSError *error;
    BOOL result = [fileManager removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"[VISIBILITY] error: failed to remove cache: %@", error);
    } else {
        NSLog(@"[VISIBILITY] removed cache %@", result ? @"yes" : @"no");
    }
}

- (NSString *)dataFilePath {
    return [[self cacheDirectoryPath] stringByAppendingPathComponent:@"/VisibilityLogs.json"];
}

- (NSString *)cacheDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

@end
