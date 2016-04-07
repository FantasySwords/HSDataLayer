//
//  HSDataBase.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/11.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class FMDatabaseQueue;

@interface HSDatabase : NSObject

//使用FMDatabaseQueue，来防止多线程冲突
@property (nonatomic, strong, readonly) FMDatabaseQueue * fm_databseQueue;
//数据库的名字
@property (nonatomic, copy, readonly) NSString * hs_databaseName;
//数据库的路径
@property (nonatomic, copy, readonly) NSString * hs_databaseFilePath;

//根据数据库名，创建HSDatabase实例
- (instancetype)initWithDatabaseName:(NSString *)databaseName error:(NSError **)error;
//关闭数据库
- (void)closeDatabase;

//通过数据库名获取数据库实例
+ (HSDatabase *)dataBaseWithName:(NSString *)databaseName;

//清空数据库缓存数据
+ (void)clear;

/**
 *  通过数据库名设置当前的默认数据库，如果HSTable没有指定数据库，那么所有的操作都在默认数据库里面进行
 */
+ (BOOL)useDatabase:(NSString *)databaseName;

@end
