import 'dart:convert';

class Question {
  int? id;
  int bankId;
  int originalId;
  String type;
  String question;
  Map<String, String> options;
  dynamic correctAnswer;
  String explanation;
  int score;
  String? imageBase64; // 题目配图（单张），base64编码直接存入数据库

  Question({
    this.id,
    required this.bankId,
    required this.originalId,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.score = 1,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_id': bankId,
      'original_id': originalId,
      'type': type,
      'question': question,
      'options': jsonEncode(options),
      'correct_answer': jsonEncode(correctAnswer),
      'explanation': explanation,
      'score': score,
      'image_base64': imageBase64,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      bankId: map['bank_id'],
      originalId: map['original_id'],
      type: map['type'],
      question: map['question'],
      options: Map<String, String>.from(jsonDecode(map['options'])),
      correctAnswer: jsonDecode(map['correct_answer']),
      explanation: map['explanation'],
      score: map['score'] ?? 1,
      imageBase64: map['image_base64'],
    );
  }

  // 复制方法，用于创建新实例
  Question copyWith({
    int? id,
    int? bankId,
    int? originalId,
    String? type,
    String? question,
    Map<String, String>? options,
    dynamic correctAnswer,
    String? explanation,
    int? score,
    String? imageBase64,
  }) {
    return Question(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      originalId: originalId ?? this.originalId,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      score: score ?? this.score,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
