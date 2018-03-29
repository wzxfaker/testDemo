//
//  ViewController.m
//  testDemo
//
//  Created by admin on 2018/3/22.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "ViewController.h"
#import "XNotiViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_queue_t queue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{//此处换成异步派发，queue换成串行队列也会造成死锁，死锁的原因：想当前串行队列执行的任务所在的线程同步向该队列派发任务就会造成死锁
        dispatch_sync(queue, ^{
            NSLog(@"你会死锁吗？");
        });
    });
    
    //task1
    dispatch_queue_t my_queue1 = dispatch_queue_create("myqueue1", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 3; i++) {
//        sleep(1);
        dispatch_async(my_queue1, ^{
            NSLog(@"task1--%d--%@",i,[NSThread currentThread]);
        });
    }
    NSLog(@"task1--%@",[NSThread currentThread]);//如果循环次数过多的话，先异步添加到队列中的任务会先于task1执行，可以改为100测试一下
    
    
    //task2
    //在两个不同的线程向同一个并发队列同步派发任务才能体现出并发性
    dispatch_queue_t my_queue2 = dispatch_queue_create("my_queue2", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_sync(my_queue2, ^{
            sleep(2);
            NSLog(@"1--%@",[NSThread currentThread]);
        });
    });
    sleep(0.5);
    dispatch_sync(my_queue2, ^{
        dispatch_async(my_queue2, ^{
            NSLog(@"2--%@",[NSThread currentThread]);
        });
        sleep(1);
        NSLog(@"3--%@",[NSThread currentThread]);
    });
    NSLog(@"4--%@",[NSThread currentThread]);
    
    
    //信号量控制最大并发数
    //信号量的具体做法：一个线程进入一段关键代码之前，必须获取一个信号量，一旦该关键代码段完成了，那么该线程必须释放信号量。其他想进入该关键代码段的线程必须等待前面的线程释放信号量。当信号计数大于0时，每条进来的线程使计数减1，直到变为0.变为0后其他线程进不来，处于等待状态；执行完任务的线程释放信号，使计数加1，如此循环下去
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    dispatch_queue_t seQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 30; i++) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(seQueue, ^{
            NSLog(@"🏀--%d",i);
            sleep(2);
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    //可以利用信号量控制同步问题
    NSMutableArray *testArr = [NSMutableArray array];
    dispatch_semaphore_t testSemaphore = dispatch_semaphore_create(1);
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(testSemaphore, DISPATCH_TIME_FOREVER);
            [testArr addObject:@(i)];
            dispatch_semaphore_signal(testSemaphore);
        });
    }
    NSLog(@"循环结束了--%lu",(unsigned long)testArr.count);
    
    //通知与多线程的关系：通知只能在发送通知的线程中进行传递，如果希望跨线程处理通知消息，需要利用“重定向”进行处理
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"asyncNotificationName" object:nil];
        NSLog(@"noti--%@",[NSThread currentThread]);
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNoti:) name:@"asyncNotificationName" object:nil];
}

- (void)handleNoti:(NSNotification *)noti{
    NSLog(@"监听到了通知--%@",[NSThread currentThread]);
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    XNotiViewController *notiVC = [[XNotiViewController alloc] init];
    [self presentViewController:notiVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
