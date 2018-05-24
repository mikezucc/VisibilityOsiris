//
//  SCKLogMessage.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 4/12/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import "SCKLogMessage.h"

@interface SCKLogMessage ()
@property (strong, nonatomic) NSDictionary <NSString *, NSObject *>* log;
@end

@implementation SCKLogMessage

-(void)setLog:(NSDictionary <NSString *, NSObject *>*)log {
    self.log = [log copy];
}



@end
