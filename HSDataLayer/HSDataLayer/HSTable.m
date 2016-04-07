//
//  HSTable.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/11.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <objc/runtime.h>
#import <pthread.h>
#import "FMDB.h"

#import "HSTable.h"
#import "HSColumn.h"
#import "HSPair.h"
#import "HSTableConfig.h"

static NSMutableDictionary * hs_table_dict;
static pthread_mutex_t hs_table_mutex = PTHREAD_MUTEX_INITIALIZER;

@interface HSTable ()

@end

@implementation HSTable

- (instancetype)init
{
    if (self = [super init]) {
        self.tableConfig = [self.class getTableConfig];
    }
    
    return self;
}

+(NSString *)hs_databaseName
{
    return nil;
}

+(HSDatabase *)hs_getDatabase
{
    return [HSDatabase dataBaseWithName:[self hs_databaseName]];
}

+ (void)initialize
{
    static dispatch_once_t once_handle;
    dispatch_once(&once_handle, ^{
        hs_table_dict = [[NSMutableDictionary alloc] init];
        pthread_mutex_init(&hs_table_mutex, NULL);
    });
}

/**
 *  获取表的配置类
 *  @return 表的配置类
 */
+ (HSTableConfig *)getTableConfig
{
    HSTableConfig * tableConfig = nil;

    pthread_mutex_lock(&hs_table_mutex);
    
    NSString * className = NSStringFromClass(self);
    if (className && className.length) {
        tableConfig = [hs_table_dict objectForKey:className];
    }
    
    pthread_mutex_unlock(&hs_table_mutex);
    
    if (tableConfig == nil) {
        tableConfig = [self createTableConfig];
    }

    return tableConfig;
}

/**
 *  设置表的配置类
 */
+ (void)setTableConfig:(HSTableConfig *)tableConfig;
{
    NSParameterAssert(tableConfig);
    NSString * className = NSStringFromClass(self);
    pthread_mutex_lock(&hs_table_mutex);
    
    if (className && className.length && ![hs_table_dict objectForKey:className]) {
        [hs_table_dict setObject:tableConfig forKey:className];
        NSLog(@"%@ : %@", className, tableConfig.hs_tableColumns);
    }
    
    pthread_mutex_unlock(&hs_table_mutex);
}

/**
 * SQLite 支持数据类型：TEXT(文本)、INTEGER(整形)、REAL(浮点型)、BLOB(二进制块数据)、NULL(空值)
 * HSDataLayer支持的类型：char,int,long,short,long long,double,float,bool
 *                      signed unsigned (整形）,enum
 *                      NSInteger,CGFloat,BOOL
 *                      NSString, NSData, NSDate, NSNumber
 *
 */

+ (NSArray *)getPropertys
{
    unsigned int outCount;
    objc_property_t * properties = class_copyPropertyList([self class], &outCount);
    
    NSMutableArray * array = [NSMutableArray array];
    
    for (unsigned int i = 0; i < outCount ; i++) {

        objc_property_t property_obj = properties[i];
        const char * property_name = property_getName(property_obj);
        const char * property_attributes = property_getAttributes(property_obj);
        
        //name 和 attributes 不能为空
        if (property_name == NULL || property_attributes == NULL) {
            continue;
        }
        
        NSString * propertyName = [NSString stringWithUTF8String:property_name];
        NSString * propertyAttributes = [NSString stringWithUTF8String:property_attributes];
        NSString * propertyType = nil;
        
        //暂时屏蔽掉只读属性
        if ([propertyAttributes rangeOfString:@",R"].location != NSNotFound) {
            continue;
        }
        
        //OC类型
        if ([propertyAttributes hasPrefix:@"T@"]) {
            NSRange range = [propertyAttributes rangeOfString:@","];
            if (range.location == NSNotFound || range.location < 3) {
                continue;
            }
            if (range.location == 3) {
                //id 类型
            }else {
                range = NSMakeRange(3, range.location - 4);
                NSString * className = [propertyAttributes substringWithRange:range];
                 propertyType = className;
                if ([className hasSuffix:@">"]) {
                    NSRange localRange = [className rangeOfString:@"<"];
                    
                    if (localRange.location == NSNotFound) {
                        continue;
                    }
                    
                    className = [className substringToIndex:localRange.location];
                    //OC 类型
                    propertyType = className;
                }
                
            }
        }else if([propertyAttributes hasPrefix:@"T{"]){
            //结构体或者数组类型
            continue;
        }else {
            if ([propertyAttributes hasPrefix:@"T"] && propertyAttributes.length >= 2) {
                
                unichar ch =[propertyAttributes characterAtIndex:1];
                ch = tolower(ch);
                switch (ch) {
                    case 'c':
                        propertyType = @"char";
                        break;
                    case 'i':
                    case 'b':
                        propertyType = @"int";
                        break;
                    case 's':
                        propertyType = @"short";
                        break;
                    case 'l':
                    case 'q':
                        propertyType = @"long";
                        break;
                    case 'f':
                        propertyType = @"float";
                        break;
                    case 'd':
                        propertyType = @"double";
                        break;
                    default:
                        continue;
                        break;
                }
            }
        }
        
        if (propertyType.length) {
            HSPair * pair = hs_make_pair(propertyName,
                                         propertyType);
            [array addObject:pair];
            
        }
    }
    
    return array;
}


