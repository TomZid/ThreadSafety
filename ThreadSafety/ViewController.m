//
//  ViewController.m
//  ThreadSafety
//
//  Created by tom.zid on 05/05/2017.
//  Copyright © 2017 Tom.zhu. All rights reserved.
//

#import "ViewController.h"

#   define IS_QUEUE             1
#   define IS_GCD               0
#   define IS_THREAD            0

#   define IS_SYNCHRONIZED     1
#   define IS_LOCK             0
#   define IS_SEMAPHORE        0

static int TICKETCOUNT = 30;

@interface ViewController ()
{
    __weak IBOutlet UILabel *_label;
}
@property (nonatomic, strong) NSMutableString *mutStr;
@property (nonatomic, assign)  NSInteger num;
@end

@implementation ViewController
- (NSMutableString *)mutStr {
    if (nil == _mutStr) {
        _mutStr = [NSMutableString new];
    }
    return _mutStr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self threadSell];
}

- (void)threadSell {
#if IS_GCD
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sellByThread:@"man1"];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sellByThread:@"man2"];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sellByThread:@"man3"];
    });
#elif IS_QUEUE
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.name = @"haha";
    queue.maxConcurrentOperationCount = 3;
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self sellByThread:@"man1"];
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        [self sellByThread:@"man2"];
    }];
    
    [queue addOperations:@[
                          op, op2
                          ] waitUntilFinished:NO];
#elif IS_THREAD
    [NSThread detachNewThreadWithBlock:^{
        [self sellByThread:@"man1"];
    }];
    
    [NSThread detachNewThreadWithBlock:^{
        [self sellByThread:@"man2"];
    }];
#endif
}

- (void)sellByThread:(NSString*)name {
    /**
     Each thread in a Cocoa application maintains its own stack of autorelease pool blocks. If you are writing a Foundation-only program or if you detach a thread, you need to create your own autorelease pool block.
     
     If your application or thread is long-lived and potentially generates a lot of autoreleased objects, you should use autorelease pool blocks (like AppKit and UIKit do on the main thread); otherwise, autoreleased objects accumulate and your memory footprint grows. If your detached thread does not make Cocoa calls, you do not need to use an autorelease pool block.
     
     
     https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmAutoreleasePools.html#//apple_ref/doc/uid/20000047-CJBFBEDI
     */
#if IS_SYNCHRONIZED
    @autoreleasepool {
        do {
            @synchronized (self) {
                //查询 买票 是一个原子操作
                if (TICKETCOUNT > 0) {
                    TICKETCOUNT -= 1;
                    
                    //模拟一些耗时操作
                    [NSThread sleepForTimeInterval:.2f];
                    
                    NSString *str = [NSString stringWithFormat:@"售票员:%@在卖票，还剩余:%i张票\n", name, TICKETCOUNT];
                    [self.mutStr appendString:str];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _label.text = self.mutStr;
                    });
                }
            }
        } while (TICKETCOUNT > 0);
    }
#elif IS_LOCK
    @autoreleasepool {
        do {
            static NSLock *lock;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                lock = [NSLock new];
            });
            [lock lock];
            if (TICKETCOUNT > 0) {
                TICKETCOUNT -= 1;
                
                [NSThread sleepForTimeInterval:.2f];
                
                NSString *str = [NSString stringWithFormat:@"售票员:%@在卖票，还剩余:%i张票\n", name, TICKETCOUNT];
                [self.mutStr appendString:str];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _label.text = self.mutStr;
                });
                [lock unlock];
            }
        }while (TICKETCOUNT > 0);
    }
#elif IS_SEMAPHORE
    @autoreleasepool {
        do {
            static dispatch_semaphore_t sema;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sema = dispatch_semaphore_create(1);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            if (TICKETCOUNT > 0) {
                TICKETCOUNT -= 1;
                
                [NSThread sleepForTimeInterval:.2f];
                
                NSString *str = [NSString stringWithFormat:@"售票员:%@在卖票，还剩余:%i张票\n", name, TICKETCOUNT];
                [self.mutStr appendString:str];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _label.text = self.mutStr;
                });
                dispatch_semaphore_signal(sema);
            }
        }while (TICKETCOUNT > 0);
    }
#endif
}

@end
