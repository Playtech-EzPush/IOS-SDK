//
//  EzPush.m
//  EzPush
//
//  Created by Haggai Elazar on 09/08/2016.
//  Copyright © 2016 Playtech. All rights reserved.
//

#import "EzPush.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"



#define EzPush_APP_KEY      @"EzPush_APP_ID"
#define EzPush_DEVICE_TOKEN @"EzPush_DEVICE_TOKEN"

#define socketHost          @"fe.techonlinecorp.com"
#define socketPort          443
#define socketSecure        YES

//#define applicationId @"<YOUR_APPLICATION_ID>"

@interface EzPush ()<SocketIODelegate>{
    SocketIO *socketIO;
}

//WEB SOCKET METHODS
- (void) socketIODidConnect:(SocketIO *)socket;
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error;
- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket onError:(NSError *)error;

//@property (nonatomic,strong) SocketIO       *socketIO;

@property(assign)            BOOL           enableLog;

@property (nonatomic,copy)   NSData         *pushToken;
@property (nonatomic,copy)   NSString       *queString;
@property (nonatomic,copy)   NSString       *contextId;
@property (nonatomic,copy)   NSString       *saveUser;
@property (nonatomic,copy)   NSString       *applicationId;
@property (nonatomic,strong) NSDictionary   *launchOptions;
@end


@implementation EzPush


//make it singleton
+ (id)sharedManager {
    static EzPush *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        NSLog(@"EzPush init once.");
    });
    return sharedMyManager;
}

- (id)init {
    
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActiveNotification)
                                                 name:UIApplicationWillResignActiveNotification object:nil];*/
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

- (void)didBecomeActiveNotification{
    NSLog(@"Ezpush UIApplicationDidBecomeActiveNotification");
    [socketIO disconnectForced];
}
+ (void)didAcceptLocalNotification:(UILocalNotification*)notification application:(UIApplication*)application
{
    //TODO;
}
+ (void)EzPushApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
        EzPush *anInstance = [EzPush sharedManager];
        
        if([EzPush enableDebugLogs]){
            NSLog(@"didReceiveRemoteNotification = %@",userInfo);
        }
        if (anInstance->socketIO.isConnected) {
            NSString *json =  [NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push/notificationOpened/1.0\",\"contextId\":\"%@\",\"data\":{\"hwid\":\"%@\",\"applicationId\":\"%@\",\"notificationId\":\"%@\"}}",anInstance.contextId,[anInstance stringFromDeviceToken],anInstance.applicationId,userInfo[@"nid"]];
            
            //opened from a push notification when the app was on background
            [anInstance->socketIO sendMessage:json];
        }
        else{
            
            [anInstance connectSocket];
            
            if (userInfo[@"nid"]) {
                NSString *json =  [NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push/notificationOpened/1.0\",\"contextId\":\"%@\",\"data\":{\"hwid\":\"%@\",\"applicationId\":\"%@\",\"notificationId\":\"%@\"}}",anInstance.contextId,[anInstance stringFromDeviceToken],anInstance.applicationId,userInfo[@"nid"]];
                
                //opened from a push notification when the app was on background
                [anInstance->socketIO sendMessage:json];
            }
            
        }
    }
}

- (void)connectToServer{
    
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    socketIO.useSecure = socketSecure;
    [socketIO connectToHost:socketHost onPort:socketPort];
    
    
    SocketIOCallback cb = ^(id argsData) {
        NSDictionary *response = argsData;
        NSLog(@"%@",response);
        // do something with response
    };
    
   // NSDictionary *json = @{@"qualifier": @"pt.openapi.context/createContextRequest", @"data": @{@"properties":@"null"}};
    
    [socketIO sendMessage:@"{\"qualifier\":\"pt.openapi.context/createContextRequest\",\"data\":{\"properties\":null}}" withAcknowledge:cb];

}

+ (void)initWithLaunchOptions:(NSDictionary*)launchOptions appId:(NSString*)appId{
    
    EzPush *anInstance = [EzPush sharedManager];
    anInstance.applicationId = appId;
    anInstance.launchOptions = launchOptions;

}

