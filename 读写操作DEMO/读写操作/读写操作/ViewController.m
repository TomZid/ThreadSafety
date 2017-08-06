//
//  ViewController.m
//  读写操作
//
//  Created by tom.zid on 06/08/2017.
//  Copyright © 2017 Tom.zhu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSInteger num;
    __weak IBOutlet UIView *_maskView;
    
    __weak IBOutlet UILabel *_readLabel;
    __weak IBOutlet UILabel *_readLabel2;
    __weak IBOutlet UILabel *_writeLabel;
}
@end

@implementation ViewController
- (void)progressShow {
    [UIView animateWithDuration:.75f
                          delay:0
         usingSpringWithDamping:.5f
          initialSpringVelocity:1
                        options:0
                     animations:^{
                         _maskView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, _maskView.frame.size.width, 0);
                     } completion:^(BOOL finished){
                         _readLabel.alpha = 1;
                         _readLabel2.alpha = 1;
                         _writeLabel.alpha = 1;
                     }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self test_set_get];
       [self progressShow];
    });
}

- (void)test_set_get {
    static int progress;
    
    void (^readBlock)() = ^(){
        NSLog(@"reading: current number is == %li \n", num);
        progress += 1;
    };
    void (^writeBlock)() = ^(){
        for (int i = 0; i++<99999;) {
            num++;
            [NSThread sleepForTimeInterval:.00000001f];
        }
        NSLog(@"writing……");
        progress += 1;
    };
    //new a concurrent queue
    dispatch_queue_t queue = dispatch_queue_create("com.tom.zid", DISPATCH_QUEUE_CONCURRENT);
    //append read operation to concurrent queue
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    //dispatch_barrier_async in place of dispatch_async
    dispatch_barrier_async(queue, writeBlock);
    
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
    dispatch_async(queue, readBlock);
}

@end
