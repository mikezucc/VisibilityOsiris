//
/*
      ___           ___           ___                         ___           ___
     /  /\         /  /\         /__/|                       /  /\         /  /\
    /  /:/_       /  /:/        |  |:|                      /  /::\       /  /:/_
   /  /:/ /\     /  /:/         |  |:|      ___     ___    /  /:/\:\     /  /:/ /\
  /  /:/ /::\   /  /:/  ___   __|  |:|     /__/\   /  /\  /  /:/  \:\   /  /:/_/::\
 /__/:/ /:/\:\ /__/:/  /  /\ /__/\_|:|____ \  \:\ /  /:/ /__/:/ \__\:\ /__/:/__\/\:\
 \  \:\/:/~/:/ \  \:\ /  /:/ \  \:\/:::::/  \  \:\  /:/  \  \:\ /  /:/ \  \:\ /~~/:/
  \  \::/ /:/   \  \:\  /:/   \  \::/~~~~    \  \:\/:/    \  \:\  /:/   \  \:\  /:/
   \__\/ /:/     \  \:\/:/     \  \:\         \  \::/      \  \:\/:/     \  \:\/:/
     /__/:/       \  \::/       \  \:\         \__\/        \  \::/       \  \::/
     \__\/         \__\/         \__\/                       \__\/         \__\/
 */

#import "VisibilitySocketLogger.h"

#import "VisibilityLongTerm.h"

#import <Foundation/Foundation.h>

#import <MPMessagePack/MPMessagePack.h>

@import SocketIO;

@interface SCKLogger ()
@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) SocketManager *manager;
@property (strong, nonatomic) VisibilityLongTerm *longTerm;

@property (nonatomic) BOOL didIdentify;

@property (strong, nonatomic) NSString *sessionId;
@end

@implementation SCKLogger

NSString *SDK_VERSION = @"0.0.1";

/**
 User defaults config
 */
NSString *kUserDefaultsSCKIdentifier = @"sck_identifier";
NSString *kUserDefaultsAPIKey = @"sck_api_key";
NSString *kUserDefaultsEndpoint = @"sck_endpoint_osiris";
NSString *kUserDefaultsActive = @"sck_active";

- (NSUserDefaults *)sckDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSCKIdentifier];
}

- (void)configureWithAPIKey:(NSString *)apiKey {
    if (apiKey == nil) { return; }
    NSString *existingAPIKey = [self getAPIKey];
    if (![existingAPIKey isEqualToString:apiKey]) {
        [[self sckDefaults] setObject:apiKey forKey:kUserDefaultsAPIKey];
    }
    [self initiateSocket:[self endpoint:nil]];
}

// Reinitialize socket when the endpoint is modified and different
- (void)configureWithEndpoint:(NSString *)endpoint {
    if (endpoint == nil) { return; }
    NSString *existingEndpoint = [self userDefinedEndpoint];
    if (![existingEndpoint isEqualToString:endpoint]) {
        [[self sckDefaults] setObject:endpoint forKey:kUserDefaultsEndpoint];
    }
    NSString *existingAPIKey = [self getAPIKey];
    if (existingAPIKey && existingAPIKey.length) {
        [self initiateSocket:[self endpoint:nil]];
    }
}

// ENDPOINT/ DISCOVERY
- (NSString *)userDefinedEndpoint {
    return [[self sckDefaults] objectForKey:kUserDefaultsEndpoint];
}

- (NSURL *)endpoint:(NSString * _Nullable)path {
    NSString *base = [self userDefinedEndpoint];
    if (base == nil) {
        return nil;
    }
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:base];
    if (path) { components.path = path; }
    return [components URL];
}

- (NSString *)getAPIKey {
    return [[self sckDefaults] objectForKey:kUserDefaultsAPIKey];
}

- (BOOL)appShouldBeActive {
    return [[self sckDefaults] boolForKey:kUserDefaultsActive];
}

- (NSString *)sessionIdentifier {
    if (self.sessionId == nil) {
        self.sessionId = [self generateRandomString];
    }
    return self.sessionId;
}

// I know this is redundant, but you'll thank me when you start trying to make tectonic
// shifts to the way this thing behaves a year from now
- (NSURL * _Nullable)localServerEndpoint { return [self endpoint:nil]; }

// LOGGER
+ (SCKLogger *)shared {
    static SCKLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[SCKLogger alloc] init];
        logger.didIdentify = NO;
        logger.session = [NSString stringWithFormat:@"%@",[NSDate date]];
        logger.longTerm = [[VisibilityLongTerm alloc] initAndWithCache:nil];
        [[logger sckDefaults] setObject:@NO forKey:kUserDefaultsActive];
    });
    return logger;
}

