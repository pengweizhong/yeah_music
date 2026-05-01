#import "AppAuthMacOSAuthorization.h"
#import <Cocoa/Cocoa.h>

/// 供登出等对「会话内 WebView」无强依赖的流程使用。
static NSWindow *yeahMusicFlutterPresentingWindowForOAuth(void) {
  NSApplication *app = [NSApplication sharedApplication];
  NSWindow *w = app.keyWindow;
  if (w != nil) {
    return w;
  }
  w = app.mainWindow;
  if (w != nil) {
    return w;
  }
  for (NSWindow *candidate in app.windows) {
    if (!candidate.isVisible) {
      continue;
    }
    if ((candidate.styleMask & NSWindowStyleMaskBorderless) != 0) {
      continue;
    }
    return candidate;
  }
  return nil;
}

@implementation AppAuthMacOSAuthorization

- (id<OIDExternalUserAgentSession>)
    performAuthorization:(OIDServiceConfiguration *)serviceConfiguration
                clientId:(NSString *)clientId
            clientSecret:(NSString *)clientSecret
                  scopes:(NSArray *)scopes
             redirectUrl:(NSString *)redirectUrl
    additionalParameters:(NSDictionary *)additionalParameters
       externalUserAgent:(NSNumber *)externalUserAgent
                  result:(FlutterResult)result
            exchangeCode:(BOOL)exchangeCode
                   nonce:(NSString *)nonce {
  NSString *codeVerifier = [OIDAuthorizationRequest generateCodeVerifier];
  NSString *codeChallenge =
      [OIDAuthorizationRequest codeChallengeS256ForVerifier:codeVerifier];

  OIDAuthorizationRequest *request = [[OIDAuthorizationRequest alloc]
      initWithConfiguration:serviceConfiguration
                   clientId:clientId
               clientSecret:clientSecret
                      scope:[OIDScopeUtilities scopesWithArray:scopes]
                redirectURL:[NSURL URLWithString:redirectUrl]
               responseType:OIDResponseTypeCode
                      state:[OIDAuthorizationRequest generateState]
                      nonce:nonce != nil
                                ? nonce
                                : [OIDAuthorizationRequest generateState]
               codeVerifier:codeVerifier
              codeChallenge:codeChallenge
        codeChallengeMethod:OIDOAuthorizationRequestCodeChallengeMethodS256
       additionalParameters:additionalParameters];
  // authorize 固定在系统默认浏览器打开：Flutter 宿主内 ASWebAuthenticationSession 常见「start 成功但永不 completion」，
  // 导致 Dart authorizeAndExchangeCode 永久挂起。回调仍由自定义 scheme + AppDelegate 交给 AppAuth resume。
  NSWindow *authorizePresentingWindow = nil;
  if (exchangeCode) {
    NSObject<OIDExternalUserAgent> *agent =
        [self userAgentWithPresentingWindow:authorizePresentingWindow
                          externalUserAgent:externalUserAgent];
    return [OIDAuthState
        authStateByPresentingAuthorizationRequest:request
                                externalUserAgent:agent
                                         callback:^(
                                             OIDAuthState *_Nullable authState,
                                             NSError *_Nullable error) {
                                           if (authState) {
                                             result([FlutterAppAuth
                                                 processResponses:
                                                     authState.lastTokenResponse
                                                     authResponse:
                                                         authState
                                                             .lastAuthorizationResponse]);

                                           } else {
                                             [FlutterAppAuth
                                                 finishWithError:
                                                     AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE
                                                         message:
                                                             [FlutterAppAuth
                                                                 formatMessageWithError:
                                                                     AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                                                  error:
                                                                                      error]
                                                          result:result
                                                           error:error];
                                           }
                                         }];
  } else {
    NSObject<OIDExternalUserAgent> *agent =
        [self userAgentWithPresentingWindow:authorizePresentingWindow
                          externalUserAgent:externalUserAgent];
    return [OIDAuthorizationService
        presentAuthorizationRequest:request
                  externalUserAgent:agent
                           callback:^(OIDAuthorizationResponse
                                          *_Nullable authorizationResponse,
                                      NSError *_Nullable error) {
                             if (authorizationResponse) {
                               NSMutableDictionary *processedResponse =
                                   [[NSMutableDictionary alloc] init];
                               [processedResponse
                                   setObject:authorizationResponse
                                                 .additionalParameters
                                      forKey:
                                          @"authorizationAdditionalParameters"];
                               [processedResponse
                                   setObject:authorizationResponse
                                                 .authorizationCode
                                      forKey:@"authorizationCode"];
                               [processedResponse
                                   setObject:authorizationResponse.request
                                                 .codeVerifier
                                      forKey:@"codeVerifier"];
                               [processedResponse
                                   setObject:authorizationResponse.request.nonce
                                      forKey:@"nonce"];
                               result(processedResponse);
                             } else {
                               [FlutterAppAuth
                                   finishWithError:AUTHORIZE_ERROR_CODE
                                           message:
                                               [FlutterAppAuth
                                                   formatMessageWithError:
                                                       AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                                    error:error]
                                            result:result
                                             error:error];
                             }
                           }];
  }
}