-(void)processRemoteNotification:(NSDictionary *)userInfo {
    //let's handle info!!!
    //Not yet complete, will modify by requirements
    NSLog(@"HANDLING INFO");
    NSString *URL = @"";
    if( [userInfo objectForKey:@"URL"] != NULL)
    {
        URL = [userInfo objectForKey:@"URL"];
        NSLog(@"%@",URL);
        NSURL *candidateURL = [NSURL URLWithString:URL];
        // WARNING > "test" is an URL according to RFCs, being just a path
        // so you still should check scheme and all other NSURL attributes you need
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            // candidate is a well-formed url with, let's check if delegator responds to URL function
            if ([_delegate respondsToSelector:@selector(handleUrlOpen:)]) {
                [_delegate handleUrlOpen:candidateURL];
            }
        }
    }
}

+ (void)registerDevice:(NSData *)deviceToken {
    
    EzPush *anInstance = [EzPush sharedManager];
    anInstance.pushToken = deviceToken;
    
    if([EzPush enableDebugLogs])
        NSLog(@"I got token, and connecting!!!!");
    
    [anInstance connectSocket];
}
-(void) executeQue {
    if (_queString) {
        NSArray *queSelectors = [_queString componentsSeparatedByString:@":"];
        if ([queSelectors[0] isEqualToString:@"registerUserName"]) {
            [EzPush registerUserName:queSelectors[1]];
        }
        _queString = nil;
    }
}
-(void) connectSocket {
    if (self.pushToken) {
        if([EzPush enableDebugLogs])
            NSLog(@"I have token, I can start connection");
        
        socketIO = [[SocketIO alloc] initWithDelegate:self];
        socketIO.useSecure = socketSecure;
        [socketIO connectToHost:socketHost onPort:socketPort];
        
        //need to get context
        [socketIO sendMessage:@"{\"qualifier\":\"pt.openapi.context/createContextRequest\",\"data\":{\"properties\":null}}"];
    } else {
        if([EzPush enableDebugLogs])
            NSLog(@"I don't have token /:");
    }
}

-(void) registerDeviceForPush {
    [socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/registerDevice/1.0\",\"contextId\":\"%@\",\"data\":{\"_id\":{\"hwid\":\"%@\",\"applicationId\":\"%@\"},\"pushToken\":\"%@\",\"language\":\"en\",\"platform\":1,\"timeZone\":7200}}",_contextId, [self stringFromDeviceToken],_applicationId,[self stringFromDeviceToken]]];
}

+(void) registerUserName:(NSString*) username {
    
    EzPush *anInstance = [EzPush sharedManager];
    
    NSString *oldUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    if (oldUser && [oldUser isEqualToString:username]) {
        if([EzPush enableDebugLogs])
            NSLog(@"We already have this username: %@",username);
        return;
    }
    
    if (anInstance->socketIO.isConnected) {
        if (anInstance.contextId) {
            if([EzPush enableDebugLogs])
                NSLog(@"rEGISTERING uSERNAME");
            
            //it's new or different from what we have, so let's update ptech
            anInstance.saveUser = username;
            [anInstance->socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateUserId\",\"contextId\":\"%@\",\"data\":{\"deviceRegistrationId\":{\"hwid\":\"%@\",\"applicationId\":\"%@\"},\"userIdentity\":\"%@\"}}",anInstance.contextId, [anInstance stringFromDeviceToken], anInstance.applicationId, username]];
        }
    }
    
    else {
        if([EzPush enableDebugLogs])
            NSLog(@"socketIO NOT connected ... update tags");
        
        [anInstance connectSocket];
        
        if (anInstance->socketIO.isConnected) {
            if (anInstance.contextId) {
                if([EzPush enableDebugLogs])
                    NSLog(@"REGISTERING USERNAME");
                
                //it's new or different from what we have, so let's update ptech
                anInstance.saveUser = username;
                [anInstance->socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateUserId\",\"contextId\":\"%@\",\"data\":{\"deviceRegistrationId\":{\"hwid\":\"%@\",\"applicationId\":\"%@\"},\"userIdentity\":\"%@\"}}",anInstance.contextId, [anInstance stringFromDeviceToken], anInstance.applicationId, username]];
            }
        }
        //anInstance.queString = [NSString stringWithFormat:@"registerUserName:%@",username];
        //[anInstance connectSocket];
    }
}
+ (void)setGeoLocationLatitude : (float)latitude andLongitude:(float) longitude{
    EzPush *anInstance = [EzPush sharedManager];
    
    if (anInstance->socketIO.isConnected) {
        if (anInstance.contextId) {
            [anInstance->socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateLocation\",\"contextId\":\"%@\",\"data\":{\"hwid\":\"%@\",\"longitude\":%f,\"latitude\":%f}}",anInstance.contextId,[anInstance stringFromDeviceToken],longitude,latitude]];
        }
    }
    
    else{
        if([EzPush enableDebugLogs])
            NSLog(@"socketIO NOT connected ... update tags");
        
        [anInstance connectSocket];
        
        
        if (anInstance->socketIO.isConnected) {
            if (anInstance.contextId) {
                [anInstance->socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateLocation\",\"contextId\":\"%@\",\"data\":{\"hwid\":\"%@\",\"longitude\":%f,\"latitude\":%f}}",anInstance.contextId,[anInstance stringFromDeviceToken],longitude,latitude]];
            }
        }
        
    }
    
    
}

