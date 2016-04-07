//
//  HSDataBase.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/11.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import <pthread.h>
#import "FMDB.h"
#import "HSDatabase.h"
#import "FMDatabase.h"

#define PATH_OF_HSDATA_ROOT [NSString stringWithFormat:@"%@/HSDataRoot",  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]

static NSMutableDictionary * hs_database_dict;
static pthread_mutex_t hs_database_mutex = PTHREAD_MUTEX_INITIALIZER;
static HSDatabase * hs_current_using_database = nil;

#define HS_DEFAULT_DATABASE_NAME @"hs_datalayer_default.db"

@interface HSDatabase ()

@end

@implementation HSDatabase

+ (void)initialize
{
    static dispatch_once_t once_handle;
    dispatch_once(&once_handle, ^{
        hs_database_dict = [[NSMutableDictionary alloc] init];
        pthread_mutex_init(&hs_database_mutex, NULL);
    });
}

/**
 *  获取对应名字的HSDatabase对象
 *
 *  @param databaseName 数据库名字,如果databaseName为nil的话 将返回默认的数据库
 *
 *  @return HSDatabase对象
 */
+ (HSDatabase *)dataBaseWithName:(NSString *)databaseName
{
    if (databaseName == nil && hs_current_using_database) {
        return hs_current_using_database;
    }
    
    if (hs_current_using_database == nil && databaseName == nil) {
         databaseName = HS_DEFAULT_DATABASE_NAME;
    }
   
    pthread_mutex_lock(&hs_database_mutex);
    
    HSDatabase * database  = [hs_database_dict objectForKey:databaseName];
    
    if (database == nil || ![database isKindOfClass:[HSDatabase class]]) {
        database = [[self alloc] initWithDatabaseName:databaseName error:nil];
        if (database) {
            [hs_database_dict setObject:database forKey:databaseName];
        }
    }
    
    if (hs_current_using_database == nil && [databaseName isEqualToString:HS_DEFAULT_DATABASE_NAME]) {
        hs_current_using_database = database;
    }
    
    pthread_mutex_unlock(&hs_database_mutex);
    
    return database;
}

/**
 *  将指定名字的HSDatabase对象从字典中移除，不负责关闭数据库, 如果databaseName是当前使用的数据库
 *  那么hs_current_using_database置为0
 *
 *  @param databaseName 数据库名字,如果databaseName为nil的话 没有任何动作
 */
+ (void)removeDatabaseWithName:(NSString *)databaseName
{
    if (databaseName == nil) {
        return;
    }
    
    pthread_mutex_lock(&hs_database_mutex);

    [hs_database_dict removeObjectsForKeys:@[databaseName]];
    
    if ([hs_current_using_database.hs_databaseName isEqualToString:databaseName]) {
        hs_current_using_database = nil;
    }
    
    pthread_mutex_unlock(&hs_database_mutex);
}

+ (void)clear
{
    pthread_mutex_lock(&hs_database_mutex);
    
    for (HSDatabase * db in hs_database_dict) {
        [db.fm_databseQueue close];
    }
    
    [hs_database_dict removeAllObjects];
    hs_current_using_database = nil;
    
    pthread_mutex_unlock(&hs_database_mutex);
}

- (instancetype)initWithDatabaseName:(NSString *)databaseName error:(NSError **)error
{
    NSParameterAssert(databaseName.length != 0);
    
    BOOL isDirectroy;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:PATH_OF_HSDATA_ROOT isDirectory:&isDirectroy];
    
    if (!isExists) {
        NSError * error = nil;
        BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:PATH_OF_HSDATA_ROOT withIntermediateDirectories:YES attributes:nil error:&error];
        if (!result || error) {
            NSLog(@"create directory failed! (%@)", error.description);
            return nil;
        }
    }else if(!isDirectroy) {
        NSLog(@"create directory failed! (has an existed file at specified PATH_OF_HSDATA_ROOT)");
        return nil;
    }
    
    _hs_databaseName = databaseName;
    _hs_databaseFilePath = [NSString stringWithFormat:@"%@/%@", PATH_OF_HSDATA_ROOT, databaseName];
    
    if (self = [super init]) {
        _fm_databseQueue = [FMDatabaseQueue databaseQueueWithPath:_hs_databaseFilePath];
        if (!_fm_databseQueue) {
            NSLog(@"database[%@] open failed, please be sure there are insufficient resources or permissions to open and/or create the database", databaseName);
            return nil;
        }
    }
    
    NSLog(@"%@",_hs_databaseFilePath);
    
    return self;
}

- (void)closeDatabase
{
    [HSDatabase removeDatabaseWithName:self.hs_databaseName];
    [self.fm_databseQueue close];
}

+ (BOOL)useDatabase:(NSString *)databaseName
{
    NSParameterAssert(databaseName);
    
    HSDatabase * database = [HSDatabase dataBaseWithName:databaseName];
    
    hs_current_using_database = database;
    
    if (!hs_current_using_database) {
        return NO;
    }
    
    return YES;
    
}

@end