+ (NSArray *)getColumnsInfo
{
    NSArray * propertys = [self getPropertys];
    
    NSDictionary * transDictionary = @{@"NSString":@(HS_SQLITE_DATATYPE_TEXT),
                                       @"NSMutableString":@(HS_SQLITE_DATATYPE_TEXT),
                                       @"NSData":@(HS_SQLITE_DATATYPE_BLOB),
                                       @"NSMutableData":@(HS_SQLITE_DATATYPE_BLOB),
                                       @"NSDate":@(HS_SQLITE_DATATYPE_INTEGER),
                                       @"NSNumber":@(HS_SQLITE_DATATYPE_TEXT),
                                       @"char":@(HS_SQLITE_DATATYPE_INTEGER),
                                       @"int":@(HS_SQLITE_DATATYPE_INTEGER),
                                       @"short":@(HS_SQLITE_DATATYPE_INTEGER),
                                       @"long":@(HS_SQLITE_DATATYPE_INTEGER),
                                       @"float":@(HS_SQLITE_DATATYPE_REAL),
                                       @"double":@(HS_SQLITE_DATATYPE_REAL)};
    
    NSMutableArray * columnsArray = [NSMutableArray array];
    for (int i = 0; i < propertys.count; i++) {
        HSPair * pair = propertys[i];
        
        NSNumber * typeNumber = [transDictionary objectForKey:pair.second];
        if (!typeNumber) {
            NSLog(@"type[%@] is not supported for property[%@].", pair.second, pair.first);
            continue;
        }
        
        HSColumn * column = [HSColumn column];
        column.columnDataType = typeNumber.intValue;
        column.columnName = pair.first;
        column.propertyName = pair.first;
        column.propertyType = pair.second;
        [columnsArray addObject:column];
        
        //NSLog(@"%@, %@, %d",  column.columnName  , typeNumber, column.isPrimaryKey);
    }
    
    return columnsArray;
}

