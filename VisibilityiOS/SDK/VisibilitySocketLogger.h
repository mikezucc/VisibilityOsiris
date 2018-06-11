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

#import <Foundation/Foundation.h>

#import "SCKLogMessage.h"

typedef enum : NSUInteger {
    UnconfiguredAPIKey,
    Disconnected,
    Platform500
} SCKLoggerErrorCode;

@protocol SCKLoggerDelegate <NSObject>
@optional
- (void)errorOccurred:(SCKLoggerErrorCode)code;
@end

@protocol SCKLoggerLifecycleObserver <NSObject>
- (void)applicationDidEnterBackground;
@end

@interface SCKLogger: NSObject <SCKLoggerLifecycleObserver>

// Delegate
@property (weak, nonatomic, nullable) id <SCKLoggerDelegate> delegate;

// Swangleton
+ (SCKLogger * _Nonnull)shared;
- (NSString * _Nullable)sessionIdentifier;
- (NSURL * _Nullable)endpoint:(NSString * _Nullable)path;

// Configuring the SDK
- (void)configureWithAPIKey:(NSString * _Nullable)apiKey;
- (NSString * _Nullable)getAPIKey;
// Modifying the endpoint will provoke the socket
// to reinitialize to new endpoint on the fly
- (void)configureWithEndpoint:(NSString * _Nullable)endpoint;

// Logging
- (void)writeLog:(SCKLogMessage * _Nullable)message error:(NSError * _Nullable)error;

// Session identification
- (NSDictionary * _Nullable)client_identity_info;

// Convert SCKLoggerErrorCode to human readable
- (NSString * _Nullable)humanReadableCode:(SCKLoggerErrorCode)code;

@property (strong, nonatomic) NSString * _Nullable session;
@end

NS_ASSUME_NONNULL_BEGIN

#ifndef SCKLog_h
#define SCKLog_h

void SCKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2) NS_NO_TAIL_CALL;

#endif /* SCKLog_h */

NS_ASSUME_NONNULL_END
