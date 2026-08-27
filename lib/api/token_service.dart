class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  String? _accessToken;
  String? _refreshToken;
  
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;
  
  void setTokens({required String accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    print('Token已更新: accessToken=${accessToken.substring(0, 20)}...');
  }
  
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    print('Token已清除');
  }
  
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      print('没有refreshToken，无法刷新');
      return false;
    }
    
    print('正在刷新Token...');
    // TODO: 调用后端刷新Token接口
    // 这里需要根据您的后端API实现
    // 示例：
    // final response = await http.post(
    //   Uri.parse('${AppConfig.baseUrl}/auth/refresh'),
    //   headers: {'Authorization': 'Bearer $_refreshToken'},
    // );
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   setTokens(
    //     accessToken: data['accessToken'],
    //     refreshToken: data['refreshToken'],
    //   );
    //   return true;
    // }
    
    return false;
  }
}