- (id<OIDExternalUserAgentSession>)
    performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration
           requestParameters:(EndSessionRequestParameters *)requestParameters
                      result:(FlutterResult)result {
  NSURL *postLogoutRedirectURL =
      requestParameters.postLogoutRedirectUrl
          ? [NSURL URLWithString:requestParameters.postLogoutRedirectUrl]
          : nil;

  OIDEndSessionRequest *endSessionRequest =
      requestParameters.state
          ? [[OIDEndSessionRequest alloc]
                initWithConfiguration:serviceConfiguration
                          idTokenHint:requestParameters.idTokenHint
                postLogoutRedirectURL:postLogoutRedirectURL
                                state:requestParameters.state
                 additionalParameters:requestParameters.additionalParameters]
          : [[OIDEndSessionRequest alloc]
                initWithConfiguration:serviceConfiguration
                          idTokenHint:requestParameters.idTokenHint
                postLogoutRedirectURL:postLogoutRedirectURL
                 additionalParameters:requestParameters.additionalParameters];

  NSWindow *presentingWindow = yeahMusicFlutterPresentingWindowForOAuth();
  id<OIDExternalUserAgent> externalUserAgent =
      [self userAgentWithPresentingWindow:presentingWindow
                        externalUserAgent:requestParameters.externalUserAgent];
  return [OIDAuthorizationService
      presentEndSessionRequest:endSessionRequest
             externalUserAgent:externalUserAgent
                      callback:^(
                          OIDEndSessionResponse *_Nullable endSessionResponse,
                          NSError *_Nullable error) {
                        if (!endSessionResponse) {
                          NSString *message = [NSString
                              stringWithFormat:END_SESSION_ERROR_MESSAGE_FORMAT,
                                               [error localizedDescription]];
                          [FlutterAppAuth finishWithError:END_SESSION_ERROR_CODE
                                                  message:message
                                                   result:result
                                                    error:error];
                          return;
                        }
                        NSMutableDictionary *processedResponse =
                            [[NSMutableDictionary alloc] init];
                        [processedResponse setObject:endSessionResponse.state
                                              forKey:@"state"];
                        result(processedResponse);
                      }];
}

- (id<OIDExternalUserAgent>)
    userAgentWithPresentingWindow:(NSWindow *)presentingWindow
                externalUserAgent:(NSNumber *)externalUserAgent {
  if ([externalUserAgent integerValue] == EphemeralASWebAuthenticationSession) {
    return [[OIDExternalUserAgentMacNoSSO alloc]
        initWithPresentingWindow:presentingWindow];
  }
  return [[OIDExternalUserAgentMac alloc]
      initWithPresentingWindow:presentingWindow];
}

@end
