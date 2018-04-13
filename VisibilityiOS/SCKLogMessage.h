//
//  SCKLogMessage.h
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 4/12/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCKLogMessage : NSObject

// returns NO if the message is not properly formatted
// MUST contain JSON encodable objects
- (void)setLog:(NSDictionary <NSString *, NSObject *>*) log;
- (NSDictionary <NSString *, NSObject *>*)getLog;

@end
