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

- (id)initWithURL:(NSURL *)aUrl 
         consumer:(OAConsumer *)aConsumer 
            token:(OAToken *)aToken 
            realm:(NSString *)aRealm 
signatureProvider:(id<OASignatureProviding,NSObject>)aProvider
  extraParameters:(NSDictionary *)extraParameters;


- (NSString *)_generateQueryString;
- (NSString *)_signatureBaseString:(NSMutableDictionary *)params;

- (void)_generateTimestamp;
- (void)_generateNonce;

-(NSString *)Base64Encode:(NSData *)data;

@end
