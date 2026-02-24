import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../captcha_service.dart';

class WebCaptchaService implements CaptchaService {
  bool _sdkLoaded = false;
  bool _disposed = false;
  Function(Map<String, String>)? _onCaptchaCompleted;
  Function? _onCaptchaError;
  html.Element? _captchaContainer;
  
  @override
  Future<void> initialize() async {
    if (!_sdkLoaded) {
      _loadCaptchaSDK();
    }
  }
  
  void _loadCaptchaSDK() {
    final existingScript = html.document.querySelector('script[src*="AliyunCaptcha.js"]');
    if (existingScript != null) {
      print('阿里云验证码SDK已存在');
      _sdkLoaded = true;
      _setupCaptchaCallback();
      return;
    }
    
    final script = html.ScriptElement()
      ..src = 'https://o.alicdn.com/captcha-frontend/aliyunCaptcha/AliyunCaptcha.js'
      ..type = 'text/javascript'
      ..onLoad.listen((_) {
        print('阿里云验证码SDK加载完成');
        _sdkLoaded = true;
        _setupCaptchaCallback();
      })
      ..onError.listen((_) {
        print('阿里云验证码SDK加载失败');
        if (_onCaptchaError != null) {
          _onCaptchaError!();
        }
      });
    
    html.document.head!.append(script);
  }
  
  void _setupCaptchaCallback() {
    js.context['flutterCaptchaCallback'] = js.allowInterop((dynamic data, [dynamic _]) {
      if (_disposed) return;
      
      try {
        print('收到验证码回调数据: $data');
        final Map<String, String> captchaParams = {};
        
        if (data is String) {
          try {
            final decoded = js.context['JSON'].callMethod('parse', [data]);
            final keys = js.context['Object'].callMethod('keys', [decoded]);
            for (var i = 0; i < keys.length; i++) {
              final key = keys[i];
              captchaParams[key.toString()] = decoded[key]?.toString() ?? '';
            }
          } catch (e) {
            print('解析JSON字符串失败: $e');
          }
        } else if (data is js.JsObject) {
          final keys = js.context['Object'].callMethod('keys', [data]);
          for (var i = 0; i < keys.length; i++) {
            final key = keys[i];
            captchaParams[key.toString()] = data[key]?.toString() ?? '';
          }
        }
        
        print('解析后的验证码参数: $captchaParams');
        
        if (_onCaptchaCompleted != null) {
          _onCaptchaCompleted!(captchaParams);
        }
      } catch (e) {
        print('处理验证码回调失败: $e');
        if (_onCaptchaError != null) {
          _onCaptchaError!();
        }
      }
    });
    
    js.context['flutterCaptchaCloseCallback'] = js.allowInterop(() {
      if (_disposed) return;
      
      if (_onCaptchaError != null) {
        _onCaptchaError!();
      }
    });
  }
  
  void _initCaptchaWidget() {
    _cleanupExistingElements();
    
    _captchaContainer = html.DivElement()
      ..id = 'aliyun-captcha-container-${DateTime.now().millisecondsSinceEpoch}'
      ..style.width = '100%'
      ..style.height = '300px';
    
    final triggerBtn = html.ButtonElement()
      ..id = 'captcha-trigger-${DateTime.now().millisecondsSinceEpoch}'
      ..style.position = 'absolute'
      ..style.width = '0'
      ..style.height = '0'
      ..style.padding = '0'
      ..style.margin = '0'
      ..style.border = 'none'
      ..style.opacity = '0';
    
    html.document.body!.append(_captchaContainer!);
    html.document.body!.append(triggerBtn);
    
    try {
      js.context.callMethod('initAliyunCaptcha', [
        js.JsObject.jsify({
          'SceneId': '112sdsxg',
          'region': 'cn',
          'prefix': '79mv0l',
          'mode': 'popup',
          'element': '#${triggerBtn.id}',
          'button': '#${triggerBtn.id}',
          'captchaVerifyCallback': js.allowInterop((dynamic captchaVerifyParam, [dynamic _]) {
            print('captchaVerifyCallback被调用');
            js.context.callMethod('flutterCaptchaCallback', [captchaVerifyParam]);
          }),
          'onError': js.allowInterop((dynamic error) {
            print('验证码错误: $error');
            if (_onCaptchaError != null) {
              _onCaptchaError!();
            }
          }),
          'onClose': js.allowInterop(() {
            print('验证码弹窗关闭');
            js.context.callMethod('flutterCaptchaCloseCallback', []);
          }),
        }),
        js.allowInterop((dynamic instance) {
          print('验证码初始化完成');
          Future.delayed(const Duration(milliseconds: 100), () {
            triggerBtn.click();
          });
        })
      ]);
    } catch (e) {
      print('初始化验证码失败: $e');
      if (_onCaptchaError != null) {
        _onCaptchaError!();
      }
    }
  }
  
  void _cleanupExistingElements() {
    final oldContainers = html.document.querySelectorAll('[id^="aliyun-captcha-container"]');
    for (var i = 0; i < oldContainers.length; i++) {
      oldContainers[i].remove();
    }
    
    final oldTriggers = html.document.querySelectorAll('[id^="captcha-trigger"]');
    for (var i = 0; i < oldTriggers.length; i++) {
      oldTriggers[i].remove();
    }
    
    final masks = html.document.querySelectorAll('[id*="aliyunCaptcha"]');
    for (var i = 0; i < masks.length; i++) {
      masks[i].remove();
    }
  }
  
  @override
  Widget buildCaptchaWidget({
    required Function(Map<String, String>) onCaptchaCompleted,
    required Function onCaptchaError,
  }) {
    _disposed = false;
    _onCaptchaCompleted = onCaptchaCompleted;
    _onCaptchaError = onCaptchaError;
    
    initialize().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _initCaptchaWidget();
      });
    });
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  @override
  Future<void> showCaptcha() async {
    final triggerBtns = html.document.querySelectorAll('[id^="captcha-trigger"]');
    if (triggerBtns.isNotEmpty) {
      (triggerBtns.first as html.ButtonElement).click();
    }
  }
  
  @override
  Future<void> hideCaptcha() async {
    // popup模式会自动隐藏
  }
  
  @override
  Future<void> refreshCaptcha() async {
    // 可以重新初始化
  }
  
  @override
  void dispose() {
    _disposed = true;
    
    if (_captchaContainer != null) {
      _captchaContainer!.remove();
      _captchaContainer = null;
    }
    
    _cleanupExistingElements();
  }
}
