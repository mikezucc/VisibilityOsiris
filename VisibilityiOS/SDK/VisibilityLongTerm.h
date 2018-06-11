//
//  VisibilityLongTerm.h
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 5/23/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SCKLogMessage.h"

@interface VisibilityLongTerm : NSObject

- (id)initAndWithCache:(NSString *)cacheIdentifier;

- (void)receiveNewMessage:(SCKLogMessage *)message;
- (NSArray <SCKLogMessage *>*)cacheDumpAndClear:(BOOL)clearCache;


@end
