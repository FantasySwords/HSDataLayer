//
//  Student.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "Student.h"

@implementation Student


+(NSDictionary *)hs_keyMapper
{
    return @{@"name":@"stu_name",
             @"studentId":@"id"};
}

+(NSString *)hs_primaryKey
{
    return @"studentId";
}




@end
