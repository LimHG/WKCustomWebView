# WKCustomWebView

[![CI Status](https://img.shields.io/travis/LimHG/WKCustomWebView.svg?style=flat)](https://travis-ci.org/LimHG/WKCustomWebView)
[![Version](https://img.shields.io/cocoapods/v/WKCustomWebView.svg?style=flat)](https://cocoapods.org/pods/WKCustomWebView)
[![License](https://img.shields.io/cocoapods/l/WKCustomWebView.svg?style=flat)](https://cocoapods.org/pods/WKCustomWebView)
[![Platform](https://img.shields.io/cocoapods/p/WKCustomWebView.svg?style=flat)](https://cocoapods.org/pods/WKCustomWebView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

WKCustomWebView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WKCustomWebView'
```

## How to Use

1. WKCustomWebView를 사용할 화면에서 Lazy 객체 생성 및 초기화
```ruby
// InappAlert Class import
import WKCustomWebView

// WKCustomWebView 변수 생성
// - frame : WKCustomWebView를 그릴 Frame 지정
// - userDefault : 앱에서 사용할 UserDefault 객체 전달 (쿠키 정보 저장을 위해 사용)
// - uDCookie : 앱에서 사용할 UserDefault에 저장할 키 이름 
// - saveCookieName : Cookie중 저장할 쿠키 문자열 (포함검색) 
// - deleteCookieName : Cookie 중 삭제할 쿠기 문자열 (포함검색) 
lazy var wkWebView: WKCustomWebView = {
    let webView: WKCustomWebView = WKCustomWebView(frame: CGRect.init(x: 0, y: 0, width: self.mainView.frame.size.width, height: self.mainView.frame.size.height), userDefault: <UserDefault 객체>, uDCookie: "쿠키 저장 키이름", saveCookieName: "저장할 쿠키 문자열", deleteCookieName: "삭제할 쿠키 문자열")
    return webView
    
}()
```

2. WKCustomWebView Delegate 이용
```ruby
// WKWebView의 UIDelegate 이용시
self.wkWebView.uiDelegate = self
// WKCustomWebView wkNavigationDelegate 이용 시
self.wkWebView.wkNavigationDelegate = self

// wkNavigationDelegate self 시 사용가능 함수 
// - onDecidePolicyForNavigationAction의 경우 WKWebView의 WKNavigationDelegate의 decidePolicyForNavigationAction 함수와 매칭된다.
self.wkWebView.onDecidePolicyForNavigationAction = { (webView, navigationAction, decisionHandler) in
    if(navigationAction.request.url?.absoluteString == "about:blank")
    {
        decisionHandler(.cancel)
    } else {
        decisionHandler(.allow)
    }
}
// - onDecidePolicyForNavigationResponse의 경우 WKWebView의 WKNavigationDelegate의 decidePolicyForNavigationResponse 함수와 매칭된다.
self.wkWebView.onDecidePolicyForNavigationResponse = { (webView, navigationResponse, decisionHandler) in
    decisionHandler(.allow)
}
```

3. WKCustomWebView 객체를 이용하여 기존 WKWebView 객체와 동일하게 사용시 자동으로 Cookie를 관리하게 된다.


## Author

LimHG, dla.hg210@gmail.com

## License

WKCustomWebView is available under the MIT license. See the LICENSE file for more info.
