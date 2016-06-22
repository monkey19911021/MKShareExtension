//
//  ViewController.m
//  MKShareExtension
//
//  Created by DONLINKS on 16/6/21.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)share:(id)sender {
    
    NSString *shareStr = @"分享mkapple";
    NSString *shareStr2 = @"----------";
    
    NSURL *shareUrl = [NSURL URLWithString:@"http://mkapple.cn"];
    NSURL *shareUrl2 = [NSURL URLWithString:@"http://www.baidu.com"];
    
    UIImage *shareImg = [UIImage imageNamed: @"MKImg"];
    UIImage *shareImg2 = [UIImage imageNamed: @"btn_delete"];
    
    UIActivityViewController *ctrl = [[UIActivityViewController alloc] initWithActivityItems:@[shareStr, shareStr2, shareUrl, shareUrl2, shareImg, shareImg2] applicationActivities:nil];
    ctrl.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
        if(!completed){
            
            UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"分享失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [ctrl addAction: [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:ctrl animated:YES completion:nil];
            
        }
    };
    [self presentViewController:ctrl animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
