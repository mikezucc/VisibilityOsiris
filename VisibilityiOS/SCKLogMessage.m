//
//  SCKLogMessage.m
//  VisibilityiOS
//
//  Created by Michael Zuccarino on 4/12/18.
//  Copyright © 2018 SnarfSnarf. All rights reserved.
//

#import "SCKLogMessage.h"

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

- (NSArray *)friendlifyNSArray:(NSArray *)array {
	NSMutableArray *friendly = [NSMutableArray new];
	[array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([obj isKindOfClass:[NSArray class]]) {
			[friendly addObject:[self friendlifyNSArray:(NSArray *)obj]];
		} else if ([obj isKindOfClass:[NSDictionary class]]) {
			[friendly addObject:[self friendlifyNSDictionary:obj]];
		} else if ([obj isKindOfClass:[NSString class]]) {
			[friendly addObject:obj];
		} else if (obj) {
			[friendly addObject:[obj debugDescription]];
		}
	}];
	return friendly;
}

- (NSDictionary *)friendlifyNSDictionary:(NSDictionary *)dictionary {
	NSMutableDictionary *friendly = [NSMutableDictionary new];
	[dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if ([obj isKindOfClass:[NSDictionary class]]) {
			[friendly setObject:[self friendlifyNSDictionary:obj] forKey:key];
		} else if ([obj isKindOfClass:[NSArray class]]) {
			[friendly setObject:[self friendlifyNSArray:obj] forKey:key];
		} else if ([obj isKindOfClass:[NSString class]]) {
			[friendly setObject:obj forKey:key];
		} else if (obj) {
			[friendly setObject:[obj debugDescription] forKey:key];
		}
	}];
	return friendly;
}

@end

