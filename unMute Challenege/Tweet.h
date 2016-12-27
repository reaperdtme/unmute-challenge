//
//  Tweet.h
//  unMute Challenege
//
//  Created by Zaid Daghestani on 12/26/16.
//  Copyright © 2016 ark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tweet : NSObject

@property (nonatomic, strong) NSString *name, *url;
@property NSInteger volume;

+(Tweet *)fromDict:(NSDictionary *)dict;

@end