+ (HSTableConfig *)createTableConfig
{
    //是否有联合主键
    NSArray * compositeKeys = [self invokeSelector:@"hs_compositeKeys"];
    if (![compositeKeys isKindOfClass:[NSArray class]]) {
        //是否有单一主键
        NSString * primaryKey = [self invokeSelector:@"hs_primaryKey"];
        if([primaryKey isKindOfClass:[NSString class]] && primaryKey.length){
            compositeKeys = @[primaryKey];
        }else {
            compositeKeys = nil;
        }
    }
    
    NSArray * allColumns = [self getColumnsInfo];
    NSMutableDictionary * columnsDict = [NSMutableDictionary dictionary];
    
    for (HSColumn * column in allColumns) {
        [columnsDict setObject:column forKey:column.columnName];
    }
    
    if (compositeKeys && compositeKeys.count) {
        NSMutableArray * compositeColumns = [NSMutableArray array];
        for (NSString * key in compositeKeys) {
            if (![columnsDict objectForKey:key]) {
                NSAssert(0, @"can not find specified key at class.");
                return nil;
            }
            
            [compositeColumns addObject:[columnsDict objectForKey:key]];
        }
        
        compositeKeys = compositeColumns;
    }
    
    //键映射
    NSDictionary * keyMapperDictionary = [self invokeSelector:@"hs_keyMapper"];
    if(![keyMapperDictionary isKindOfClass:[NSDictionary class]]){
        keyMapperDictionary = nil;
    }
    
    for (int i = 0; i < allColumns.count; i++) {
        HSColumn * column = allColumns[i];
        column.columnName = [keyMapperDictionary objectForKey:column.columnName] ?:column.columnName;
        
        if (compositeKeys && [compositeKeys containsObject:column.columnName]) {
            column.isPrimaryKey = YES;
        }
    }
    
    HSTableConfig * tableConfig = [HSTableConfig tableConfig];
    //如果没有主键生成默认主键
    if (compositeKeys == nil || compositeKeys.count == 0) {
        HSColumn * rowidColumn = [HSColumn column];
        rowidColumn.columnName = @"rowid";
        rowidColumn.columnDataType = HS_SQLITE_DATATYPE_INTEGER;
        rowidColumn.isAdditional = YES;
        compositeKeys = @[rowidColumn];
        
        NSMutableArray * allMutabColumns = [allColumns mutableCopy];
        [allMutabColumns addObject:rowidColumn];
        allColumns = allMutabColumns;
    }
    
    tableConfig.hs_tableColumns = allColumns;
    tableConfig.hs_primaryKeys = compositeKeys;
    tableConfig.hs_tableName = NSStringFromClass(self);
    tableConfig.hs_tableClass = [self class];
    
    NSMutableDictionary * propertyDict = [NSMutableDictionary dictionary];
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = tableConfig.hs_tableColumns[i];
        
        if (column.isAdditional) {
            continue;
        }
        
        [propertyDict setObject:column.propertyType forKey:column.propertyName];
    }
    
    tableConfig.hs_propertyTypeDict = propertyDict;
    
    [self setTableConfig:tableConfig];
    
    [self createTableWithTableConfig:tableConfig];
    
    return tableConfig;
}


+ (NSString *)createTableSchema:(HSTableConfig *)tableConfig
{
    NSParameterAssert(tableConfig.hs_tableName);
    NSParameterAssert(tableConfig.hs_tableColumns.count);
    NSAssert(tableConfig.hs_primaryKeys.count, @"the primary key cannot be null.");
    
    NSMutableString * sqlString = [NSMutableString string];
    [sqlString appendFormat:@"create table if not exists %@ (\n", tableConfig.hs_tableName];
    
    //生成各数据列
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = tableConfig.hs_tableColumns[i];
        
        NSString * dataType = [self transToSqliteType:column.columnDataType];
        [sqlString appendFormat:@"%@ %@,\n", column.columnName, dataType];
    }
    
    //生成主键
    if (tableConfig.hs_primaryKeys.count) {
        [sqlString appendString:@"primary key ( "];
        
        for (int i = 0; i < tableConfig.hs_primaryKeys.count; i++) {
            HSColumn * pkColumn = tableConfig.hs_primaryKeys[i];
            if (i == tableConfig.hs_primaryKeys.count - 1) {
                [sqlString appendFormat:@"%@", pkColumn.columnName];
            }else {
                [sqlString appendFormat:@"%@,", pkColumn.columnName];
            }
        }
        
        [sqlString appendString:@")"];
    }
    
    [sqlString appendString:@");"];
    
    return sqlString;
}

+ (NSInteger)createTableWithTableConfig:(HSTableConfig *)tableConfig
{
    NSString * createSqlString = [self createTableSchema:tableConfig ];
    
    if (createSqlString == nil) {
        NSLog(@"can not create table schema.");
        return NO;
    }
    
    HSDatabase * database = [self hs_getDatabase];
    
    __block BOOL exist = NO;
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
        exist = [db tableExists:tableConfig.hs_tableName];
    }];
    
    if (!exist) {
        __block BOOL ret = NO;
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:createSqlString];
        }];
        
        return ret;
    }else {
        NSMutableDictionary * schemaDict = [NSMutableDictionary dictionary];
        
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            FMResultSet * set = [db getTableSchema:tableConfig.hs_tableName];
            
            while ([set next]) {
                NSString * name = [set stringForColumn:@"name"];
                NSString * type = [set stringForColumn:@"type"];
                [schemaDict setObject:type forKey:name];
            }
            
            [set close];
        }];
        
        NSMutableArray * newColumns = [NSMutableArray array];
        for (HSColumn * column in tableConfig.hs_tableColumns) {
            if (![schemaDict objectForKey:column.columnName]) {
                [newColumns addObject:column];
            }
        }
        
        __block BOOL ret = NO;
        [database.fm_databseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            //生成各数据列
            for (int i = 0; i < newColumns.count; i++) {
                
                NSMutableString * alertAddString = [NSMutableString stringWithFormat:@"alter table %@ add ", tableConfig.hs_tableName];
                HSColumn * column = newColumns[i];
                
                NSString * dataType = [self transToSqliteType:column.columnDataType];
                
                [alertAddString appendFormat:@"%@ %@", column.columnName, dataType];
                [alertAddString appendString:@";"];
                
                ret = [db executeUpdate:alertAddString];
                
                if (!ret) {
                    *rollback = YES;
                    break;
                }
            }
        }];
    }
    
    return exist;
}

