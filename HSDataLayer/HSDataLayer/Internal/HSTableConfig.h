//
//  HSTableConfig.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/22.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSTableConfig : NSObject

+ (HSTableConfig *)tableConfig;

@property (nonatomic, copy) NSString * hs_databaseName;

@property (nonatomic, copy) NSString * hs_tableName;

@property (nonatomic, strong) NSArray * hs_tableColumns;

@property (nonatomic, strong) NSArray * hs_primaryKeys;

@property (nonatomic, assign) Class hs_tableClass;

@property (nonatomic, strong) NSDictionary * hs_propertyTypeDict;

@end
