import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../captcha_service.dart';
import '../../config/app_config.dart';

class WebCaptchaService implements CaptchaService {
  bool _sdkLoaded = false;
  bool _sdkLoading = false;
  bool _disposed = false;
  bool _isLoading = true;
  String? _currentTriggerId;
  Function(String)? _onCaptchaCompleted;
  Function(CaptchaRefreshReason)? _onCaptchaRefresh;
  Function(String)? _onError;
  html.Element? _captchaContainer;
  Completer<void>? _sdkLoadCompleter;
  
  @override
  Future<void> initialize() async {
    if (_sdkLoaded) return;
    if (_sdkLoading && _sdkLoadCompleter != null) {
      await _sdkLoadCompleter!.future;
      return;
    }
    
    _sdkLoading = true;
    _sdkLoadCompleter = Completer<void>();
    _loadCaptchaSDK();
    await _sdkLoadCompleter!.future;
  }
  
  void _loadCaptchaSDK() {
    final existingScript = html.document.querySelector('script[src*="AliyunCaptcha.js"]');
    if (existingScript != null) {
      print('阿里云验证码SDK已存在');
      _onSdkLoaded();
      return;
    }
    
    print('开始加载阿里云验证码SDK');
    final script = html.ScriptElement()
      ..src = AppConfig.captchaSdkUrl
      ..type = 'text/javascript'
      ..onLoad.listen((_) {
        print('阿里云验证码SDK加载完成');
        _onSdkLoaded();
      })
      ..onError.listen((_) {
        print('阿里云验证码SDK加载失败');
        _onSdkLoadFailed();
      });
    
    html.document.head!.append(script);
  }
  
  void _onSdkLoaded() {
    _sdkLoaded = true;
    _sdkLoading = false;
    _setupCaptchaCallback();
    _sdkLoadCompleter?.complete();
  }
  
  void _onSdkLoadFailed() {
    _sdkLoading = false;
    _isLoading = false;
    _sdkLoadCompleter?.completeError('SDK加载失败');
    if (_onCaptchaRefresh != null && !_disposed) {
      _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
    }
  }
  
  void _setupCaptchaCallback() {
    js.context['flutterCaptchaCallback'] = js.allowInterop((dynamic data, [dynamic _]) {
      if (_disposed) return;
      
      try {
        print('收到验证码回调数据: $data');
        
        String captchaVerifyParam;
        if (data is String) {
          captchaVerifyParam = data;
        } else if (data is js.JsObject) {
          captchaVerifyParam = js.context['JSON'].callMethod('stringify', [data]);
        } else {
          captchaVerifyParam = data.toString();
        }
        
        print('验证码参数: $captchaVerifyParam');
        
        if (_onCaptchaCompleted != null) {
          _onCaptchaCompleted!(captchaVerifyParam);
        }
      } catch (e) {
        print('处理验证码回调失败: $e');
        if (_onCaptchaRefresh != null && !_disposed) {
          _onCaptchaRefresh!(CaptchaRefreshReason.verifyFailed);
        }
      }
    });
    
    js.context['flutterCaptchaCloseCallback'] = js.allowInterop(() {
      if (_disposed) return;
      print('用户关闭验证码弹窗');
      if (_onCaptchaRefresh != null) {
        _onCaptchaRefresh!(CaptchaRefreshReason.userClosed);
      }
    });
    
    js.context['flutterCaptchaErrorCallback'] = js.allowInterop((dynamic error) {
      if (_disposed) return;
      print('验证码错误: $error');
      if (_onCaptchaRefresh != null) {
        _onCaptchaRefresh!(CaptchaRefreshReason.verifyFailed);
      }
    });
    
    js.context['flutterCaptchaExpiredCallback'] = js.allowInterop(() {
      if (_disposed) return;
      print('验证码过期');
      if (_onCaptchaRefresh != null) {
        _onCaptchaRefresh!(CaptchaRefreshReason.expired);
      }
    });
  }
  
  void _initCaptchaWidget() {
    if (!_sdkLoaded) {
      print('SDK未加载完成，无法初始化验证码');
      return;
    }
    
    _cleanupExistingElements();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentTriggerId = 'captcha-trigger-$timestamp';
    
    _captchaContainer = html.DivElement()
      ..id = 'aliyun-captcha-container-$timestamp'
      ..style.width = '100%'
      ..style.height = '300px';
    
    final triggerBtn = html.ButtonElement()
      ..id = _currentTriggerId!
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
          'SceneId': AppConfig.captchaSceneId,
          'region': AppConfig.captchaRegion,
          'prefix': AppConfig.captchaPrefix,
          'mode': 'popup',
          'element': '#${triggerBtn.id}',
          'button': '#${triggerBtn.id}',
          'captchaVerifyCallback': js.allowInterop((dynamic captchaVerifyParam, [dynamic _]) {
            print('captchaVerifyCallback被调用');
            js.context.callMethod('flutterCaptchaCallback', [captchaVerifyParam]);
          }),
          'onError': js.allowInterop((dynamic error) {
            print('验证码错误回调: $error');
            js.context.callMethod('flutterCaptchaErrorCallback', [error]);
          }),
          'onClose': js.allowInterop(() {
            print('验证码关闭回调');
            js.context.callMethod('flutterCaptchaCloseCallback', []);
          }),
        }),
        js.allowInterop((dynamic instance) {
          print('验证码初始化完成');
          _isLoading = false;
          if (_disposed) return;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!_disposed) {
              triggerBtn.click();
            }
          });
        })
      ]);
    } catch (e) {
      print('初始化验证码失败: $e');
      _isLoading = false;
      if (_onCaptchaRefresh != null && !_disposed) {
        _onCaptchaRefresh!(CaptchaRefreshReason.loadFailed);
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
    required Function(String) onCaptchaCompleted,
    required Function(CaptchaRefreshReason) onCaptchaRefresh,
    required Function(String) onError,
  }) {
    _disposed = false;
    _onCaptchaCompleted = onCaptchaCompleted;
    _onCaptchaRefresh = onCaptchaRefresh;
    _onError = onError;
    
    initialize().then((_) {
      if (!_disposed) {
        _initCaptchaWidget();
      }
    }).catchError((e) {
      print('初始化失败: $e');
      if (!_disposed) {
        _isLoading = false;
      }
    });
    
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
          child: _isLoading || !_sdkLoaded
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
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
  
  @override
  Future<void> showCaptcha() async {
    if (_currentTriggerId != null) {
      final triggerBtn = html.document.getElementById(_currentTriggerId!);
      if (triggerBtn != null) {
        (triggerBtn as html.ButtonElement).click();
      }
    }
  }
  
  @override
  Future<void> hideCaptcha() async {
    _cleanupExistingElements();
  }
  
  @override
  Future<void> refreshCaptcha() async {
    _cleanupExistingElements();
    _initCaptchaWidget();
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
