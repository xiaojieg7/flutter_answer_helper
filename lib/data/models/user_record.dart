class UserRecord {
  int? id;
  int questionId;
  bool isIncorrect;
  bool isMarked;
  String lastAttempted;
  dynamic userAnswer;

  UserRecord({
    this.id,
    required this.questionId,
    this.isIncorrect = false,
    this.isMarked = false,
    required this.lastAttempted,
    this.userAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'is_incorrect': isIncorrect ? 1 : 0,
      'is_marked': isMarked ? 1 : 0,
      'last_attempted': lastAttempted,
      'user_answer': userAnswer.toString(),
    };
  }

  factory UserRecord.fromMap(Map<String, dynamic> map) {
    // 解析用户答案
    dynamic userAnswer;
    try {
      String answerStr = map['user_answer'];
      if (answerStr.startsWith('[')) {
        // 多选题答案，转换为数组
        answerStr = answerStr.replaceAll(RegExp(r'^\[|\]$'), '');
        List<String> answers = answerStr.split(',').map((e) => e.trim().replaceAll(RegExp(r'^"|"$'), '')).toList();
        userAnswer = answers;
      } else {
        // 单选题答案，直接使用字符串
        userAnswer = answerStr.replaceAll(RegExp(r'^"|"$'), '');
      }
    } catch (e) {
      userAnswer = '';
    }

    return UserRecord(
      id: map['id'],
      questionId: map['question_id'],
      isIncorrect: map['is_incorrect'] == 1,
      isMarked: map['is_marked'] == 1,
      lastAttempted: map['last_attempted'],
      userAnswer: userAnswer,
    );
  }
}
