//
//  NSString+BaseString.m
//  unMute Challenege
//
//  Created by Zaid Daghestani on 12/26/16.
//  Copyright © 2016 ark. All rights reserved.
//

#import "NSString+BaseString.h"

@implementation NSString (BaseString)

-(NSString *)base64 {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

@end
