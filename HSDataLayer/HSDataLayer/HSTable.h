//
//  HSTable.h
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/11.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSTableConfig.h"
#import "HSDatabase.h"
#import "HSQueryCriteria.h"

@protocol HSTableProtocol <NSObject>

@optional

//键映射
+(NSDictionary *)hs_keyMapper;

//单一主键
+(NSString *)hs_primaryKey;

//联合主键
+(NSArray *)hs_compositeKeys;

//忽略转换的属性
+(NSArray *)hs_ignoreProperties;

//设置表在哪个数据库中
+(NSString *)hs_databaseName;

@end


@interface HSTable : NSObject <HSTableProtocol>

//默认主键，如果子类不指定主键，使用rowid作为主键
@property (nonatomic, assign) NSInteger rowid;

@property (nonatomic, strong) HSTableConfig * tableConfig;

//将数据保存到数据库中，如果原来有数据更新数据，如果原来没有数据则插入数据,表需要自定义主键
- (BOOL)saveToDB;
//插入到数据库中
- (BOOL)insertToDB;
//更新数据库记录
- (BOOL)updateToDB;
//从数据库中删除记录
- (BOOL)deleteFromDB;

//数据是否存在数据库中
- (BOOL)isExistInDB;
//获取数据库记录总条数
+ (NSInteger)allRecordCount;
//设置查询条件，查询记录中条数
+ (NSInteger)allRecordCountWithWhereCondition:(NSString *)whereCondition;

/**
 *  获取数据库对应表中所有数据
 *  @return 根据表中记录数据生成的对象数组
 */
+ (NSArray *)queryAllRecords;

/**
 *  根据唯一主键生成对象 必须是唯一主键
 *
 *  @param pk 唯一主键对应的值 只支持NSString, NSNumber 类型
 *
 *  @return 返回对应的对象，如果数据库中没有对应的数据，返回nil
 */
+ (instancetype)queryRecordWithPrimaryKey:(id)pk;

/**
 *  获取最近插入的一条记录,
 *
 *  @return 返回对应的对象，如果数据库中没有对应的数据，返回nil
 */
+ (instancetype)queryLatestRecord;

/**
 *  直接使用SQL语句，查询数据库记录
 *
 *  @param sqlString sql语句
 *
 *  @return 返回对象数组
 */
+ (NSArray *)queryRecordsWithSQL:(NSString *)sqlString;

/**
 *  使用HSQueryCriteria的对象，查询数据库记录
 *
 *  @param criteria 使用HSQueryCriteria指定查询条件 不用谢sql语句了
 *
 *  @return 返回对象数组
 */
+ (NSArray *)queryRecordsWithCriteria:(HSQueryCriteria *)criteria;

/**
 *  指定limit,offset查询数据库，如果想同时设置排序，升序，降序，请使用[queryRecordsWithCriteria:];
 *
 *  @param limit 最多查询记录的个数
 *  @param offset 起始位置
 *
 *  @return 返回对象数组
 */
+ (NSArray *)queryRecordsWithLimit:(NSInteger)limit offset:(NSInteger)offset;

//批量将保存数据到数据库，HSTable需要指定主键
+ (BOOL)saveRecordsWithArray:(NSArray *) array;

//批量插入记录
+ (BOOL)insertRecordsWithArray:(NSArray *) arrray;

//批量更新记录
+ (BOOL)updateRecordsWithArray:(NSArray *) array;

//批量删除记录，HSTable需要指定主键
+ (BOOL)deleteRecordsWithArray:(NSArray *) array;

//使用where条件语句，批量删除数据
+ (BOOL)deleteRecoderdsWithWhere:(NSString *)whereCondition;

//清空数据表
+ (BOOL)clearTable;



@end
