#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import "AppAuthMacOSAuthorization.h"
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import "AppAuthIOSAuthorization.h"
#import <Flutter/Flutter.h>
#endif

#import <AppAuth/AppAuth.h>

@interface FlutterAppauthPlugin : NSObject <FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession>
    currentAuthorizationFlow;

#if TARGET_OS_OSX
/// 由宿主在 `application:openURLs:` 中调用。Microsoft 等指标体系的 `code` 极长，
/// 若仅通过 NSAppleEventDescriptor 字符串传递，`stringValue` 可能被截断导致无法 resume。
- (void)deliverOAuthRedirectURL:(NSURL *_Nonnull)url;
#endif

@end
