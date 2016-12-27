//
//  Tweet.m
//  unMute Challenege
//
//  Created by Zaid Daghestani on 12/26/16.
//  Copyright © 2016 ark. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

+(Tweet *)fromDict:(NSDictionary *)dict {
    Tweet *t = [Tweet new];
    t.name = dict[@"name"];
    t.url = dict[@"url"];
    if (dict[@"tweet_volume"] != [NSNull null])
        t.volume = [dict[@"tweet_volume"] integerValue];
    else
        t.volume = 0;
    return t;
}

@end
