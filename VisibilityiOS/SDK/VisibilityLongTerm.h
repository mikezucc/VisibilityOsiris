//
//  VisibilityLongTerm.h
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 5/23/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SCKLogMessage.h"

#import "VisibilitySocketLogger.h"

@interface VisibilityLongTerm : NSObject

- (id)initAndWithCache:(NSString *)cacheIdentifier logger:(SCKLogger *)logger;
- (void)identify;

- (void)receiveNewMessage:(SCKLogMessage *)message;
- (NSArray <SCKLogMessage *>*)cacheDumpAndClear:(BOOL)clearCache;


@end
