//
//  XCommon.h
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#ifndef XCommon_h
#define XCommon_h


#if DEBUG
#define DebugLog(fmt, ...) NSLog((@"[当前线程 : %p, 主线程 : %p][%s, %d] : " fmt), [NSThread currentThread], [NSThread mainThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DebugLog(fmt, ...) // NSLog((@"web_apilog : [%p] %s Line %d : " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

#define WEAKIFY(x) __weak __typeof(x) weak_##x = x
#define STRONGIFY(x) __strong __typeof(weak_##x) x = weak_##x
#define STRONGIFY_OR_RETURN(x) __strong __typeof(weak_##x) x = weak_##x; if (x == nil) {return;};


#if defined(WIN32)
#define __FILENAME__ (strrchr(__FILE__, '\\') + 1)
#else
#define __FILENAME__ (strrchr(__FILE__, '/') + 1)
#endif


#if DEBUG
#define DebugLog(fmt, ...) NSLog((@"[当前线程 : %p, 主线程 : %p][%s, %d] : " fmt), [NSThread currentThread], [NSThread mainThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DebugLog(fmt, ...) // NSLog((@"web_apilog : [%p] %s Line %d : " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

#define WEAKIFY(x) __weak __typeof(x) weak_##x = x
#define STRONGIFY(x) __strong __typeof(weak_##x) x = weak_##x
#define STRONGIFY_OR_RETURN(x) __strong __typeof(weak_##x) x = weak_##x; if (x == nil) {return;};


#if defined(WIN32)
#define __FILENAME__ (strrchr(__FILE__, '\\') + 1)
#else
#define __FILENAME__ (strrchr(__FILE__, '/') + 1)
#endif

#define XTAsyncRunInMain(block, ...) \
if(block){ \
if([NSThread isMainThread]){ \
block(__VA_ARGS__); \
} \
else{ \
dispatch_async(dispatch_get_main_queue(), ^{ \
block(__VA_ARGS__); \
}); \
} \
}

#define XTSyncRunInMain(block, ...) \
if(block){ \
if([NSThread isMainThread]){ \
block(__VA_ARGS__); \
} \
else{ \
dispatch_sync(dispatch_get_main_queue(), ^{ \
block(__VA_ARGS__); \
}); \
} \
}



#define PROXY_DECLARAION(clss) \
@interface clss##Proxy : NSProxy{ \
    clss *_proxyInstance;\
}\
@property (nonatomic, retain) clss *proxyInstance;\
\
- (instancetype)initWith:(clss *)obj;\
\
- (void)destroy;\
\
@end



#define PROXY_IMPLEMENT(clss) @implementation clss##Proxy \
\
+ (Class)class {\
    return [clss class];\
}\
\
- (instancetype)initWith:(clss *)proxyInstance {\
    _proxyInstance = proxyInstance;\
    return self;\
}\
\
- (void)destroy {\
    DebugLog(@"%@:%p destroy", [self class],_proxyInstance);\
    [_proxyInstance destoryClean];\
    _proxyInstance = nil;\
}\
\
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {\
    return [clss instanceMethodSignatureForSelector:sel];\
}\
\
- (void)forwardInvocation:(NSInvocation *)invocation {\
    if (_proxyInstance) {\
        [invocation invokeWithTarget:_proxyInstance];\
    } else {\
        DebugLog(@"Calling method on destroyed %s: %p, %@", #clss, self, NSStringFromSelector(invocation.selector));\
    }\
}\
\
@end

#define PROXY_Singleton_DECLARAION(clss) \
+ (instancetype)sharedInstance;\
+ (void)destorySharedInstance;\


#define PROXY_Singleton_IMPLEMENT(clss) \
static clss##Proxy *shared##clss##Instance = nil; \
static pthread_mutex_t shared##clss##Instance##Metux; \
+ (void)load { \
    pthread_mutex_init(&shared##clss##Instance##Metux, NULL); \
}\
+ (instancetype)sharedInstance {\
    if (shared##clss##Instance == nil) {\
        pthread_mutex_lock(&shared##clss##Instance##Metux);\
        if (shared##clss##Instance == nil) {\
            clss *shared = [[clss alloc] init]; \
            shared##clss##Instance = [[clss##Proxy alloc] initWith:shared]; \
            DebugLog(@"sharedInstance<%p> is created : %p", shared##clss##Instance, shared); \
        }\
        pthread_mutex_unlock(&shared##clss##Instance##Metux);\
    }\
    return (clss##Proxy *)shared##clss##Instance;\
}\
+ (void)destorySharedInstance { \
    pthread_mutex_lock(&shared##clss##Instance##Metux); \
       if (shared##clss##Instance) { \
           [shared##clss##Instance destroy]; \
           DebugLog(@"sharedInstance<%p> is destroyed", shared##clss##Instance); \
           shared##clss##Instance = nil; \
       }\
    pthread_mutex_unlock(&shared##clss##Instance##Metux); \
}


#endif /* XCommon_h */
