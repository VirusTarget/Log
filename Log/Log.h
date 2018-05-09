//
//  Log.h
//  Log
//
//  Created by 陈晋添 on 2018/5/8.
//  Copyright © 2018年 cjt. All rights reserved.
//

#import <UIKit/UIKit.h>

#if defined(__cplusplus)
extern "C" {
#endif
    void NDSimulatorLog(NSString *logStr,char* fileName, int lineNum);
#if defined(__cplusplus)
}
#endif

@interface NDLogger : NSObject

+ (BOOL)setBasicLogPath:(NSString *)path;
+ (void)log:(NSString *)str file:(char *)fileName linnum:(int)lineNum;
+ (void)setLogEnabled:(BOOL)enable;
@end

#define setNDLOGPath(path)    [NDLogger setBasicLogPath:path];
#if TARGET_IPHONE_SIMULATOR
#define NDLOG(...)  NDSimulatorLog([NSString stringWithFormat:__VA_ARGS__], __FILE__, __LINE__)
#else
#define NDLOG(...)   [NDLogger log:[NSString stringWithFormat:__VA_ARGS__] file:__FILE__ linnum:__LINE__]
#endif
#define setNDLOGEnable(enable) [NDLogger setLogEnabled:enable]

