//
//  EzPush.m
//  EzPush
//
//  Created by Haggai Elazar on 09/08/2016.
//  Copyright © 2016 Playtech. All rights reserved.
//

#import "EzPush.h"


#define API_BASE_URL @"https://fe.techonlinecorp.com:4835/"


//#define applicationId @"<YOUR_APPLICATION_ID>"

@interface EzPush ()

@property(assign)            BOOL           enableLog;

@property (nonatomic,copy)   NSString       *applicationId;
@property (nonatomic,copy)   NSString       *EzPush_URL;
@property (nonatomic,strong) NSDictionary   *launchOptions;
@end


@implementation EzPush


//make it singleton
+ (id)sharedManager {
    static EzPush *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        NSLog(@"EP:SDK ACTIVE");
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
    NSLog(@"EP:didBecomeActiveNotification");

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
        
        NSDictionary *params = @{@"qualifier": @"pt.openapi.push.devreg/notificationOpened/1.0",
                                 @"data":@{@"hwid":@"hwid1", @"applicationId": anInstance.applicationId, @"notificationId":userInfo[@"nid"]}};
        if([EzPush enableDebugLogs])
            NSLog(@"EZ:didReceiveRemoteNotification : %@",params);
        
        [anInstance requestWithParams:params];

    }
}
+ (void)entryPointURL:(NSString*)url{
    EzPush *anInstance = [EzPush sharedManager];
    
    if (url == nil || url.length == 0) {
        anInstance.EzPush_URL = API_BASE_URL;
    }
    anInstance.EzPush_URL = url;
    
    if([EzPush enableDebugLogs])
        NSLog(@"EP:ENTRY POINT URL : %@",anInstance.EzPush_URL);
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
    NSString *newDeviceToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newDeviceToken = [newDeviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSDictionary *params = @{@"qualifier": @"pt.openapi.push.devreg/registerDevice/1.0",
                             @"data":@{@"_id":@{@"hwid":@"hwid1", @"applicationId": anInstance.applicationId},
                                       @"pushToken":newDeviceToken,
                                       @"language":@"EN",
                                       @"platform":@1,
                                       @"timeZone":@0,
                                       @"userIdentity":@"ul"}};
    if([EzPush enableDebugLogs])
        NSLog(@"EP:registerDevice : %@",params);
    
    [anInstance requestWithParams:params];

}



+(void) registerUserName:(NSString*) username {
    
    
    EzPush *anInstance = [EzPush sharedManager];
    
    NSDictionary *params = @{@"qualifier": @"pt.openapi.push.devreg/updateUserId",
                             @"data":@{@"deviceRegistrationId":@{@"hwid":@"hwid1", @"applicationId": anInstance.applicationId},
                                       @"userIdentity":username
                                       }};
    if([EzPush enableDebugLogs])
        NSLog(@"EP:registerUserName : %@",params);
    
    [anInstance requestWithParams:params];

    
}

+ (void)updateTags : (NSArray*)tags{
    
    
    
    EzPush *anInstance = [EzPush sharedManager];
     NSString *jsonTags = [anInstance jsonStringFromNSdictionary:tags];
    
    NSDictionary *params = @{@"qualifier": @"pt.openapi.push.devreg/updateTags",
                             @"data":@{@"deviceRegistrationId":@{@"hwid":@"hwid1", @"applicationId": anInstance.applicationId},
                                       @"tags":jsonTags}};
    if([EzPush enableDebugLogs])
        NSLog(@"EP:updateTags : %@",params);
    
    [anInstance requestWithParams:params];

}

+(void)setGeoLocationLatitude : (float)latitude andLongitude:(float) longitude{
    
    
    EzPush *anInstance = [EzPush sharedManager];

    NSDictionary *params = @{@"qualifier": @"pt.openapi.push.devreg/updateLocation",
                             @"data":@{@"hwid":@"hwid1", @"longitude": [NSNumber numberWithFloat:longitude],@"latitude": [NSNumber numberWithFloat:latitude]}};
    if([EzPush enableDebugLogs])
        NSLog(@"EP:setGeoLocationLatitude : %@",params);
    
    [anInstance requestWithParams:params];

}


-(NSString*) jsonStringFromNSdictionary : (NSArray<EzPushTag *>*)ezpushTags{
    
    
    if ([EzPush enableDebugLogs]) {
        NSLog(@"EP:Taglist == %@",ezpushTags);
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
            NSLog(@"EP:Taglist JSON == %@",jsonString);
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



- (void)handleUrlOpen:(NSURL*)url {
    if([EzPush enableDebugLogs])
        NSLog(@"I GOT TO WRONG PLACE /:");
}

//suporting methods

- (void)requestWithParams : (NSDictionary*)params{
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@",_EzPush_URL]];
    
    
    // Convert the dictionary into JSON data.
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0
                                                         error:nil];
    
    //NSData *JSONData = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create a POST request with our JSON as a request body.
    NSMutableURLRequest *request    = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod              = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody                = JSONData;
    
    // Create a task.
    NSURLSessionDataTask *task      = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                      completionHandler:^(NSData *data,
                                                                                          NSURLResponse *response,
                                                                                          NSError *error)
                                       {
                                           if (!error)
                                           {
                                               if([EzPush enableDebugLogs]){
                                                   NSLog(@"EP:Status code: %li", (long)((NSHTTPURLResponse *)response).statusCode);
                                                   NSString *__response = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                                   NSLog(@"EP:SERVER RESPONSE%@",__response);
                                               }

                                               
                                               
                                           }
                                           else
                                           {
                                               if([EzPush enableDebugLogs])
                                                   NSLog(@"EP: SERVER Error: %@", error.localizedDescription);
                                           }
                                       }];
    
    // Start the task.
    [task resume];
}
@end

