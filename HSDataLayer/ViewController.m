//
//  ViewController.m
//  HSDataLayer
//
//  Created by hexiaojian on 16/3/11.
//  Copyright © 2016年 Jerry Ho. All rights reserved.
//

#import "ViewController.h"
#import "HSDataLayer.h"
#import "Student.h"
#import "School.h"
#import "Course.h"
#import <mach/mach_time.h> 

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置当前使用数据库
    [HSDatabase useDatabase:@"demo_default.db"];
    
    //增
    Student * student = [[Student alloc] init];
    student.studentId = 10003;
    student.name = @"何小健";
    student.remark = @"好帅，好帅";
    [student saveToDB];
    
    Student * temp = [[Student alloc] init];
    temp.studentId = 10004;
    temp.name = @"何小贱";
    temp.remark = @"好贱，好贱";
    [temp saveToDB];
    
    //改
    temp.birthDate = [NSDate date];
    [temp updateToDB];
    
    //删
    [temp deleteFromDB];
    
    //通过主键获取一条记录，要保证唯一主键
    Student * aNewStudent = [Student queryRecordWithPrimaryKey:@10003];
    NSLog(@"%ld %@ %@", aNewStudent.studentId, aNewStudent.name, aNewStudent.remark);
    
    //获取记录的条数
    NSInteger studentCount = [Student allRecordCount];
    NSLog(@"Student记录条数：%ld",studentCount);
    
    //批量插入
    NSMutableArray * stuArray = [NSMutableArray array];
    for (int i = 0; i < 10000; i++) {
        Student * student = [[Student alloc] init];
        student.studentId = 200000 + i;
        student.name = [NSString stringWithFormat:@"何小健的老婆%d", i];
        student.remark = @"好漂亮，好大";
    
        [stuArray addObject:student];
    }
    
    NSLog(@"开始插入数据");
    uint64_t startTime = mach_absolute_time();
    [Student saveRecordsWithArray:stuArray];
    uint64_t endTime = mach_absolute_time();
    NSLog(@"插入完成 耗时:%lf",  MachTimeToSecs(endTime - startTime));
    
    NSArray * newStuArray = [Student queryAllRecords];
    NSLog(@"共有%ld条记录", newStuArray.count);
    
    NSArray * limitStuArray = [Student queryRecordsWithLimit:20 offset:1];
    NSLog(@"共有%ld条记录", limitStuArray.count);
    
    //批量删除
    NSLog(@"开始删除数据");
    startTime = mach_absolute_time();
    [Student deleteRecordsWithArray:stuArray];
    endTime = mach_absolute_time();
    NSLog(@"删除 耗时:%lf",  MachTimeToSecs(endTime - startTime));
    
    //////////
    
    //为表指定不同的数据库,需要在HSTable之类里面重写 +hs_databaseName 方法
    School * school = [[School alloc] init];
    school.shcoolId = 1;
    school.schoolName = @"南翔技校";
    [school saveToDB];

}

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /  (double)timebase.denom / 1e9;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
