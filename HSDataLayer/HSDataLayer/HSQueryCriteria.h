//
//  HSQueryCriteria.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/31.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSQueryCriteria : NSObject

//where条件
@property (nonatomic, strong) NSString * where;

//排序字段
@property (nonatomic, strong) NSString * orderBy;

//条数
@property (nonatomic, assign) NSInteger limit;

//偏移量
@property (nonatomic, assign) NSInteger offset;

//是否降序
@property (nonatomic, assign) BOOL isDESC;

//是否去掉重复的记录
@property (nonatomic, assign) BOOL isDistinct;

@end
