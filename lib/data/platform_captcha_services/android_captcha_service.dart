import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../captcha_service.dart';

class AndroidCaptchaService implements CaptchaService {
  late WebViewController _webViewController;
  bool _isInitialized = false;
  bool _disposed = false;
  Function(Map<String, String>)? _onCaptchaCompleted;
  Function? _onCaptchaError;
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (!_disposed) {
              _initializeCaptcha();
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView加载错误: $error');
            if (!_disposed && _onCaptchaError != null) {
              _onCaptchaError!();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('file:///android_asset/flutter_assets/assets/index.html')) {
              return NavigationDecision.navigate;
            } else if (request.url.startsWith('https://') && 
                       (request.url.contains('alicdn.com') || 
                        request.url.contains('aliyun.com') ||
                        request.url.contains('alibaba.com'))) {
              return NavigationDecision.navigate;
            }
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
            if (data['type'] == 'captcha_success') {
              final captchaData = data['data'];
              _handleCaptchaSuccess(captchaData);
            } else if (data['type'] == 'captcha_close') {
              if (_onCaptchaError != null) {
                _onCaptchaError!();
              }
            }
          } catch (e) {
            print('解析JavaScript消息失败: $e');
            if (_onCaptchaError != null) {
              _onCaptchaError!();
            }
          }
        },
      )
      ..loadFlutterAsset('assets/index.html');
    
    _isInitialized = true;
  }
  
  Future<void> _initializeCaptcha() async {
    try {
      int checkCount = 0;
      const maxCheckCount = 50;
      
      while (checkCount < maxCheckCount) {
        try {
          final result = await _webViewController.runJavaScriptReturningResult(
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
        if (_onCaptchaError != null) {
          _onCaptchaError!();
        }
        return;
      }
      
      await _webViewController.runJavaScript('window.initCaptcha()');
    } catch (e) {
      print('初始化验证码失败: $e');
      if (_onCaptchaError != null) {
        _onCaptchaError!();
      }
    }
  }
  
  void _handleCaptchaSuccess(dynamic captchaData) {
    try {
      Map<dynamic, dynamic> captchaMap;
      if (captchaData is String) {
        captchaMap = json.decode(captchaData);
      } else if (captchaData is Map) {
        captchaMap = captchaData;
      } else {
        if (_onCaptchaError != null) {
          _onCaptchaError!();
        }
        return;
      }
      
      final captchaParams = <String, String>{};
      
      if (captchaMap.containsKey('sessionId')) {
        captchaParams['sessionId'] = captchaMap['sessionId']?.toString() ?? '';
        captchaParams['token'] = captchaMap['token']?.toString() ?? '';
        captchaParams['sig'] = captchaMap['sig']?.toString() ?? '';
      } else if (captchaMap.containsKey('certifyId')) {
        captchaParams['sessionId'] = captchaMap['certifyId']?.toString() ?? '';
        captchaParams['token'] = captchaMap['deviceToken']?.toString() ?? '';
        captchaParams['sig'] = captchaMap['sceneId']?.toString() ?? '';
      } else {
        captchaParams['sessionId'] = captchaMap.values.first?.toString() ?? '';
        captchaParams['token'] = captchaMap.values.first?.toString() ?? '';
        captchaParams['sig'] = captchaMap.values.first?.toString() ?? '';
      }
      
      if (_onCaptchaCompleted != null) {
        _onCaptchaCompleted!(captchaParams);
      }
    } catch (e) {
      print('处理验证码数据失败: $e');
      if (_onCaptchaError != null) {
        _onCaptchaError!();
      }
    }
  }
  
  @override
  Widget buildCaptchaWidget({
    required Function(Map<String, String>) onCaptchaCompleted,
    required Function onCaptchaError,
  }) {
    _onCaptchaCompleted = onCaptchaCompleted;
    _onCaptchaError = onCaptchaError;
    
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
          child: WebViewWidget(controller: _webViewController),
        ),
      ),
    );
  }
  
  @override
  Future<void> showCaptcha() async {
    if (!_disposed) {
      await _webViewController.runJavaScript('window.showCaptcha()');
    }
  }
  
  @override
  Future<void> hideCaptcha() async {
    if (!_disposed) {
      await _webViewController.runJavaScript('window.hideCaptcha()');
    }
  }
  
  @override
  Future<void> refreshCaptcha() async {
    if (!_disposed) {
      await _webViewController.runJavaScript('window.refreshCaptcha()');
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    if (!_disposed) {
      _webViewController.runJavaScript('''
        document.getElementById("aliyunCaptcha-mask")?.remove();
        document.getElementById("aliyunCaptcha-window-popup")?.remove();
      ''').catchError((e) {});
    }
  }
}