+ (NSString *)transToSqliteType:(HS_SQLITE_DATATYPE)type
{
    switch (type) {
        case HS_SQLITE_DATATYPE_NULL:
            return @"null";
        case HS_SQLITE_DATATYPE_INTEGER:
            return @"integer";
        case HS_SQLITE_DATATYPE_REAL:
            return @"real";
        case HS_SQLITE_DATATYPE_TEXT:
            return @"text";
        case HS_SQLITE_DATATYPE_BLOB:
            return @"blob";
        default:
            NSAssert(0, @"Unable to determine the data type.");
            return nil;
    }
    
}

+ (id)invokeSelector:(NSString *)selectorString
{
    if ([self respondsToSelector:NSSelectorFromString(selectorString)]) {
        IMP imp = [self methodForSelector:NSSelectorFromString(selectorString)];
        if (imp) {
            return ((id (*)()) imp)();
        }
    }
    
    return nil;
}

//清空数据表
+ (BOOL)clearTable
{
    NSString * tableName = NSStringFromClass(self);
    NSString * sqlString = [NSString stringWithFormat:
                            @"delete from %@ ;"
                            @"update sqlite_sequence SET seq = 0 where name ='%@';", tableName,tableName ];
    
    HSDatabase * database = [self hs_getDatabase];
    __block BOOL ret = NO;
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
       ret = [db executeUpdate:sqlString];
    }];

    return ret;
}

//将对象保存到数据库
- (BOOL)saveToDB
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    return [self saveToDB:nil tableConfig:tableConfig];
   
}

- (BOOL)saveToDB:(FMDatabase *)fm_db tableConfig:(HSTableConfig *)tableConfig;
{
    NSMutableString * keyString = [NSMutableString string];
    NSMutableString * valueString = [NSMutableString string];
    NSMutableArray * insertValuesArray = [NSMutableArray array];
    
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = tableConfig.hs_tableColumns[i];
        //TODO:如果有添加的主键说明没有指定主键
        if (column.isAdditional) {
            continue;
        }
        
        id value = [self valueForKey:column.propertyName];
        if (value == nil) {
            value = @"";
        }
        
        [keyString appendFormat:@"%@,", column.columnName];
        [valueString appendString:@"?,"];
        
        [insertValuesArray addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    __block BOOL ret = NO;
    NSString * sqlString = [NSString stringWithFormat:@"insert or replace into %@(%@) values (%@);",tableConfig.hs_tableName, keyString, valueString];
    
    if (fm_db) {
        ret = [fm_db executeUpdate:sqlString withArgumentsInArray:insertValuesArray];
    }else {
        HSDatabase * database = [self.class hs_getDatabase];
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sqlString withArgumentsInArray:insertValuesArray];
        }];
    }
    
    return ret;
}


//
//插入到数据库中
- (BOOL)insertToDB
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    return [self insertToDB:nil tableConfig:tableConfig];
}

- (BOOL)insertToDB:(FMDatabase *)fm_db tableConfig:(HSTableConfig *)tableConfig;
{
    NSMutableString * keyString = [NSMutableString string];
    NSMutableString * valueString = [NSMutableString string];
    NSMutableArray * insertValuesArray = [NSMutableArray array];
    
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = tableConfig.hs_tableColumns[i];
        //TODO:如果有添加的主键说明没有指定主键
        if (column.isAdditional) {
            continue;
        }
        
        id value = [self valueForKey:column.propertyName];
        if (value == nil) {
            value = @"";
        }
        
        [keyString appendFormat:@"%@,", column.columnName];
        [valueString appendString:@"?,"];
        
        [insertValuesArray addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    __block BOOL ret = NO;
    NSString * sqlString = [NSString stringWithFormat:@"insert into %@(%@) values (%@);",tableConfig.hs_tableName, keyString, valueString];
    
    if (fm_db) {
        ret = [fm_db executeUpdate:sqlString withArgumentsInArray:insertValuesArray];
    }else {
        HSDatabase * database = [self.class hs_getDatabase];
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sqlString withArgumentsInArray:insertValuesArray];
        }];
    }

    return ret;
}

