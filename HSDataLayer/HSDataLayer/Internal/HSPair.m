//
//  HSPair.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/18.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSPair.h"

@implementation HSPair

- (instancetype)initWithFirst:(id)first second:(id)second
{
    if (self = [super init]) {
        self.first = first;
        self.second = second;
    }

    return self;
}

@end
