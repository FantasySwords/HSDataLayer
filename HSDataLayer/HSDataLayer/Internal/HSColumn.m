//
//  HSColumn.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/17.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSColumn.h"


@interface HSColumn ()

@end

@implementation HSColumn

- (instancetype)init
{
    if (self = [super init]) {
        _isUnique = NO;
        _isNotNUll = NO;
        _isPrimaryKey = NO;
        _isAdditional = NO;
    }
    
    return self;
}

+ (instancetype)column
{
    return [[self alloc] init];
}

@end
