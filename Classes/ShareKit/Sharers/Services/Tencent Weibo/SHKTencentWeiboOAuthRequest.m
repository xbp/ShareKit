//
//  SHKTencentWeiboOAuthRequest.m
//  ShareKit
//
//  Created by icyleaf on 11-11-15.
//  Copyright (c) 2011 icyleaf.com. All rights reserved.
//

#import "SHKTencentWeiboOAuthRequest.h"
#import "SHKConfig.h"

@implementation SHKTencentWeiboOAuthRequest

-(NSString *)Base64Encode:(NSData *)data{
    //Point to start of the data and set buffer sizes
    int inLength = [data length];
    int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
    const char *inputBuffer = [data bytes];
    char *outputBuffer = malloc(outLength);
    outputBuffer[outLength] = 0;
    
    //64 digit code
    static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    //start the count
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp;
    
    //Pad the last to bytes, the outbuffer must always be a multiple of 4
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    /* http://en.wikipedia.org/wiki/Base64
     Text content   M           a           n
     ASCII          77          97          110
     8 Bit pattern  01001101    01100001    01101110
     
     6 Bit pattern  010011  010110  000101  101110
     Index          19      22      5       46
     Base64-encoded T       W       F       u
     */
    
    
    while (inpos < inLength){
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;                  
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;                          
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer); 
    return pictemp;
}


- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider
{
    if ((self = [super initWithURL:aUrl
                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                   timeoutInterval:10.0]))
	{
        consumer = [aConsumer retain];
        
        // empty token for Unauthorized Request Token transaction
        if (aToken == nil)
            token = [[OAToken alloc] init];
        else
            token = [aToken retain];
        
        if (aRealm == nil)
            realm = [[NSString alloc] initWithString:@""];
        else
            realm = [aRealm retain];
        
        // default to HMAC-SHA1
        if (aProvider == nil)
            signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
        else
            signatureProvider = [aProvider retain];
        
        [self _generateTimestamp];
        [self _generateNonce];
        
        NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [aUrl absoluteString], [self _generateQueryString]]];
        self = [super initWithURL:newURL
                      cachePolicy:NSURLRequestReloadIgnoringCacheData
                  timeoutInterval:10.0];
        
        NSLog(@"%@", [newURL absoluteString]);
        
		didPrepare = NO;
	}
    return self;
}

- (NSString *)_generateQueryString
{
    NSMutableDictionary *allParameters = [[NSMutableDictionary alloc] init];
    [allParameters setObject:nonce forKey:@"oauth_nonce"];
	[allParameters setObject:timestamp forKey:@"oauth_timestamp"];
	[allParameters setObject:@"1.0" forKey:@"oauth_version"];
	[allParameters setObject:[signatureProvider name] forKey:@"oauth_signature_method"];
	[allParameters setObject:consumer.key forKey:@"oauth_consumer_key"];
    [allParameters setObject:SHKTencentWeiboCallbackUrl forKey:@"oauth_callback"];
    
    if (![token.key isEqualToString:@""]) {
        [allParameters setObject:token.key forKey:@"oauth_token"];
    }
    
    signature = [signatureProvider signClearText:[self _signatureBaseString:allParameters]
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
												  [consumer.secret URLEncodedString],
                                                  [token.secret URLEncodedString]]];
    
    // Fix-it: always return 'Invalid signature'
    SHKLog(@"Signature: %@", signature);
    
    [allParameters setObject:[signature URLDecodedString] forKey:@"oauth_signature"];
    
    
    NSMutableArray *parametersArray = [[NSMutableArray alloc] init];
    NSArray *sortedPairs = [[allParameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in sortedPairs) {
		NSString *value = [allParameters valueForKey:key];
		[parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, [value URLEncodedString]]];
	}    
    
    NSString *queryString = [parametersArray componentsJoinedByString:@"&"];

    return queryString;
}

- (void)prepare
{
	if (didPrepare) {
		return;
	}
	didPrepare = YES;
    
    return;
}

#pragma mark -
#pragma mark Private

- (void)_generateTimestamp
{
    timestamp = [[NSString stringWithFormat:@"%d", time(NULL)] retain];
}

- (void)_generateNonce
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSMakeCollectable(theUUID);
    nonce = [self Base64Encode:[(NSString *)string dataUsingEncoding:NSUTF8StringEncoding]];
    nonce = [nonce substringToIndex:32];
	CFRelease(theUUID);
}

- (NSString *)_signatureBaseString:(NSMutableDictionary *)params
{
    NSMutableArray *sortedPairs = [[NSMutableArray alloc] init];
    
    NSArray *sortedKeys = [[params allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in sortedKeys) {
		NSString *value = [params valueForKey:key];
		[sortedPairs addObject:[NSString stringWithFormat:@"%@=%@", key, [value URLEncodedString]]];
	}
    
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [self HTTPMethod],
					 [[[self URL] URLStringWithoutQuery] URLEncodedString],
					 [normalizedRequestParameters URLEncodedString]];
    
    NSLog(@"ret: %@", ret);
    
    return ret;
}

@end
