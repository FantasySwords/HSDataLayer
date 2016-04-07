//
//  HSColumn.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/17.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, HS_SQLITE_DATATYPE)
{
    HS_SQLITE_DATATYPE_NULL = 0,
    HS_SQLITE_DATATYPE_INTEGER,
    HS_SQLITE_DATATYPE_REAL,
    HS_SQLITE_DATATYPE_TEXT,
    HS_SQLITE_DATATYPE_BLOB
};

@interface HSColumn : NSObject

@property (nonatomic, copy) NSString * propertyName;

@property (nonatomic, copy) NSString * propertyAttribute;

@property (nonatomic, copy) NSString * propertyType;

@property (nonatomic, copy) NSString * columnName;

@property (nonatomic, assign) HS_SQLITE_DATATYPE columnDataType;


@property (nonatomic, assign) BOOL isUnique;
@property (nonatomic, assign) BOOL isNotNUll;
@property (nonatomic, assign) BOOL isPrimaryKey;

@property (nonatomic, assign) BOOL isAdditional;


+ (instancetype)column;

@end