//更新数据库记录
- (BOOL)updateToDB
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    return [self updateToDB:nil tableConfig:tableConfig];
   
}

- (BOOL)updateToDB:(FMDatabase *)fm_db tableConfig:(HSTableConfig *)tableConfig
{
    NSMutableString * keyString = [NSMutableString string];
    NSMutableArray * updateValueArray = [NSMutableArray array];
    
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = tableConfig.hs_tableColumns[i];
        //TODO:如果有添加的主键说明没有指定主键
        if (column.isAdditional) {
            continue;
        }
        
        id value = [self valueForKey:column.propertyName];
        if (value == nil) {
            value = @"";
        }
        
        [keyString appendFormat:@" %@=?,", column.columnName];
        [updateValueArray addObject:value];
    }
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    
    NSString * whereCondition = [HSTable getUniqueWhereCondition:tableConfig withInstance:self];
    if (whereCondition.length == 0) {
        //无法生成唯一标识where条件
        return NO;
    }
    
    NSString * sqlString = [NSString stringWithFormat:@"update %@ set %@ where %@",tableConfig.hs_tableName, keyString, whereCondition];
    
    __block BOOL ret = NO;
    
    if (fm_db) {
        ret = [fm_db  executeUpdate:sqlString withArgumentsInArray:updateValueArray];
    }else {
        HSDatabase * database = [self.class hs_getDatabase];
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sqlString withArgumentsInArray:updateValueArray];
        }];
    }
    
    return ret;
}

//从数据库中删除记录
- (BOOL)deleteFromDB
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    return [self deleteFromDB:nil tableConfig:tableConfig];
}

- (BOOL)deleteFromDB:(FMDatabase *)fm_db tableConfig:(HSTableConfig *)tableConfig
{
    NSString * whereCondition = [HSTable getUniqueWhereCondition:tableConfig withInstance:self];
    NSString * sqlString = [NSString stringWithFormat:@"delete from %@ where %@", tableConfig.hs_tableName, whereCondition];
    
    __block BOOL ret = NO;
    
    if (fm_db) {
        ret = [fm_db executeUpdate:sqlString];

    }else {
        HSDatabase * database = [self.class hs_getDatabase];
        [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sqlString];
        }];
    }
    
    return ret;

}

//数据是否存在数据库中
- (BOOL)isExistInDB
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self.class hs_getDatabase];
    
    NSString * whereCondition = [HSTable getUniqueWhereCondition:tableConfig withInstance:self];
    NSString * sqlString = [NSString stringWithFormat:@"select count(rowid) from %@ where %@", tableConfig.hs_tableName, whereCondition];
    
    __block BOOL ret = NO;
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * set = [db executeQuery:sqlString];
        if ([set columnCount] > 0 && [set next]) {
            int count = [set intForColumnIndex:0];
            if (count > 0) {
                ret = YES;
            }
        }
        
        [set close];
    }];
    
    return ret;
}

//通过主键生成唯一标识记录的where条件
+(NSString *) getUniqueWhereCondition:(HSTableConfig *)tableConfig withInstance:(HSTable *)instance
{
    //生成where语句
    NSMutableString * whereCondition = [NSMutableString string];
    for (NSInteger i = 0; i < tableConfig.hs_primaryKeys.count; i++) {
        HSColumn * column = tableConfig.hs_primaryKeys[i];
        
        id value = [instance valueForKey:column.propertyName];
        if (value == nil) {
            value = @"";
        }
        
        if (i != 0) {
            [whereCondition appendString:@" and "];
        }
        
        if ([value isKindOfClass:[NSString class]]) {
            [whereCondition appendFormat:@" %@='%@' ",column.columnName,value];
        }else if ([value isKindOfClass:[NSNumber class]]){
            [whereCondition appendFormat:@" %@=%@ ",column.columnName,value];
        }else {
            NSAssert(0, @"don’t support the primary key with other type, unless the type is Integer or String.");
        }
    }
    
    return whereCondition;
}

