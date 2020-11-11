import UIKit
import Foundation
import WebKit

open class WKCustomWebView: WKWebView {
    // navigationDelegate
    @objc public weak var wkNavigationDelegate: WKNavigationDelegate?
    // WKCustomWebView Delegate Function
    @objc public var onDecidePolicyForNavigationAction: ((WKWebView, WKNavigationAction, @escaping (WKNavigationActionPolicy) -> Swift.Void) -> Void)?
    @objc public var onDecidePolicyForNavigationResponse: ((WKWebView, WKNavigationResponse, @escaping (WKNavigationResponsePolicy) -> Swift.Void) -> Void)?
    @objc public var onDidReceiveChallenge: ((WKWebView, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) -> Void)?
    
    // WKCustomWebView inside Value
    private var userDefault: UserDefaults? = nil
    private var uDCookie: String = ""
    private var deleteCookieName: String = ""
    
    @objc
    public init(frame: CGRect, userDefault: UserDefaults, uDCookie: String, deleteCookieName: String = "", configurationBlock: ((WKWebViewConfiguration) -> Void)? = nil) {
        self.userDefault = userDefault
        self.uDCookie = uDCookie
        self.deleteCookieName = deleteCookieName
        
        let wkDataStore = WKWebsiteDataStore.nonPersistent()
        let sharedCookies: Array<HTTPCookie> = HTTPCookieStorage.shared.cookies!
        let dispatchGroup = DispatchGroup()
        let config = WKWebViewConfiguration()
        let preferences: WKPreferences = WKPreferences.init()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        
        if let cookieDictionary = self.userDefault?.dictionary(forKey: self.uDCookie) {
            for (_, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                    dispatchGroup.enter()
                    if #available(iOS 11.0, *) {
                        wkDataStore.httpCookieStore.setCookie(cookie){
                            dispatchGroup.leave()
                        }
                    } else {
                        HTTPCookieStorage.shared.setCookie(cookie)
                        dispatchGroup.leave()
                    }
                }
            }
        } else {
            for cookie in sharedCookies{
                dispatchGroup.enter()
                if #available(iOS 11.0, *) {
                    wkDataStore.httpCookieStore.setCookie(cookie){
                        dispatchGroup.leave()
                    }
                } else {
                    HTTPCookieStorage.shared.setCookie(cookie)
                    dispatchGroup.leave()
                }
            }
        }

        config.websiteDataStore = wkDataStore
        config.preferences = preferences
        
        super.init(frame: frame, configuration: config)
        navigationDelegate = self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("WKCustomWebView : init(coder:) has not been implemented, init(frame:configurationBlock:)")
    }
    
}


extension WKCustomWebView: WKNavigationDelegate {
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let handler = onDecidePolicyForNavigationAction {
            handler(webView, navigationAction, decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        if let handler = onDecidePolicyForNavigationResponse {
//            if(webView.url?.absoluteString.contains("https://accounts.google.com/o/oauth2/auth?"))!
//            {
//                if (navigationResponse.response is HTTPURLResponse) {
//                    let response = navigationResponse.response as? HTTPURLResponse
//                    #if DEBUG
//                    print(String(format: "WKCustomWebView : response.statusCode: %ld", response?.statusCode ?? 0))
//                    #endif
//                    if response?.statusCode != 200 {
//                        // 네이티브 로그인 작업 부분
//                    }
//                }
//            }
            
            // * 구글 WebView 로그인 막혔을 경우 체크를 위한 코드 부분
            if (navigationResponse.response is HTTPURLResponse) {
                let response = navigationResponse.response as? HTTPURLResponse
                #if DEBUG
                print(String(format: "WKCustomWebView : response.statusCode: %ld", response?.statusCode ?? 0))
                #endif
                if response?.statusCode != 200 {
                    // 네이티브 로그인 작업 부분
                }
            }
            
            handler(webView, navigationResponse, decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        wkNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if #available(iOS 11.0, *) {
            // 쿠키 저장 부분
            var cookieDict = [String : AnyObject]()
            self.configuration.websiteDataStore.httpCookieStore.getAllCookies({
            (cookies) in
                if(cookies.count > 0)
                {
                    let now = Date()
                    for cookie in cookies {
                        if(cookie.domain.contains(URL_COOKIE)) {
                            #if DEBUG
                            print("WKCustomWebView : cookie name == \(cookie.name)")
                            #endif
                            
                            if let expiresDate = cookie.expiresDate, now.compare(expiresDate) == .orderedDescending {
                                HTTPCookieStorage.shared.deleteCookie(cookie)
                                webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: nil)
                            }
                            else {
                                if(self.deleteCookieName != "")
                                {
                                    if(cookie.name.contains(self.deleteCookieName))
                                    {
                                        HTTPCookieStorage.shared.deleteCookie(cookie)
                                        webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: nil)
                                    } else {
                                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                                    }
                                } else {
                                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                                }
                            }
                        }
                    }

                    self.userDefault?.set(cookieDict, forKey: self.uDCookie)
                    self.userDefault?.synchronize()
                } else {
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        let now = Date()
                        for cookie in cookies {

                            if(cookie.domain.contains(URL_COOKIE)) {
                                if let expiresDate = cookie.expiresDate, now.compare(expiresDate) == .orderedDescending {
                                    HTTPCookieStorage.shared.deleteCookie(cookie)
                                    webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: nil)
                                } else {
                                    if(self.deleteCookieName != "")
                                    {
                                        if(cookie.name.contains(self.deleteCookieName))
                                        {
                                            HTTPCookieStorage.shared.deleteCookie(cookie)
                                            webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: nil)
                                        } else {
                                            cookieDict[cookie.name] = cookie.properties as AnyObject?
                                        }
                                    } else {
                                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                                    }
                                }
                            }
                        }
                        self.userDefault?.set(cookieDict, forKey: self.uDCookie)
                        self.userDefault?.synchronize()
                    }
                }
            })
        } else {
            // 쿠키 저장 부분
            var cookieDict = [String : AnyObject]()
            if let cookies = HTTPCookieStorage.shared.cookies {
                let now = Date()
                for cookie in cookies {
                    if(cookie.domain.contains(URL_COOKIE)) {
                        if let expiresDate = cookie.expiresDate, now.compare(expiresDate) == .orderedDescending {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        } else {
                            if(self.deleteCookieName != "")
                            {
                                if(cookie.name.contains(self.deleteCookieName))
                                {
                                    HTTPCookieStorage.shared.deleteCookie(cookie)
                                } else {
                                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                                }
                            } else {
                                cookieDict[cookie.name] = cookie.properties as AnyObject?
                            }
                        }
                    }
                }

                self.userDefault?.set(cookieDict, forKey: self.uDCookie)
                self.userDefault?.synchronize()
            }
        }
        
        
        wkNavigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didFinish: navigation)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        wkNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if let handler = onDidReceiveChallenge {
            handler(webView, challenge, completionHandler)
        } else {
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    credential = URLCredential(trust: serverTrust)
                    disposition = .useCredential
                }
            } else {
                disposition = .cancelAuthenticationChallenge
            }
            
            completionHandler(disposition, credential)
        }
    }
    
    @available(iOS 9.0, *)
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        wkNavigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }
    
}