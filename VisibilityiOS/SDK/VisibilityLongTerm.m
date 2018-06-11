//
//  VisibilityLongTerm.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 5/23/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import "VisibilityLongTerm.h"

@interface VisibilityLongTerm ()

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) NSMutableArray *messageQueue; // message

@end

@implementation VisibilityLongTerm

- (id)initAndWithCache:(NSString *)cacheIdentifier {
    self = [super init];
    
    self.messageQueue = [[NSMutableArray alloc] init];
    
    [self initializeFromCache];
    
    return self;
}

- (void)receiveNewMessage:(SCKLogMessage *)message {
    if (!self.messages) {
        [self.messageQueue addObject:message];
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
    return array;
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
