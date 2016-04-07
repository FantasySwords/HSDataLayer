//
//  HSPair.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/18.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HSPair : NSObject

- (instancetype)initWithFirst:(id)first second:(id)second;

@property (nonatomic, strong) id first;

@property (nonatomic, strong) id second;

@end

static inline HSPair *  hs_make_pair(id first,id second)
{
    return [[HSPair alloc] initWithFirst:first second:second];
}