+ (void)updateTags : (NSArray*)tags{
    EzPush *anInstance = [EzPush sharedManager];
    
    NSString *json = [anInstance jsonStringFromNSdictionary:tags];
    
    if (anInstance->socketIO.isConnected) {
        if (anInstance.contextId) {
            if([EzPush enableDebugLogs])
                NSLog(@"socketIO connected ... update tags");
            
            //it's new or different from what we have, so let's update ptech
            if (json.length > 0) {
                
                NSString *jsonFormat = [NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateTags\",\"contextId\":\"%@\",\"data\":{\"deviceRegistrationId\":{\"hwid\":\"%@\",\"applicationId\":\"%@\"},\"tags\":%@}}",anInstance.contextId,[anInstance stringFromDeviceToken],anInstance.applicationId,json];
                
                if([EzPush enableDebugLogs])
                    NSLog(@"Tags JSON == %@",jsonFormat);
                
                [anInstance->socketIO sendMessage:jsonFormat];
            }
        }
    }
    else {
        if([EzPush enableDebugLogs])
            NSLog(@"socketIO NOT connected ... update tags");
        
        [anInstance connectSocket];
        
        if([EzPush enableDebugLogs])
            NSLog(@"socketIO try to connected ... update tags");
        
        if (anInstance->socketIO.isConnected) {
            if (anInstance.contextId) {
                
                if([EzPush enableDebugLogs])
                    NSLog(@"socketIO connected ... update tags");
                
                if (json.length > 0) {
                    [anInstance->socketIO sendMessage:[NSString stringWithFormat:@"{\"qualifier\":\"pt.openapi.push.devreg/updateTags\",\"contextId\":\"%@\",\"data\":{\"deviceRegistrationId\":{\"hwid\":\"%@\",\"applicationId\":\"%@\"},\"tags\":[{\"key\":\"casino\",\"value\":\"galaUpdated\"}]}}",anInstance.contextId,[anInstance stringFromDeviceToken],anInstance.applicationId]];
                }
            }
        }
    }
    
    
}
- (NSString*)stringFromDeviceToken {
    
    NSData *tokenData = self.pushToken;
    const char* data = [tokenData bytes];
    NSMutableString* token = [NSMutableString string];
    for (int i = 0; i < [tokenData length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    return token;
}

- (void) socketIODidConnect:(SocketIO *)socket {
    if([EzPush enableDebugLogs])
        NSLog(@"socketIODidConnect!!!!");
}
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    if([EzPush enableDebugLogs])
        NSLog(@"socketIODidDisconnect = %@",error.description);
}
- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    
    if([EzPush enableDebugLogs])
        NSLog(@"didReceiveMessage >>> data: %@", packet.data);
    
    NSData *packetData = [packet.data dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:packetData options:0 error:nil];
    NSString *qualifier = [json objectForKey:@"qualifier"];
    if ([qualifier isEqualToString:@"pt.openapi.context/createContextResponse"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"contextId"] == [NSNull null]) {
            if([EzPush enableDebugLogs])
                NSLog(@"NO CONTEXT ID");
        }
        else {
            _contextId = [data objectForKey:@"contextId"];
            //check is no saved token in settings, must send request to server to set token
            NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
            if (oldToken) {
                if([EzPush enableDebugLogs])
                    NSLog(@"I already have old token, let's check if something else needed");
                [self executeQue];
            }
            else {
                if([EzPush enableDebugLogs])
                    NSLog(@"I don't have old token, let's register my device");
                [self registerDeviceForPush];
            }
        }
    }
    
    //-----------------------
    
    else if ([qualifier isEqualToString:@"pt.openapi.push.devreg/registerDeviceResponse"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        }
        else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //device successfuly registered, save token for future
            if([EzPush enableDebugLogs])
                NSLog(@"device successfuly registered, save token for future & check if something else needed");
            
            [[NSUserDefaults standardUserDefaults] setObject:self.pushToken forKey:@"deviceToken"];
            //let's check if something else needed
            [self executeQue];
        }
    }
    //-----------------------
    
    else if([qualifier isEqualToString:@"pt.openapi.push.devreg/updateUserIdResponse"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        } else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //user successfuly registered, save user for future
            if([EzPush enableDebugLogs])
                NSLog(@"user successfuly registered, save user for future & check if something else needed");
            [[NSUserDefaults standardUserDefaults] setObject:_saveUser forKey:@"username"];
            
            if([EzPush enableDebugLogs])
                NSLog(@"saved user: %@",_saveUser);
        }
    }
    
    //-----------------------GeoLocation
    
    else if ([qualifier isEqualToString:@"pt.openapi.push.devreg/updateLocation"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        }
        else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //device successfuly registered, save token for future
            if([EzPush enableDebugLogs])
                NSLog(@"device successfuly send geoLocation");
            //let's check if something else needed
            [self executeQue];
        }
    }
    
    
    //-----------------------TAGS
    
    else if ([qualifier isEqualToString:@"pt.openapi.push.devreg/updateTags"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        }
        else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //device successfuly registered, save token for future
            if([EzPush enableDebugLogs])
                NSLog(@"device successfuly update tags");
            
            //let's check if something else needed
            [self executeQue];
        }
    }
    
    else if ([qualifier isEqualToString:@"pt.openapi.context/createContextRequest"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        }
        else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //device successfuly registered, save token for future
            if([EzPush enableDebugLogs])
                NSLog(@"device successfuly createContextRequest");
            
            //let's check if something else needed
            [self executeQue];
        }
    }
    
    else if ([qualifier isEqualToString:@"pt.openapi.push/notificationOpened"]) {
        id data = [json objectForKey:@"data"];
        if ([data objectForKey:@"code"] == [NSNull null]) {
            //no code?
        }
        else if ([[data objectForKey:@"code"] integerValue] == 0) {
            //device successfuly registered, save token for future
            if([EzPush enableDebugLogs])
                NSLog(@"device successfuly update notificationOpened");
            
            //let's check if something else needed
            [self executeQue];
        }
    }
}

