//
//  Log.m
//  Log
//
//  Created by 陈晋添 on 2018/5/8.
//  Copyright © 2018年 cjt. All rights reserved.
//

#import "Log.h"
#import <sys/time.h>
#include <unistd.h>

#import <fcntl.h>

//日志文件目录
#define DEFAULT_LOG_DIR @"NDLOG"

static NDLogger *g_logger = NULL;
static BOOL g_enableLog = NO;
static NSDateFormatter *g_formatter = nil;

@interface NDLogger()
@property (nonatomic, copy) NSString *basicLogPath;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@end

@implementation NDLogger
+ (void)initialize {
    if (g_logger == nil)
    {
        g_logger = [[NDLogger alloc] init];
        [self setLogEnabled:NO];
    }
    
    if (g_formatter == nil) {
        g_formatter = [[NSDateFormatter alloc] init];
        [g_formatter setDateFormat:@"yyyyMMdd"];
    }
}

+ (NDLogger*)shared {
    return g_logger;
}

+ (BOOL)isEnableLog {
    return g_enableLog;
}

+ (void)setLogEnabled:(BOOL)enable {
    g_enableLog = enable;
}

+ (BOOL)setBasicLogPath:(NSString *)path {
    return [[NDLogger shared] setLoggerBasicLogPath:path];
}

+ (void)log:(NSString *)str file:(char *)fileName linnum:(int)lineNum {
    if ([self isEnableLog] == NO)
        return;
    
    NSString *shortFileName = [[NSString stringWithFormat:@"%s", fileName] lastPathComponent];
    if (shortFileName == nil)
        shortFileName = @"";
    
    if ([[NDLogger shared] fileHandle] == nil)
    {
        [[NDLogger shared] openFile];
    }
    
    [[NDLogger shared] writeLog:[NSString stringWithFormat:@"%@#%d[%@]:%@\n", shortFileName, lineNum, currentTimeString(), str]];
}

- (id)init {
    if (self = [super init])
    {
        _fileHandle = nil;
        [self openFile];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _basicLogPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:DEFAULT_LOG_DIR];
        
    }
    return self;
}

- (BOOL)setLoggerBasicLogPath:(NSString *)path {
    if (path == NO)
        return NO;
    
    if (access([path UTF8String], R_OK | W_OK) != 0)
        return NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _basicLogPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:path];
    return YES;
}

- (void)deleteOldFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator<NSString *> *myDirectoryEnumerator = [fileManager enumeratorAtPath:_basicLogPath];
    
    NSString *strPath;
    
    // 删除5天以上的日志
    while (strPath = [myDirectoryEnumerator nextObject]) {
        for (NSString * namePath in strPath.pathComponents) {
            NSDate *date = [g_formatter dateFromString:namePath];
            if ([date timeIntervalSinceNow] < -3600*24*5) {
                NSError *error = nil;
                [fileManager removeItemAtPath:[_basicLogPath stringByAppendingPathComponent:namePath] error:&error];
                if (error) {
                    NSLog(@"%@",error);
                }
            }
        }
    }
}

- (void)openFile {
    NSString *dateString = [g_formatter stringFromDate:[NSDate date]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:_basicLogPath]) {
        [fileManager createDirectoryAtPath:_basicLogPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *strPath = [_basicLogPath stringByAppendingPathComponent:dateString];
    bool flag = true;
    if (![fileManager fileExistsAtPath:strPath isDirectory:&flag]) {
        flag = false;
        [fileManager createFileAtPath:strPath contents:nil attributes:nil];
    }
    
    if (!flag) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:strPath];
        [self writeLog:startMessage()];
    }
}

- (void)writeLog:(NSString *)log {
    if (_fileHandle == nil)
        return;
    
    [_fileHandle seekToEndOfFile];
    [_fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [_fileHandle synchronizeFile];
}

- (NSDateFormatter *)timeFormatter {
    if (!_timeFormatter) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setDateFormat:@"yyyyMMdd"];
    }
    return _timeFormatter;
}
#pragma mark - C
NSString *startMessage() {
    NSString *start=[NSString stringWithFormat:
                     @"**********************Start************************\n"
                     "----------------------------------------------------\n"
                     "NOW:%@\n"
                     "----------------------------------------------------\n"
                     ,[NSDate date]];
    return start;
}

NSString *currentTimeString() {
    struct timeval cur_timeval;
    struct timezone cur_timezone;
    gettimeofday(&cur_timeval, &cur_timezone);
    struct tm cur_tm;
    localtime_r(&(cur_timeval.tv_sec), &cur_tm);
    NSString *curTime = [NSString stringWithFormat:@"%02d-%02d %02d:%02d:%02d.%03d", cur_tm.tm_mon, cur_tm.tm_mday,cur_tm.tm_hour, cur_tm.tm_min, cur_tm.tm_sec, cur_timeval.tv_usec/1000];
    return curTime;
}
@end

void NDSimulatorLog(NSString *logStr,char* fileName, int lineNum){
    if ([NDLogger isEnableLog] == NO)
        return;
    
    NSString *shortFileName = [[NSString stringWithFormat:@"%s", fileName] lastPathComponent];
    if (shortFileName == nil)
        shortFileName = @"";
    
    NSString *fullstr = [NSString stringWithFormat:@"%@#%d[%@]:%@\n", shortFileName, lineNum, currentTimeString(), logStr];
    printf("%s", [fullstr UTF8String]);
}
