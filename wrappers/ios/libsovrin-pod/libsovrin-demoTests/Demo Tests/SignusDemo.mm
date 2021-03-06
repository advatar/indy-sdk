//
//  SignusDemo.m
//  libsovrin-demo
//

#import <XCTest/XCTest.h>
#import "PoolUtils.h"
#import "TestUtils.h"
#import <libsovrin/libsovrin.h>
#import "WalletUtils.h"
#import "SignusUtils.h"

@interface SignusDemo : XCTestCase

@end

@implementation SignusDemo

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSignusDemo
{
    [TestUtils cleanupStorage];

    NSString *poolName = @"pool1";
    NSString *myWalletName = @"my_wallet";
    NSString *theirWalletName = @"their_wallet";
    NSString *xtype = @"default";
    NSError *ret = nil;
    XCTestExpectation* completionExpectation = nil;
    
    SovrinHandle myWalletHandle = 0;
    SovrinHandle theirWalletHandle = 0;

    //TODO CREATE ISSUER, PROVER, VERIFIER WALLETS
    //1. Create and open my wallet
    ret = [[WalletUtils sharedInstance] createAndOpenWalletWithPoolName:  poolName
                                                             walletName:  myWalletName
                                                                  xtype:  xtype
                                                                 handle: &myWalletHandle];
    
    XCTAssertEqual(ret.code, Success, @"WalletUtils::createAndOpenWalletWithPoolName() failed!");

    //2. Create and open Their Wallet

    ret = [[WalletUtils sharedInstance] createAndOpenWalletWithPoolName:  poolName
                                                             walletName:  theirWalletName
                                                                  xtype:  xtype
                                                                 handle: &theirWalletHandle];
    
    XCTAssertEqual(ret.code, Success, @"WalletUtils::createAndOpenWalletWithPoolName() failed!");

    // 3. Create My DID
    
    NSString *myDidJson = @"{}";
    completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    
    __block NSString *myDid = nil;
    __block NSString *myVerkey = nil;
    __block NSString *myPk = nil;
    ret = [SovrinSignus createAndStoreMyDidWithWalletHandle:  myWalletHandle
                                                    didJSON:  myDidJson
                                                 completion: ^(NSError *error, NSString *did, NSString *verkey, NSString *pk)
    {
        XCTAssertEqual(error.code, Success, "createAndStoreMyDid() got error in completion");
        NSLog(@"myDid:");
        NSLog(@"did = %@", did);
        NSLog(@"verkey = %@", verkey);
        NSLog(@"pk = %@", pk);
        myDid = did;
        myVerkey = verkey;
        myPk = pk;
        [completionExpectation fulfill];
    }];
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    XCTAssertEqual(ret.code, Success, @"createAndStoreMyDid() failed!");
    
    // 4. Create Their DID

    NSString *theirDidJson = @"{}";
    completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];

    __block NSString *theirDid = nil;
    __block NSString *theirVerkey = nil;
    __block NSString *theirPk = nil;
    
    ret = [SovrinSignus createAndStoreMyDidWithWalletHandle:  theirWalletHandle
                                                    didJSON:  theirDidJson
                                                 completion: ^(NSError *error, NSString *did, NSString *verkey, NSString *pk)
    {
        XCTAssertEqual(error.code, Success, "createAndStoreMyDid() got error in completion");
        NSLog(@"theirDid:");
        NSLog(@"did = %@", did);
        NSLog(@"verkey = %@", verkey);
        NSLog(@"pk = %@", pk);
        theirDid = [NSString stringWithString: did];
        theirVerkey = [NSString stringWithString: verkey];
        theirPk = [NSString stringWithString: pk];
        [completionExpectation fulfill];
    }];
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    XCTAssertEqual(ret.code, Success, @"createAndStoreMyDid() failed!");

    // 5. Store Their DID
    
    NSString* theirIdentityJson = [NSString stringWithFormat: @"{\"did\":\"%@\",\
                                                                 \"pk\":\"%@\",\
                                                                 \"verkey\":\"%@\"\
                                                                }", theirDid, theirPk, theirVerkey];

    completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];

    ret = [SovrinSignus storeTheirDidWithWalletHandle: myWalletHandle identityJSON: theirIdentityJson completion:^(NSError *error)
    {
        XCTAssertEqual(error.code, Success, "storeTheirDid() got error in completion");
        [completionExpectation fulfill];
    }];
    
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    XCTAssertEqual(ret.code, Success, @"createAndStoreMyDid() failed!");
    
    // 6. Their Sign message
    
    NSString* message = @"{"\
                         "  \"reqId\":1495034346617224651,"
                         "  \"identifier\":\"GJ1SzoWzavQYfNL9XkaJdrQejfztN4XqdsiV4ct3LXKL\","
                         "  \"operation\":{"
                         "        \"type\":\"1\","
                         "        \"dest\":\"4efZu2SXufS556yss7W5k6Po37jt4371RM4whbPKBKdB\"}"
                         "}";
    
    completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];
    __block NSString *theirSignature = nil;
    
    ret = [SovrinSignus signWithWalletHandle:  theirWalletHandle
                                         did:  theirDid
                                         msg:  message
                                  completion: ^(NSError *error, NSString *signature)
    {
        XCTAssertEqual(error.code, Success, "sign() got error in completion");
        NSLog(@"signature: %@", signature);
        theirSignature = [NSString stringWithString: signature];
        [completionExpectation fulfill];
    }];

    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    XCTAssertEqual(ret.code, Success, @"sign() failed!");
    
    // 7. I Verify message
    SovrinHandle poolHandle = 1;
    
    completionExpectation = [[ XCTestExpectation alloc] initWithDescription: @"completion finished"];

    ret = [SovrinSignus verifySignatureWithWalletHandle:  myWalletHandle
                                             poolHandle:  poolHandle
                                                    did:  theirDid
                                              signature:  theirSignature
                                             completion: ^(NSError *error, BOOL valid)
    {
        XCTAssertEqual(error.code, Success, "verifySignature() got error in completion");
        XCTAssertEqual(YES, valid, "verifySignature() signature is not valid");
        [completionExpectation fulfill];
    }];

    // TODO: There is some error inside closure at rust level
    [self waitForExpectations: @[completionExpectation] timeout:[TestUtils defaultTimeout]];
    XCTAssertEqual(ret.code, Success, @"verifySignature() failed!");
    
    [TestUtils cleanupStorage];
}

@end
