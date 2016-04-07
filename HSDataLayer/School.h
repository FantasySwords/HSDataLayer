//
//  School.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "HSTable.h"

@interface School : HSTable 

@property (nonatomic, assign) NSInteger shcoolId;
@property (nonatomic, copy) NSString * schoolName;
@property (nonatomic, strong) NSDate * birthDate;


@end
