//
//  SignusUtils.m
//  libsovrin-demo
//
//  Created by Anastasia Tarasova on 02.06.17.
//  Copyright © 2017 Kirill Neznamov. All rights reserved.
//

#import "SignusUtils.h"
#import <libsovrin/libsovrin.h>
#import "TestUtils.h"
#import "WalletUtils.h"

@implementation SignusUtils

+ (SignusUtils *)sharedInstance
{
    static SignusUtils *instance = nil;
    static dispatch_once_t dispatch_once_block;
    
    dispatch_once(&dispatch_once_block, ^{
        instance = [SignusUtils new];
    });
    
    return instance;
}
- (NSError *)signWithWalletHandle:(SovrinHandle)walletHandle
                         theirDid:(NSString *)theirDid
                          message:(NSString *)message
                     outSignature:(NSString **)signature
{
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    __block NSString *signSignature = nil;
    NSError *ret;

    
    ret = [SovrinSignus signWithWalletHandle:walletHandle
                                         did:theirDid
                                         msg:message
                                  completion:^(NSError *error, NSString *blockSignature)
    {
        err = error;
        signSignature = blockSignature;
        [completionExpectation fulfill];
    }];
    
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    
    if (signature) { *signature = signSignature; }
    
    return err;
}


- (NSError *)createMyDidWithWalletHandle:(SovrinHandle)walletHandle
                               myDidJson:(NSString *)myDidJson
                                outMyDid:(NSString **)myDid
                             outMyVerkey:(NSString **)myVerkey
                                 outMyPk:(NSString **)myPk
{
   
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    __block NSString *did = nil;
    __block NSString *verKey = nil;
    __block NSString *pk = nil;
    NSError *ret;

    ret = [SovrinSignus createAndStoreMyDidWithWalletHandle:walletHandle
                                                    didJSON:myDidJson
                                                 completion:^(NSError *error, NSString *blockDid, NSString *blockVerKey, NSString *blockPk)
    {
        err = error;
        did = blockDid;
        verKey = blockVerKey;
        pk = blockPk;
        
        [completionExpectation fulfill];
    }];
    
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    
    if (myDid) { *myDid = did; }
    if (myVerkey){ *myVerkey = verKey; }
    if (myPk) { *myPk = pk; }
    
    return err;
}

- (NSError *)createAndStoreMyDidWithWalletHandle:(SovrinHandle)walletHandle
                                            seed:(NSString *)seed
                                        outMyDid:(NSString **)myDid
                                     outMyVerkey:(NSString **)myVerkey
                                         outMyPk:(NSString **)myPk
{
    
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    __block NSString *did = nil;
    __block NSString *verKey = nil;
    __block NSString *pk = nil;
    NSError *ret;
    
    NSString *myDidJson = (seed) ? [NSString stringWithFormat:@"{\"seed\":\"%@\"}", seed] : @"{}";
    
    ret = [SovrinSignus createAndStoreMyDidWithWalletHandle:walletHandle
                                                    didJSON:myDidJson
                                                 completion:^(NSError *error, NSString *blockDid, NSString *blockVerKey, NSString *blockPk)
           {
               err = error;
               did = blockDid;
               verKey = blockVerKey;
               pk = blockPk;
               
               [completionExpectation fulfill];
           }];
    
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    
    if (myDid) { *myDid = did; }
    if (myVerkey){ *myVerkey = verKey; }
    if (myPk) { *myPk = pk; }
    
    return err;
}


- (NSError *)storeTheirDidWithWalletHandle: (SovrinHandle) walletHandle
                              identityJson: (NSString *)identityJson
{
    
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    NSError *ret;
    
    ret = [SovrinSignus storeTheirDidWithWalletHandle:walletHandle
                                         identityJSON:identityJson
                                           completion:^(NSError *error)
    {
        err = error;
        [completionExpectation fulfill];
    }];
    
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils longTimeout]];
    
    return err;
}

- (NSError *)storeTheirDidFromPartsWithWalletHandle:(SovrinHandle)walletHandle
                                           theirDid:(NSString *)theirDid
                                            theirPk:(NSString *)theirPk
                                        theirVerkey:(NSString *)theirVerkey
                                           endpoint:(NSString *)endpoint
{
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    // WARNING: PublicKey is removed from Rust API, hovewer it is not a final decision.
    NSString *theirIdentityJson = [NSString stringWithFormat:@"{"
                                   "\"did\":\"%@\","
                                   "\"verkey\":\"%@\","
                                   "\"endpoint\":\"\%@\"}", theirDid, theirVerkey, endpoint];
    
    NSError *ret = [SovrinSignus storeTheirDidWithWalletHandle:walletHandle
                                                  identityJSON:theirIdentityJson
                                                    completion:^(NSError *error)
    {
        err = error;
        [completionExpectation fulfill];
    }];
    
    if (ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils longTimeout]];
    
    return err;
}

- (NSError *)replaceKeysWithWalletHandle:(SovrinHandle)walletHandle
                                     did:(NSString *)did
                            identityJson:(NSString *)identityJson
                             outMyVerKey:(NSString **)myVerKey
                                 outMyPk:(NSString **)myPk
{
    
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    __block NSString *verkey;
    __block NSString *pk;
    NSError *ret;
    
    ret = [SovrinSignus replaceKeysWithWalletHandle:walletHandle
                                                did:did
                                       identityJSON:identityJson
                                         completion: ^(NSError *error, NSString *blockVerkey, NSString *blockPk)
    {
        err = error;
        verkey = blockVerkey;
        pk = blockPk;
        [completionExpectation fulfill];
    }];
 
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils longTimeout]];
    
    if (myVerKey) { *myVerKey = verkey; }
    if (myPk) { *myPk = pk; }
    
    return err;
}

- (NSError *)verifyWithWalletHandle:(SovrinHandle)walletHandle
                         poolHandle:(SovrinHandle)poolHandle
                                did:(NSString *)did
                          signature:(NSString *)signature
                        outVerified:(BOOL *)verified
{
    XCTestExpectation* completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSError *err = nil;
    __block BOOL outVerified;
    NSError *ret;
    
    ret = [SovrinSignus verifySignatureWithWalletHandle:walletHandle
                                             poolHandle:poolHandle
                                                    did:did
                                              signature:signature
                                             completion:^(NSError *error, BOOL valid)
    {
        err = error;
        outVerified = valid;
        [completionExpectation fulfill];
    }];
    
    if( ret.code != Success)
    {
        return ret;
    }
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils longTimeout]];
    
    if (verified) { *verified = outVerified; }
    
    return err;
}

@end
