//
//  ViewController.m
//  Example
//
//  Created by jqoo on 2018/5/3.
//  Copyright © 2018年 jqoo. All rights reserved.
//

#import "ViewController.h"
#import <JQRequestKit/JQRequestKit.h>

@interface ViewController ()
{
    JQRequestFamily *_family;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _family = [[JQRequestFamily alloc] init];
    
    JQRequest *request = [JQRequest requestWithUrl:@"https://api.github.com/user" method:JQRequestMethod_GET];
    request.requestTracer = [JQRequestTracer tracerWithCompletionBlock:^(JQResponseResult *responseResult) {
        NSLog(@"");
    }];
    [request setValue:@"token 799e46e96e337702b5a852cb3d99bc7a7cb0fd3e" forHTTPHeaderField:@"Authorization"];
    [request startInFamily:_family];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
