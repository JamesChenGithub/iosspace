//
//  ViewController.m
//  iostest
//
//  Created by AlexiChen on 2020/7/9.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"


@interface MenuItem : NSObject

@property (nonatomic, copy) NSString *titleName;
@property (nonatomic, copy) NSString *className;

@end

@implementation MenuItem

- (instancetype)initWith:(NSString *)title vcName:(NSString *)name{
    if (self = [super init]) {
        self.titleName = title;
        self.className = name;
    }
    return self;
}

@end

@interface ViewController ()

@property (nonatomic, strong) NSMutableDictionary *sectionMap;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.sectionMap = [NSMutableDictionary dictionary];
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"Category" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Load" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"initialize" vcName:nil]];
        
        [self.sectionMap setValue:array forKey:@"NSObject"];
    }
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"Source" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Timer" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"NSMachPort" vcName:nil]];
        
        [self.sectionMap setValue:array forKey:@"Runloop"];
    }
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"NSMachPort" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Runloop" vcName:nil]];
        
        [self.sectionMap setValue:array forKey:@"NSThread"];
    }
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"NSMachPort" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Source" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Timer" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"卡顿监听" vcName:nil]];
        
        
        [self.sectionMap setValue:array forKey:@"NSRunLoop"];
    }
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"SearlizeQueue" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"ConcurentQueue" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Group" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Apply" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Semphore" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"TLS" vcName:nil]];
        
        
        [self.sectionMap setValue:array forKey:@"GCD"];
    }
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"NSOperation" vcName:nil]];
        
        
        [self.sectionMap setValue:array forKey:@"NSOperationQueue"];
    }
    
    {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:[[MenuItem alloc] initWith:@"消息发送" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"消息转发" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"KVO" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"KVC" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Hook" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"MethodSwizzle" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Protocl Cache" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Associate property" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Strong" vcName:nil]];
        [array addObject:[[MenuItem alloc] initWith:@"Weak" vcName:nil]];
        
        [self.sectionMap setValue:array forKey:@"Runtime"];
    }
    
    //    ￼NSObject事件转发
    //    ￼NSRunLoop
    //    ￼NSThread
    //    4. NSOperationQueue / NSOperation
    //    GCD
    //    block
    //    Hook
    //    runtime
    //    touchevent传递
    //    hitTest
    //    NSProxy
    //    NSMachPort
    //    associate property
    //    CALayer
    //    UIAnimation
    //    iOS各版本新增特性
    //    离屏渲染
    //    instrument
    //    drawRect
    //    cache
    //    NSPort
    
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionMap.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *keys = self.sectionMap.allKeys;
    NSArray *kvs = self.sectionMap[keys[section]];
    return kvs.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSArray *keys = self.sectionMap.allKeys;
    return keys[section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TestCell"];
    }
    NSArray *keys = self.sectionMap.allKeys;
    NSArray *kvs = self.sectionMap[keys[indexPath.section]];
    MenuItem *item = kvs[indexPath.row];
    cell.textLabel.text = item.titleName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *keys = self.sectionMap.allKeys;
    NSArray *kvs = self.sectionMap[keys[indexPath.section]];
    MenuItem *item = kvs[indexPath.row];
    NSString *clsName = item.className;
    
    if (clsName.length == 0) {
        clsName = @"UIViewController";
    }
    
    Class cls = NSClassFromString(clsName);
    UIViewController *control = [[cls alloc] init];
    [self.navigationController pushViewController:control animated:YES];
    
}

@end
