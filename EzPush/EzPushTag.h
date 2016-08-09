//
//  EzPushTag.h
//  EzPush_SDK
//
//  Created by Haggai Elazar on 09/08/2016.
//  Copyright © 2016 Playtech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EzPushTag : NSObject

@property(nonnull,nonatomic ,copy) NSString  *key;
@property(nonnull,nonatomic ,copy) NSString *value;
@property(nonnull,nonatomic ,copy) NSString *type;
@end
