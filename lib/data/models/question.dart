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
    );
  }
}
