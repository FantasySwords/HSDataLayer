//
//  Course.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/29.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSTable.h"

@interface Course : HSTable 

@property (nonatomic, assign) NSInteger shcoolId;

@property (nonatomic, strong) NSString * studentId;

@property (nonatomic, assign) float score;

@end
