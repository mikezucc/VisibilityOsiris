//
//  SCKLogMessage.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 4/12/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import <VisibilityiOS/SCKLogMessage.h>

@interface SCKLogMessage ()
@property (strong, nonatomic) NSDictionary <NSString *, NSObject *>* internal_log;
@end

@implementation SCKLogMessage

@synthesize internal_log;

- (void)setLog:(NSDictionary <NSString *, NSObject *>*)log {
    self.internal_log = [log copy];
}

- (NSDictionary <NSString *, NSObject *>*)getLog {
    return self.internal_log;
}


@end

