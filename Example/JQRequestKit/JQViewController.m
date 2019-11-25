//
//  JQViewController.m
//  JQRequestKit
//
//  Created by MDoEEPgAAAAAAAAAAAAAAAAAAAEwFAYIKoZIhvcNAwcECPVhY6001vdcBBA0CNPkkJoG3K+DKSynV74R on 11/25/2019.
//  Copyright (c) 2019 MDoEEPgAAAAAAAAAAAAAAAAAAAEwFAYIKoZIhvcNAwcECPVhY6001vdcBBA0CNPkkJoG3K+DKSynV74R. All rights reserved.
//

#import "JQViewController.h"
#import <JQRequestKit/JQRequestKit.h>

@interface JQViewController ()
{
    JQRequestFamily *_family;
}

@end

@implementation JQViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _family = [[JQRequestFamily alloc] init];
    
    JQRequest *request = [JQRequest requestWithUrl:@"https://api.github.com/user" method:JQRequestMethod_GET];
    request.requestTracer = [JQRequestTracer tracerWithCompletionBlock:^(JQResponseResult *responseResult) {
        NSLog(@"");
    }];
    [request setValue:@"token 3d75522e13e95acd238d5e5c825dc9ad1726c467" forHTTPHeaderField:@"Authorization"];
    [request startInFamily:_family];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
