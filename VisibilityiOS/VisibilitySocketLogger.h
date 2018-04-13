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

#import <VisibilityiOS/SCKLogMessage.h>

typedef enum : NSUInteger {
    UnconfiguredAPIKey,
    Disconnected,
    Platform500
} SCKLoggerErrorCode;

@protocol SCKLoggerDelegate <NSObject>
@optional
- (void)errorOccurred:(SCKLoggerErrorCode)code;
@end

@interface SCKLogger: NSObject

// Delegate
@property (weak, nonatomic) id<SCKLoggerDelegate> delegate;

// Swangleton
+ (SCKLogger *)shared;

// Configuring the SDK
- (void)configureWithAPIKey:(NSString *)apiKey;
// Modifying the endpoint will provoke the socket
// to reinitialize to new endpoint on the fly
- (void)configureWithEndpoint:(NSString *)endpoint;

// Logging
- (void)writeLog:(SCKLogMessage *)message error:(NSError *)error;

// Convert SCKLoggerErrorCode to human readable
- (NSString *)humanReadableCode:(SCKLoggerErrorCode)code;

@property (strong, nonatomic) NSString *session;
@end

#ifndef SCKLog_h
#define SCKLog_h

void SCKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2) NS_NO_TAIL_CALL;

#endif /* SCKLog_h */

