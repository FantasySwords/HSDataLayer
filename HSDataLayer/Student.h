//
//  Student.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSTable.h"

@interface Student : HSTable 

@property (nonatomic, assign) NSInteger studentId;

@property (nonatomic, copy) NSString * name;

@property (nonatomic, assign) NSInteger age;

@property (nonatomic, strong) NSDate * birthDate;

@property (nonatomic, strong) NSString  * remark;

@property (nonatomic, strong) NSString * a1;

@property (nonatomic, strong) NSString * a2;

@end
