//
//  HSTableConfig.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSTableConfig.h"
#import "FMDB.h"
#import "HSColumn.h"
#import "HSDatabase.h"

@implementation HSTableConfig

+ (HSTableConfig *)tableConfig
{
    return [[self alloc] init];
}

@end
