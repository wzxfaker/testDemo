//
//  XNotiViewController.m
//  testDemo
//
//  Created by admin on 2018/3/29.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "XNotiViewController.h"

#define kNotificationCenter [NSNotificationCenter defaultCenter]

@interface XNotiViewController ()<NSMachPortDelegate>

/** 通知队列 */
@property (nonatomic, strong) NSMutableArray *notifications;
/** 期望线程 */
@property (nonatomic, strong) NSThread *notificationThread;
/** 用于向通知队列加锁的锁对象，避免线程冲突 */
@property (nonatomic, strong) NSLock *notificationLock;
/** 用于向期望线程发送信号的端口 */
@property (nonatomic, strong) NSMachPort *notificationPort;

@end

@implementation XNotiViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    // Do any additional setup after loading the view.
    self.notifications = [NSMutableArray array];
    self.notificationThread = [NSThread currentThread];
    self.notificationLock = [[NSLock alloc] init];
    self.notificationPort = [[NSMachPort alloc] init];
    self.notificationPort.delegate = self;
    //向当前线程的runloop添加端口源，当mach消息到达而接收线程的runloop没有启动时，则内核会保存这条消息，直到下一次进入runloop
    [[NSRunLoop currentRunLoop] addPort:self.notificationPort forMode:NSRunLoopCommonModes];
    [kNotificationCenter addObserver:self selector:@selector(handleNoti:) name:@"testNotification" object:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [kNotificationCenter postNotificationName:@"testNotification" object:nil userInfo:nil];
    });
//    NSNotificationQueue
}

- (void)handleNoti:(NSNotification *)noti{
    NSLog(@"接受通知的线程--%@",[NSThread currentThread]);
    if ([NSThread currentThread] != _notificationThread) {
        //重定向
        [self.notificationLock lock];
        [self.notifications addObject:noti];
        [self.notificationLock unlock];
        [self.notificationPort sendBeforeDate:[NSDate date] components:nil from:nil reserved:0];
    }else{
        NSLog(@"处理通知事件，当前线程--%@",[NSThread currentThread]);
    }
}

- (void)handleMachMessage:(void *)msg{
    [self.notificationLock lock];
    while (self.notifications.count) {
        NSNotification *noti = [self.notifications objectAtIndex:0];
        [self.notifications removeObjectAtIndex:0];
        [self.notificationLock unlock];
        [self handleNoti:noti];
        [self.notificationLock lock];
    }
    [self.notificationLock unlock];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
