//
//  OKViewController.m
//  SAML Sample
//
//  Created by Tom Belote on 3/6/14.
//  Copyright (c) 2014 Okta, Inc. All rights reserved.
//

#import "OKViewController.h"

#import "OKWebViewController.h"

@interface OKViewController ()

@end

@implementation OKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.signInButton addTarget:self action:@selector(showWebView) forControlEvents:UIControlEventTouchUpInside];
}

- (void) showWebView
{
    OKWebViewController *webViewController = [[OKWebViewController alloc] init];
    [self presentViewController:webViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