+ (BOOL)saveRecordsWithArray:(NSArray *) array
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self hs_getDatabase];
    
    __block BOOL ret = NO;
    [database.fm_databseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (int index = 0; index < array.count; index++) {
            HSTable * tableObj = array[index];
            if ([tableObj isKindOfClass:[HSTable class]]) {
                ret = [tableObj saveToDB:db tableConfig:tableConfig];
                
                if (!ret) {
                    *rollback = YES;
                    return;
                }
            }
        }
    
    }];
    
    return ret;
}

+ (BOOL)insertRecordsWithArray:(NSArray *) array
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self hs_getDatabase];
    
    __block BOOL ret = NO;
    [database.fm_databseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (int index = 0; index < array.count; index++) {
            HSTable * tableObj = array[index];
            if ([tableObj isKindOfClass:[HSTable class]]) {
                ret = [tableObj insertToDB:db tableConfig:tableConfig];
                
                if (!ret) {
                    *rollback = YES;
                    return;
                }
            }
        }
        
    }];
    
    return ret;
}

+ (BOOL)updateRecordsWithArray:(NSArray *) array
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self hs_getDatabase];
    
    __block BOOL ret = NO;
    [database.fm_databseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (int index = 0; index < array.count; index++) {
            HSTable * tableObj = array[index];
            if ([tableObj isKindOfClass:[HSTable class]]) {
                ret = [tableObj updateToDB:db tableConfig:tableConfig];
                
                if (!ret) {
                    *rollback = YES;
                    return;
                }
            }
        }
        
    }];
    
    return ret;
}

+ (BOOL)deleteRecordsWithArray:(NSArray *) array
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self hs_getDatabase];
    
    __block BOOL ret = NO;
    [database.fm_databseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (int index = 0; index < array.count; index++) {
            HSTable * tableObj = array[index];
            if ([tableObj isKindOfClass:[HSTable class]]) {
                ret = [tableObj deleteFromDB:db tableConfig:tableConfig];
                
                if (!ret) {
                    *rollback = YES;
                    return;
                }
            }
        }
        
    }];
    
    return ret;
}


+ (BOOL)deleteRecoderdsWithWhere:(NSString *)whereCondition
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    NSString * sqlString = [NSString stringWithFormat:@"delete from %@ where %@", tableConfig.hs_tableName, whereCondition];
    __block BOOL ret = NO;
    HSDatabase * database = [self hs_getDatabase];
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sqlString];
    }];
    
    return ret;
}


+ (NSInteger)allRecordCount
{
    return [self allRecordCountWithWhereCondition:nil];
}
                            
+ (NSInteger)allRecordCountWithWhereCondition:(NSString *)whereCondition
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    HSDatabase * database = [self hs_getDatabase];
    
    NSString * sqlString = nil;
    if (whereCondition.length) {
        sqlString = [NSString stringWithFormat:@"select count(rowid) from %@ where %@", tableConfig.hs_tableName, whereCondition];
    }else {
        sqlString = [NSString stringWithFormat:@"select count(rowid) from %@ ", tableConfig.hs_tableName];
    }
    
    __block NSInteger count = 0;
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * set = [db executeQuery:sqlString];
        
        if ([set columnCount] > 0 && [set next]) {
            count = [set intForColumnIndex:0];
        }
        
        [set close];
    }];
    
    return count;
}


#pragma mark - 查询
+ (NSMutableString *)getSelectListString:(HSTableConfig *)tableConfig isDistinct:(BOOL)isDistinct
{
    NSMutableString * sqlString = [NSMutableString stringWithString:@"select "];
    
    if (isDistinct) {
        [sqlString appendString:@"distinct"];
    }
    
    [sqlString appendString:@" rowid as rowid "];
    
    for (int i = 0; i < tableConfig.hs_tableColumns.count; i++) {
        HSColumn * column = [tableConfig.hs_tableColumns objectAtIndex:i];
        
        if ([[column.columnName lowercaseString] isEqualToString:@"rowid"]) {
            continue;
        }
        
        if ([column.columnName isEqualToString:column.propertyName]) {
            [sqlString appendFormat:@", %@ ", column.columnName];
        }else {
            [sqlString appendFormat:@", %@ as %@", column.columnName, column.propertyName];
        }
    }
    
    [sqlString appendFormat:@" from %@ ", tableConfig.hs_tableName];
    
    return sqlString;
}

+ (NSArray *)queryAllRecords
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    
    NSMutableString * sqlString = [self getSelectListString:tableConfig isDistinct:NO];
    
    return [self queryRecordsWithSQL:sqlString];
}

