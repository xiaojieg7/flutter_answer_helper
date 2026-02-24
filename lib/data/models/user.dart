class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // 从Map创建User实例
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 复制方法，用于创建新实例
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}