//
//  OKWebViewController.m
//  SAML Sample
//
//  Created by Tom Belote on 3/6/14.
//  Copyright (c) 2014 Okta, Inc. All rights reserved.
//

/*
 * SAML related comments are in the "block style" comments (this is a block style comment).
 *
 * See the STEP 1, STEP 1.1, STEP 2, STEP 3, and STEP 4 comments below to understand 
 * how to implement a SAML flow in an embedded webView.
 */

#import "OKWebViewController.h"

/*
 * Replace all instances of the string "EXAMPLE" below with the approprate values for your setup.
 */
#define SAML_URL_STRING @"https://EXAMPLE.okta.com/app/salesforce/EXAMPLE/sso/saml"
#define SALESFORCE_BASE_URL @"https://EXAMPLE.salesforce.com/"
#define LOGIN_SUCCESS_URL_STRING @"https://EXAMPLE.salesforce.com/home/home.jsp"
#define SALESFORCE_OAUTH_AUTHORIZE @"https://login.salesforce.com/services/oauth2/authorize?response_type=code&client_id=EXAMPLE&redirect_uri=https://EXAMPLE.okta.com/salesforce/oauth&state=mystate"
/*
 * NEVER include a client secret in an iPhone app.
 * Instead, use a proxy or OAuth service that doesn't require this.
 */
#define SALESFORCE_OAUTH @"https://EXAMPLE.salesforce.com/services/oauth2/token?client_id=EXAMPLE&grant_type=authorization_code&redirect_uri=https://EXAMPLE.okta.com/salesforce/oauth&client_secret=EXAMPLE"

#define OAUTH_CALLBACK @"https://EXAMPLE.okta.com/salesforce/oauth"

#define OKTA_DEMO_LOGIN_URL @"https://EXAMPLE.okta.com/login"

@interface OKWebViewController () <UIWebViewDelegate, UIAlertViewDelegate>

@end

@implementation OKWebViewController {
    BOOL done;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        done = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[self.view bounds]];
    /*
     * This needs to be a webView delegate so we know when sign-in is complete.
     */
    webView.delegate = self;

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:webView];
    
    id topGuide = self.topLayoutGuide;
    id bottomGuide = self.bottomLayoutGuide;
    NSDictionary *topViewsDictionary = NSDictionaryOfVariableBindings(webView, topGuide);
    NSDictionary *bottomViewsDictionary = NSDictionaryOfVariableBindings(webView, bottomGuide);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[webView]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:topViewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[webView]-0-[bottomGuide]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:bottomViewsDictionary]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    

    [self.view layoutSubviews];
    
    /*
     * STEP 1:
     
     * Load the Okta "chicklet" link in the webView. 
     * This will redirect to a login screen and is the start of the SAML flow.
     */
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:SAML_URL_STRING]]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*)oauthCodeFromURL:(NSString*) urlString
{
    NSArray *pieces = [urlString componentsSeparatedByString:@"="];
    return [pieces objectAtIndex:1];
}


#pragma mark WebViewDelegate


-(void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"Loaded %@", [webView.request.URL absoluteString]);
    if (!webView.isLoading) {
        /*
         * STEP 1.1:
         *
         * For the purposes of this demonstration, we will fill in credentials automatically.
         *
         * DO NOT DO THIS IN A REAL APP.
         *
         */
        if ([[webView.request.URL absoluteString] hasPrefix:OKTA_DEMO_LOGIN_URL]) {
            /*
             * This is just for the purposes of this demonstration, so you know how to login.
             * Normally the user would type in their username and password or use Okta Mobile Connect to SSO in.
             */
            [webView stringByEvaluatingJavaScriptFromString:@"$('#user-signin').val('demo@example.com');$('#pass-signin').val('ExamplePassword');"];
        } else if ([[webView.request.URL absoluteString] isEqualToString:LOGIN_SUCCESS_URL_STRING]) {
            /*
             * STEP 2:
             *
             * Now that we are signed in to Salesforce, start the OAuth flow so we can get a long lived token, 
             * this way the user won't have to constantly re-enter their password.
             *
            //But you could skip the later steps and just use the salesforce session cookies, it is now in the shared cookie jar
            //here it is logged
             */
            NSLog(@"logged in to salesforce with session cookies %@", [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:SALESFORCE_BASE_URL]]);
            
            NSMutableURLRequest *oauthRequest =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:SALESFORCE_OAUTH_AUTHORIZE]];
            [oauthRequest setHTTPMethod:@"POST"];
            [webView loadRequest:oauthRequest];
        }
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([[webView.request.URL absoluteString] hasPrefix:OAUTH_CALLBACK] || [error code] == -999) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error loading webpage"
                                                    message:[NSString stringWithFormat:@"%@ %@",[webView.request.URL absoluteString],[error localizedDescription]]
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


-(BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] hasPrefix:OAUTH_CALLBACK]) {
        /*
         * STEP 3:
         *
         * We got the callback from OAuth, now we can use the "code" from the callback URL to request our token.
         */
        NSLog(@"Got callback %@", [request.URL absoluteString]);
        /*
         * This means we are done.
         */
        if (done == NO) {
            NSString *code = [self oauthCodeFromURL:[request.URL absoluteString]];
            NSMutableURLRequest *oauthTokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SALESFORCE_OAUTH]];
            [oauthTokenRequest setHTTPMethod:@"POST"];
            [oauthTokenRequest setHTTPBody:[[NSString stringWithFormat:@"code=%@",code] dataUsingEncoding:NSUTF8StringEncoding]];
            done = YES;
            [NSURLConnection sendAsynchronousRequest:oauthTokenRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                /*
                 * STEP 4:
                 *
                 * We are done. At this point you should parse the token out of the JSON and 
                 * save it somewhere secure like Apple's Keychain.
                 */
                NSString *message = [NSString stringWithFormat:@"we got a persistent oauth token\n%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                UIAlertView *doneAlert = [[UIAlertView alloc] initWithTitle:@"Signed in!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                doneAlert.delegate = self;
                [doneAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            }];
        }
        return NO;
    }
    return YES;
}


#pragma  mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    /*
     * After user taps "OK", start the process over so we can demonstrate it again.
     */
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