-(NSString*) jsonStringFromNSdictionary : (NSArray<EzPushTag *>*)ezpushTags{
    
    
    if ([EzPush enableDebugLogs]) {
        NSLog(@"Taglist == %@",ezpushTags);
    }
    

    NSMutableArray *objectsArray = [NSMutableArray new];
    
    for (EzPushTag *tag in ezpushTags) {
        
        NSDictionary *tagObject = @{@"key":tag.key,@"value":tag.value,@"type":tag.type};
        if ([EzPush enableDebugLogs]) {
            NSLog(@"Tag KEY == %@",tagObject);
        }
        [objectsArray addObject:tagObject];
        
        if ([EzPush enableDebugLogs]) {
            NSLog(@"Tags array == %@",objectsArray);
        }
    }
    
    if (objectsArray.count > 0) {
        
        NSError * err;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:objectsArray options:0 error:&err];
        NSString* jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
        
        if ([EzPush enableDebugLogs]) {
            NSLog(@"Taglist JSON == %@",jsonString);
        }
        return jsonString;
    }
    return @"";
}

- (NSString*)DictionaryToJSONString : (NSDictionary*)jsonDict{
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    return jsonString;
}
+ (void)enableDebugLogs : (BOOL)enable{
    EzPush *anInstance = [EzPush sharedManager];
    anInstance.enableLog = enable;
}

+ (BOOL)enableDebugLogs {
    EzPush *anInstance = [EzPush sharedManager];
    return anInstance.enableLog;
}
- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    if([EzPush enableDebugLogs])
        NSLog(@"I Rcived json packet");
}
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    if([EzPush enableDebugLogs])
        NSLog(@"I Rcived event packet");
}
- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    if ([error code] == SocketIOUnauthorized) {
        NSLog(@"not authorized");
    } else {
        NSLog(@"onError() %@", error);
    }
}
- (void)handleUrlOpen:(NSURL*)url {
    if([EzPush enableDebugLogs])
        NSLog(@"I GOT TO WRONG PLACE /:");
}

//suporting methods


@end