- (void)initiateSocket:(NSURL *)endpoint {
    if (self.manager) {
        [self.manager disconnect];
    }

    if (endpoint == nil) {
        return;
    }
    
    if ([self getAPIKey] == nil) {
        return;
    }

    [self.longTerm cacheDumpAndClear:YES];
    
    if ([self appShouldBeActive] == false) {
        if (self.didIdentify == NO) {
            self.didIdentify = YES;
            [self.longTerm identify];
        }
        return;
    }
    
    self.manager = [[SocketManager alloc] initWithSocketURL:endpoint
                                   config:@{@"log": @YES, @"compress": @YES}];
    SocketIOClient *socket = self.manager.defaultSocket;
    
    [socket on:@"ack" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSDictionary *registrationParams = [self client_identity_info];
        NSLog(@"[PARAMS] %@",registrationParams);
        [socket emit:@"client-identify" with:@[registrationParams]];
    }];
    
    [socket connect];

    self.socket = socket;
}

- (NSDictionary *)client_identity_info {
    NSString *app_version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *device_identifier = [[self sckDefaults] stringForKey:kUserDefaultsSCKIdentifier] ?: [self resetDeviceIdentifier];
    return @{
      @"api_key":[self getAPIKey],
      @"team_identifier":[self getAPIKey],
      @"device_identifier":device_identifier,
      @"human_name":[[UIDevice currentDevice] model],
      @"reported_type":[[UIDevice currentDevice] model],
      @"username":@"jeremy100",
      @"app_version":app_version,
      @"os_version":[[UIDevice currentDevice] systemVersion],
      @"sdk_version":SDK_VERSION,
      @"session_identifier":[self sessionIdentifier],
      @"bundle_identifier":[[NSBundle mainBundle] bundleIdentifier]
      };
}

- (void)writeLog:(SCKLogMessage *)message error:(NSError *)error {
    if (![self localServerEndpoint]) { return; }

    if ([self appShouldBeActive] && [[self socket] status] != SocketIOStatusConnected) {
        NSData *mpjson = [MPMessagePackWriter writeObject:[message full] error:&error];
//        NSData *nsjson = [NSJSONSerialization dataWithJSONObject:message.log options:0 error:&error];
        //NSLog(@"comparing sizes nsjson: %lu vs mpjson: %lu", (unsigned long)nsjson.length, (unsigned long)mpjson.length);
        [self.socket emit:@"log" with:@[mpjson]];
    } else {
        [self.longTerm receiveNewMessage:message];
    }
}

- (void)applicationDidEnterBackground {
    NSArray <SCKLogMessage *>* cache = [self.longTerm cacheDumpAndClear:YES];
    if (!cache || [cache count] == 0) {
        NSLog(@"[Visibility] Cache is empty, can not flush on application close");
        return;
    }
}

- (NSString *)humanReadableCode:(SCKLoggerErrorCode)code {
    switch (code) {
        case UnconfiguredAPIKey:
            return @"UnconfiguredAPIKey";
        case Disconnected:
            return @"Disconnected";
        case Platform500:
            return @"Platform500";
        default:
            return @"Unmapped Code Oops Lmao";
    }
}

// UTILItitTy

- (NSString *)generateRandomString {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY";
    static NSString *digits = @"0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:8];
    //returns 19 random chars into array (mutable string)
    for (NSUInteger i = 0; i < 6; i++) {
        uint32_t r;
        
        // Append 2 random letters:
        r = arc4random_uniform((uint32_t)[letters length]);
        [s appendFormat:@"%C", [letters characterAtIndex:r]];
        r = arc4random_uniform((uint32_t)[letters length]);
        [s appendFormat:@"%C", [letters characterAtIndex:r]];
        
        // Append 2 random digits:
        r = arc4random_uniform((uint32_t)[digits length]);
        [s appendFormat:@"%C", [digits characterAtIndex:r]];
        r = arc4random_uniform((uint32_t)[digits length]);
        [s appendFormat:@"%C", [digits characterAtIndex:r]];
        
    }
    NSLog(@"s-->%@",s);
    return s;
}

- (NSString *)resetDeviceIdentifier
{
    NSString *s = [self generateRandomString];
    
    [[self sckDefaults] setObject:s forKey:kUserDefaultsSCKIdentifier];
    
    return s;
}

@end

void SCKLog(NSString *format, ...) {
    // reference from https://code.tutsplus.com/tutorials/quick-tip-customize-nslog-for-easier-debugging--mobile-19066
    va_list ap;
    va_start (ap, format);
    
    NSString *log = [[NSString alloc] initWithFormat:format arguments:ap];
    NSError *error = nil;
    SCKLogMessage *message = [[SCKLogMessage alloc] init];
    [message setLog:@{@"c-log":log}];
    [[SCKLogger shared] writeLog:message error:error];
    
    va_end (ap);
}

