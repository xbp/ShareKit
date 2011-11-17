//
//  SHKTencentWeiboOAuthRequest.h
//  ShareKit
//
//  Created by icyleaf on 11-11-15.
//  Copyright (c) 2011 icyleaf.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAMutableURLRequest.h"

@interface SHKTencentWeiboOAuthRequest : OAMutableURLRequest

- (NSString *)_generateQueryString;

- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
- (NSString *)_signatureBaseString:(NSMutableDictionary *)params;
@end