+ (instancetype)queryRecordWithPrimaryKey:(id)pk
{
    NSAssert([pk isKindOfClass:[NSString class]] || [pk isKindOfClass:[NSNumber class]], @"don’t support the primary key with other type, unless the type is Integer or String.");
    
    HSTableConfig * tableConfig = [self.class getTableConfig];
    NSAssert(tableConfig.hs_primaryKeys.count == 1, @"This method only supports the table with only one primary key.");
   
    NSMutableString * sqlString = [self getSelectListString:tableConfig isDistinct:NO];
    HSColumn * pkColumn = [tableConfig.hs_primaryKeys firstObject];
    [sqlString appendFormat:@" where %@=%@ ",pkColumn.columnName, pk];
    
    NSArray * objArray = [self queryRecordsWithSQL:sqlString];
    
    if (objArray && objArray.count) {
        return objArray.firstObject;
    }

    return nil;
}

+ (instancetype)queryLatestRecord
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    
    HSQueryCriteria * criteria = [[HSQueryCriteria alloc] init];
    criteria.limit = 1;
    NSString * sqlString = [self selectSQLStringWithCriteria:criteria TableConfig:tableConfig];
    
    NSArray * objArray = [self queryRecordsWithSQL:sqlString];
    
    if (objArray && objArray.count) {
        return objArray.firstObject;
    }
    
    return nil;
}

+ (NSArray *)queryRecordsWithSQL:(NSString *)sqlString
{
    NSParameterAssert(sqlString);
    
    NSMutableArray * array = [NSMutableArray array];
    HSDatabase * database = [self hs_getDatabase];
    
    [database.fm_databseQueue inDatabase:^(FMDatabase *db) {
        
        [db executeStatements:sqlString withResultBlock:^int(NSDictionary *resultsDictionary) {
            
            id obj = [[[self class] alloc] init];
            [obj setValuesForKeysWithDictionary:resultsDictionary];
            [array addObject:obj];
            return 0;
        }];
        
    }];
    
    return array;
}

+ (NSArray *)queryRecordsWithCriteria:(HSQueryCriteria *)criteria
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    
    NSString * sqlString = [self selectSQLStringWithCriteria:criteria TableConfig:tableConfig];
    
    return [self queryRecordsWithSQL:sqlString];
}

+ (NSArray *)queryRecordsWithLimit:(NSInteger)limit offset:(NSInteger)offset
{
    HSTableConfig * tableConfig = [self.class getTableConfig];
    
    HSQueryCriteria * criteria = [[HSQueryCriteria alloc] init];
    criteria.limit = limit;
    criteria.offset = offset;
    NSString * sqlString = [self selectSQLStringWithCriteria:criteria TableConfig:tableConfig];
    
    return [self queryRecordsWithSQL:sqlString];
}


+ (NSString *)selectSQLStringWithCriteria:(HSQueryCriteria *)criteria TableConfig:(HSTableConfig *)tableConfig
{
    NSParameterAssert(tableConfig && criteria);
    
    NSMutableString * sqlString = [NSMutableString string];
    
    [sqlString appendString:[self getSelectListString:tableConfig isDistinct:criteria.isDistinct]];

    if (criteria.where.length) {
        [sqlString appendFormat:@" where %@", criteria.where];
    }
    
    if (criteria.orderBy.length) {
        [sqlString appendFormat:@" order by %@ ", criteria.orderBy];
        
        if (criteria.isDESC) {
            [sqlString appendString:@" desc "];
        }
    }
    
    if (criteria.limit && criteria.offset) {
        [sqlString appendFormat:@"limit %ld, %ld", criteria.offset, criteria.limit];
    }else if(criteria.limit) {
        [sqlString appendFormat:@"limit %ld", criteria.limit];
    }else {
        NSAssert(0, @"You need to specify the value of limit");
    }
    
    [sqlString appendString:@";"];
    
    return sqlString;
}


#pragma mark - key values
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"UndefinedKey:%@",key);
    return;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if (!self.tableConfig) {
        self.tableConfig = [self.class getTableConfig];
    }
    
    NSString * keyType = self.tableConfig.hs_propertyTypeDict[key];
    if ([keyType isEqualToString:@"NSDate"]) {
        
        if ([value isKindOfClass:[NSString class]] && ((NSString *) value).length == 0) {
            value = nil;
        }else {
             value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
        }
    }
    
    [super setValue:value forKey:key];
}


@end
