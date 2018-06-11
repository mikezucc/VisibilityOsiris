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

@end

@implementation VisibilityLongTerm

- (id)initAndWithCache:(NSString *)cacheIdentifier {
    self = [super init];
    
    self.writeQueue = dispatch_queue_create("stanky.leg.nation.log.write", DISPATCH_QUEUE_SERIAL);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.stanky.leg.nation"];
    self.logSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    [self initializeFromCache];

    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"[visibility] [longterm] %@ %@", dataTask, data);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"[visibility] [longterm] %@ %@", task, error);
}

- (void)identify {
    NSMutableDictionary *submissionPayload = [[NSMutableDictionary alloc] init];
    [submissionPayload setObject:[[SCKLogger shared] client_identity_info] forKey:@"client_identity_info"];
    NSError *encodingError;
    NSData *mpjson = [MPMessagePackWriter writeObject:submissionPayload error:&encodingError];
    if (encodingError) {
        NSLog(@"[Visibility] Cache failed to encode with error %@", encodingError);
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[SCKLogger shared] endpoint:@"passive-log"]];
    request.HTTPBody = mpjson;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[self.logSession dataTaskWithRequest:request] resume];
}

- (void)receiveNewMessage:(SCKLogMessage *)message {
    if (self.messages) {
        [self.messages addObject:message];
        [self writeCache];
    }
}

- (NSArray <SCKLogMessage *>*)cacheDumpAndClear:(BOOL)clearCache {
    if (!self.messages || [self.messages count] == 0) {
        return @[];
    }
    NSArray *array = [self.messages copy];
    self.messages = [[NSMutableArray alloc] init];
    if (clearCache) {
        
    }

    NSString *existingAPIKey = [[SCKLogger shared] getAPIKey];

    NSMutableArray *cacheFriendly = [[NSMutableArray alloc] initWithCapacity:array.count];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCKLogMessage *message = (SCKLogMessage *)obj;
        [cacheFriendly addObject:[message full]];
    }];
    NSMutableDictionary *submissionPayload = [[NSMutableDictionary alloc] init];
    [submissionPayload setObject:cacheFriendly forKey:@"messages"];
    [submissionPayload setObject:existingAPIKey forKey:@"api_key"];
    [submissionPayload setObject:[[SCKLogger shared] sessionIdentifier] forKey:@"session_identifier"];
    NSError *encodingError;
    NSData *mpjson = [MPMessagePackWriter writeObject:submissionPayload error:&encodingError];
    if (encodingError) {
        NSLog(@"[Visibility] Cache failed to encode with error %@", encodingError);
        return array;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[SCKLogger shared] endpoint:@"passive-log"]];
    request.HTTPBody = mpjson;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[self.logSession dataTaskWithRequest:request] resume];

    return array;
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
        [data writeToFile:[self dataFilePath] atomically:YES];
    });
}

- (void)initializeFromCache {
    NSString *logsCacheFilePath = [self dataFilePath];
    NSData *data = [[NSData alloc] initWithContentsOfFile:logsCacheFilePath];
    if (!data) {
        self.messages = [[NSMutableArray alloc] init];
        NSLog(@"[Visibility] Warning: No log cache file found");
        return;
    }
    NSError *error;
    NSArray *cache = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        self.messages = [[NSMutableArray alloc] init];
        NSLog(@"[Visibility] Warning: No log cache file found");
        return;
    }
    self.messages = [[NSMutableArray alloc] initWithArray:cache];
}

-(void)removeFile:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [[self cacheDirectoryPath] stringByAppendingString:fileName];
    NSError *error;
    BOOL result = [fileManager removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"[Visibility] error: failed to remove cache: %@", error);
    } else {
        NSLog(@"[Visibility] removed cache %@", result ? @"yes" : @"no");
    }
}

- (NSString *)dataFilePath {
    return [[self cacheDirectoryPath] stringByAppendingPathComponent:@"VisibilityLogs.json"];
}

- (NSString *)cacheDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

@end
