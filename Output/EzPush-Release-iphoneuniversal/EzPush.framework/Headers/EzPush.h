//
//  EzPush.h
//  EzPush
//
//  Created by Haggai Elazar on 11/08/2016.
//  Copyright © 2016 Playtech. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EzPushTag.h"

//! Project version number for EzPush.
FOUNDATION_EXPORT double EzPushVersionNumber;

//! Project version string for EzPush.
FOUNDATION_EXPORT const unsigned char EzPushVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <EzPush/PublicHeader.h>


@protocol EzPushDelegate <NSObject>
@optional
- (void)handleUrlOpen:(NSURL*)url;
@end

@interface EzPush : NSObject

@property (assign) id<EzPushDelegate> delegate;


/**
 * init EzPush SDK
 * Call it from within didFinishLaunchingWithOptions
 * @param application id
 * @param launchOptions
 */
+ (void)initWithLaunchOptions:(NSDictionary*)launchOptions appId:(NSString*)appId;


/**
 * Register a device with EzPush service
 * call this method after initiate is succeeded
 * @param deviceToken The deviceToken of the device
 */
+ (void)registerDevice:(NSData *)deviceToken;

/**
 * Used as a placeholder currently for future features when a notification is delivered while the application is running in foreground
 * Call from within UIApplicationDelegate didReceiveNotification with same parameters to track a push open
 * @param application The UIApplication from the parent
 * @param notification The notification from the parent
 */
+ (void)didAcceptLocalNotification:(UILocalNotification*)notification application:(UIApplication*)application;

/**
 * Register user with EzPush service
 * call this method after login process is succeeded
 * @param username - The username as string
 */
+ (void)registerUserName:(NSString*) username;

/**
 * set user geo location with EzPush service
 * update location after you get new location points
 * @param latitude - The device latitude as float
 * @param longitude - The device longitude as float
 */

+ (void)setGeoLocationLatitude : (float)latitude andLongitude:(float) longitude;

/**
 * update tags with EzPush service
 * call this method after initiate is succeeded
 * @param tags - collection of key value EzpushTag objects
 */

+ (void)updateTags : (NSArray<EzPushTag *>*)tags;

/**
 * init EzPush SDK
 * Call it from within didFinishLaunchingWithOptions
 * @param url ezpush url entry point
 */
+ (void)entryPointURL:(NSString*)url;


/**
 * enable debug logs with EzPush service
 * call this method after initiate is succeeded
 * @param enable - show or hide logs
 */

+ (void)enableDebugLogs : (BOOL)enable;

/**
 * enable count open app from push with EzPush service
 * call this method from didReceiveRemoteNotification
 * @param application
 * @param userInfo
 */
+ (void)EzPushApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;


@end
