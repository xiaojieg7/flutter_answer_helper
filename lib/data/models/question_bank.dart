class QuestionBank {
  int? id;
  String title;
  String subject;
  String difficulty;
  int totalQuestions;
  String createdDate;
  String scoreMode; // single: 单题计分, average: 平均计分

  QuestionBank({
    this.id,
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.totalQuestions,
    required this.createdDate,
    this.scoreMode = 'average',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'difficulty': difficulty,
      'total_questions': totalQuestions,
      'created_date': createdDate,
      'score_mode': scoreMode,
    };
  }

  factory QuestionBank.fromMap(Map<String, dynamic> map) {
    return QuestionBank(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      difficulty: map['difficulty'],
      totalQuestions: map['total_questions'],
      createdDate: map['created_date'],
      scoreMode: map['score_mode'] ?? 'average',
    );
  }
}
