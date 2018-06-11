//
//  SCKLogMessage.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 4/12/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import "SCKLogMessage.h"

#import "VisibilitySocketLogger.h"

@interface SCKLogMessage ()
@property (strong, nonatomic) NSDictionary <NSString *, NSObject *>* internalLog;
@property (strong, nonatomic) NSDictionary *client_identity_info;
@end

@implementation SCKLogMessage

-(void)setLog:(NSDictionary <NSString *, NSObject *>*)log {
    self.internalLog = log;
    self.client_identity_info = [[SCKLogger shared] client_identity_info];
}

- (NSDictionary<NSString *,NSObject *> *)log {
    return self.internalLog;
}

- (NSDictionary *)full {
    return @{@"log": self.internalLog, @"session": self.client_identity_info };;
}

@end
