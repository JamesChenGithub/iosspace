//
//  ViewController.m
//  testProxy
//
//  Created by AlexiChen on 2020/7/9.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>

#define kMsg1 100

#define kMsg2 101

@interface TRTCCloud : NSObject

+ (instancetype)sharedInstance;

+ (void)destroySharedIntance;

- (void)logTest;

@end


@interface TRTCCloudProxy : NSProxy
{
}
@property (nonatomic, strong) TRTCCloud *cloud;
- (instancetype)initWithInstance:(TRTCCloud *)cloud;
- (void)destroy;
@end

@implementation TRTCCloudProxy

+ (Class)class {
    return [TRTCCloud class];
}

- (instancetype)initWithInstance:(TRTCCloud *)cloud
{
    _cloud = cloud;
    return self;
}
- (void)destroy {
    NSLog(@"TRTCEngine:%p destroy", _cloud);
    self.cloud = nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [TRTCCloud instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (self.cloud) {
        [invocation invokeWithTarget:self.cloud];
    } else {
        NSLog(@"Calling method on destroyed TRTCCloud: %p, %s", self, [NSStringFromSelector(invocation.selector) UTF8String]);
    }
}



@end

@implementation TRTCCloud

static TRTCCloudProxy *sharedInstance = nil;
static pthread_mutex_t sharedInstanceLock;

+ (void)load {
    pthread_mutex_init(&sharedInstanceLock, NULL);
}

+ (instancetype)sharedInstance {
    if (sharedInstance == nil) {
        pthread_mutex_lock(&sharedInstanceLock);
        if (sharedInstance == nil) {
            TRTCCloud *cloud = [[TRTCCloud alloc] init];
            sharedInstance = [[TRTCCloudProxy alloc] initWithInstance:cloud];
            NSLog(@"sharedInstance<%p> is created", sharedInstance);
        }
        pthread_mutex_unlock(&sharedInstanceLock);
    }
    return (TRTCCloud*)sharedInstance;
}

+ (void)destroySharedIntance {
    pthread_mutex_lock(&sharedInstanceLock);
    if (sharedInstance) {
        [sharedInstance destroy];
        NSLog(@"sharedInstance<%p> is destroyed", sharedInstance);
        sharedInstance = nil;
    }
    pthread_mutex_unlock(&sharedInstanceLock);
}

- (void)dealloc
{
    NSLog(@"TRTCEngine:%p dealloc", self);
}

- (void)logTest{
    NSLog(@"logtest : %@", [NSDate date]);
}

@end


@interface Person : NSObject

@end






@interface XCWeakProxy : NSProxy

@property (nonatomic, assign) Class weakClass;
@property (nonatomic, weak) id weakRef;
- (instancetype)initWithRef:(NSObject *)instance;

@end

@implementation XCWeakProxy

- (void)dealloc
{
    NSLog(@"XCWeakProxy dealloc [%p]", self);
}

- (instancetype)initWithRef:(NSObject *)instance
{
    //NSAssert(instance != nil, @"instance is nil");
    NSLog(@"XCWeakProxy create [%p, %p, %@]", self, instance, instance.class);
    if (instance) {
        _weakRef = instance;
        _weakClass = instance.class;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (_weakRef) {
        return [_weakRef instanceMethodSignatureForSelector:sel];
    } else {
        if (_weakClass) {
            return [_weakClass instanceMethodSignatureForSelector:sel];
        } else {
            return [NSObject instanceMethodSignatureForSelector:sel];
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (_weakRef) {
        [invocation invokeWithTarget:_weakRef];
    } else {
        NSLog(@"weakRef of XCWeakProxy[%p, %p, %@] is released", self, _weakRef, _weakClass);
    }
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _weakRef;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_weakRef respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_weakRef isEqual:object];
}

- (NSUInteger)hash {
    return [_weakRef hash];
}

- (Class)superclass {
    return [_weakRef superclass];
}

- (Class)class {
    return [_weakRef class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_weakRef isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_weakRef isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_weakRef conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_weakRef description];
}

- (NSString *)debugDescription {
    return [_weakRef debugDescription];
}


@end



@interface  XCDelegateProxy : XCWeakProxy

@property (nonatomic, strong) NSMutableDictionary *selectorCache;

@end

@implementation XCDelegateProxy

- (instancetype)initWithDelegate:(id)observer {
    if (self = [super initWithRef:observer]) {
        self.selectorCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString *selStr = NSStringFromSelector(aSelector);
    NSNumber *num = [_selectorCache objectForKey:selStr];
    if (num) {
        return num.boolValue;
    } else {
        BOOL resp = [super respondsToSelector:aSelector];
        [_selectorCache setObject:@(resp) forKey:selStr];
        return resp;
    }
}



@end


@implementation Person

- (void)dealloc
{
    NSLog(@"Person dealloc : [%p]", self);
}

- (void)printLog {
     NSLog(@"Person logtest : %@", [NSDate date]);
}

- (void)launchThreadWithPort:(NSPort *)port {
    usleep(2 * USEC_PER_SEC);
    
    NSPort *localPort = [NSMachPort port];
    [port sendBeforeDate:[NSDate date] msgid:kMsg1 components:nil from:localPort reserved:0];
    
    usleep(2 * USEC_PER_SEC);
}
@end

@interface ViewController ()<NSMachPortDelegate>

@property (nonatomic, strong) TRTCCloud *shared;
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)handleMachMessage:(void *)message {
    int msg = *(int *) message;
    NSLog(@"接到子线程传递的消息！%d", msg);

}

- (void)viewDidLoad {
    NSPort *myPort = [NSMachPort port];
    myPort.delegate = self;
    [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];
    
    self.person = [[Person alloc] init];
    [NSThread detachNewThreadSelector:@selector(launchThreadWithPort:) toTarget:self.person withObject:myPort];
}



//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view.
//
////    self.shared = [TRTCCloud sharedInstance];
////
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////        [TRTCCloud destroySharedIntance];
////    });
////
////    dispatch_async(dispatch_get_global_queue(0, 0), ^{
////        for (int i = 0; i < 10; i++) {
////            [self.shared logTest];
////            usleep(500*1000);
////        }
////    });
//
//
//    self.person = [[Person alloc] init];
////    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:[[XCWeakProxy alloc] initWithRef:self.person] selector:@selector(printLog) userInfo:nil repeats:YES];
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////        self.person = nil;
////    });
//
//
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////        NSLog(@"self start: %@", [NSDate date]);
////        for (NSInteger i = 0; i < 1000000; i++) {
////            [self respondsToSelector:@selector(aaaaaa:)];
////        }
////        NSLog(@"self end: %@", [NSDate date]);
////    });
////
////
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////       XCDelegateProxy *xp = [[XCDelegateProxy alloc] initWithDelegate:self];
////        NSLog(@"self start: %@", [NSDate date]);
////        for (NSInteger i = 0; i < 1000000; i++) {
////            [xp respondsToSelector:@selector(aaaaaa:)];
////        }
////        NSLog(@"self end: %@", [NSDate date]);
////    });
//
//
//    NSMachPort *mainPort = [[NSMachPort alloc] init];
//    mainPort.delegate = self;
//    [[NSRunLoop currentRunLoop] addPort:mainPort forMode:NSDefaultRunLoopMode];
//
//    NSLog(@"%@", mainPort);
//
//    NSThread detachNewThreadSelector:@selector(<#selector#>) toTarget:<#(nonnull id)#> withObject:<#(nullable id)#>
//}



@end



