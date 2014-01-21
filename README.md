The Okta Connect SDK for iOS is a framework that you can link to your iOS application to enable SSO with the Okta Mobile app. This SDK requires that the mobile beta flag be set for your organization, and your app configured in the admin interface for your org. See the PowerPoint presentation in this repository for more information.


# Dependencies :
Security.framework library

Usage:

# Initiating SSO Call:

    OktaSSO *ssoEngine = [OktaSSO sharedInstance];
    BOOL response = [ssoEngine sendRequestForApp:@"<YourAppName>"
    forTokenType:OKTokenTypeOAUTH2]; // OAUTH2 is the only supported token
    type. COOKIES support coming soon.


# Handing SSO Response:

    -(BOOL)application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
    annotation:(id)annotation {
        OktaSSO *ssoEngine = [OktaSSO sharedInstance];
        BOOL isOktaResponse = [ssoEngine isOktaSSOResponse:url];

        if(isOktaResponse) {
            OKSSOResponse *response = [ssoEngine handleSSOResponse:url];

            // Use response to setup your session. Alert message shown for
    illustration.

           NSString *responseType = [response isError]?@"Error":@"Success";
           UIAlertView *view = [[UIAlertView alloc]
    initWithTitle:responseType message:[response responseAsString]
    delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
           [view show];
           return YES;
        }
        return YES;
    }


OKSSOResponse.h // supports two accessor methods.

    -(OKOAuth2Response*) responseAsOAuth2; // call if response type is "Success"
    -(NSString *) responseAsString; // returns JSON response string. Can
    be called for both "Success" and "Error" responseType

