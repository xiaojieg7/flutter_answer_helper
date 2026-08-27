import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../captcha_service.dart';

class AndroidCaptchaService implements CaptchaService {
  WebViewController? _webViewController;
  bool _isInitialized = false;
  bool _disposed = false;
  bool _isLoading = true;
  Function(String)? _onCaptchaCompleted;
  Function(CaptchaRefreshReason)? _onCaptchaRefresh;
  Function(String)? _onError;
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _isLoading = true;
          },
          onPageFinished: (String url) {
            _isLoading = false;
            if (!_disposed) {
              _initializeCaptcha();
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView加载错误: $error');
            _isLoading = false;
            if (_onCaptchaRefresh != null && !_disposed) {
              _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('WebView导航请求: ${request.url}');
            if (request.url.startsWith('file://') ||
                (request.url.startsWith('https://') && 
                       (request.url.contains('alicdn.com') || 
                        request.url.contains('aliyun.com') ||
                        request.url.contains('alibaba.com')))) {
              return NavigationDecision.navigate;
            }
            print('阻止导航: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (_disposed) return;
          
          try {
            final data = json.decode(message.message);
            final type = data['type'] as String?;
            
            switch (type) {
              case 'captcha_success':
                final captchaData = data['data'];
                _handleCaptchaSuccess(captchaData);
                break;
              case 'captcha_close':
                print('用户关闭验证码');
                if (_onCaptchaRefresh != null) {
                  _onCaptchaRefresh!(CaptchaRefreshReason.userClosed);
                }
                break;
              case 'captcha_error':
                print('验证码错误: ${data['message']}');
                if (_onCaptchaRefresh != null) {
                  _onCaptchaRefresh!(CaptchaRefreshReason.verifyFailed);
                }
                break;
              case 'captcha_expired':
                print('验证码过期');
                if (_onCaptchaRefresh != null) {
                  _onCaptchaRefresh!(CaptchaRefreshReason.expired);
                }
                break;
              case 'sdk_loaded':
                print('SDK加载成功');
                break;
              case 'sdk_error':
                print('SDK加载失败: ${data['message']}');
                if (_onCaptchaRefresh != null) {
                  _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
                }
                break;
            }
          } catch (e) {
            print('解析JavaScript消息失败: $e');
          }
        },
      )
      ..loadFlutterAsset('assets/index.html');
    _isInitialized = true;
  }
  
  Future<void> _initializeCaptcha() async {
    if (_webViewController == null || _disposed) return;
    
    try {
      int checkCount = 0;
      const maxCheckCount = 50;
      
      while (checkCount < maxCheckCount) {
        try {
          final result = await _webViewController!.runJavaScriptReturningResult(
            'typeof window.initAliyunCaptcha === "function"'
          );
          
          if (result == true) {
            break;
          }
        } catch (e) {
          // 忽略错误继续等待
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        checkCount++;
      }
      
      if (checkCount >= maxCheckCount) {
        if (_onCaptchaRefresh != null && !_disposed) {
          _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
        }
        return;
      }
      
      await _webViewController!.runJavaScript('window.initCaptcha()');
    } catch (e) {
      print('初始化验证码失败: $e');
      if (_onCaptchaRefresh != null && !_disposed) {
        _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
      }
    }
  }
  
  void _handleCaptchaSuccess(dynamic captchaData) {
    try {
      print('收到验证码数据: $captchaData');
      
      String captchaVerifyParam;
      if (captchaData is String) {
        captchaVerifyParam = captchaData;
      } else if (captchaData is Map) {
        captchaVerifyParam = jsonEncode(captchaData);
      } else {
        captchaVerifyParam = captchaData.toString();
      }
      
      print('验证码参数: $captchaVerifyParam');
      
      if (_onCaptchaCompleted != null) {
        _onCaptchaCompleted!(captchaVerifyParam);
      }
    } catch (e) {
      print('处理验证码数据失败: $e');
      if (_onCaptchaRefresh != null && !_disposed) {
        _onCaptchaRefresh!(CaptchaRefreshReason.verifyFailed);
      }
    }
  }
  
  @override
  Widget buildCaptchaWidget({
    required Function(String) onCaptchaCompleted,
    required Function(CaptchaRefreshReason) onCaptchaRefresh,
    required Function(String) onError,
  }) {
    _onCaptchaCompleted = onCaptchaCompleted;
    _onCaptchaRefresh = onCaptchaRefresh;
    _onError = onError;
    
    initialize();
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 320,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading 
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('加载验证码中...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : WebViewWidget(controller: _webViewController!),
        ),
      ),
    );
  }
  
  @override
  Future<void> showCaptcha() async {
    if (!_disposed && _webViewController != null) {
      await _webViewController!.runJavaScript('window.showCaptcha()');
    }
  }
  
  @override
  Future<void> hideCaptcha() async {
    if (!_disposed && _webViewController != null) {
      await _webViewController!.runJavaScript('window.hideCaptcha()');
    }
  }
  
  @override
  Future<void> refreshCaptcha() async {
    if (!_disposed && _webViewController != null) {
      await _webViewController!.runJavaScript('window.refreshCaptcha()');
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    if (_webViewController != null) {
      _webViewController!.runJavaScript('''
        document.getElementById("aliyunCaptcha-mask")?.remove();
        document.getElementById("aliyunCaptcha-window-popup")?.remove();
      ''').catchError((e) {});
    }
  }
}
