//
//  School.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "School.h"

@implementation School

+(NSString *)hs_databaseName
{
    return @"school.db";
}


+ (NSString *)hs_primaryKey
{
    return @"shcoolId";
}

@end
