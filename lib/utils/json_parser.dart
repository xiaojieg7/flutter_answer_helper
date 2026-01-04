import 'dart:convert';
import '../data/models/question_bank.dart';
import '../data/models/question.dart';

class JsonParser {
  // 验证JSON结构
  static bool validateJsonStructure(Map<String, dynamic> json) {
    // 检查schema_version字段
    if (!json.containsKey('schema_version') || json['schema_version'] != '1.0') {
      return false;
    }

    // 检查metadata字段
    if (!json.containsKey('metadata') || json['metadata'] is! Map) {
      return false;
    }

    Map<String, dynamic> metadata = json['metadata'];
    // 检查metadata必填字段
    if (!metadata.containsKey('title') ||
        !metadata.containsKey('subject') ||
        !metadata.containsKey('difficulty') ||
        !metadata.containsKey('total_questions') ||
        !metadata.containsKey('created_date')) {
      return false;
    }

    // 检查questions字段
    if (!json.containsKey('questions') || json['questions'] is! List) {
      return false;
    }

    return true;
  }

  // 解析JSON到QuestionBank和Question列表
  static Future<(QuestionBank, List<Question>)> parseJson(String jsonString, int bankId) async {
    try {
      Map<String, dynamic> json = jsonDecode(jsonString);

      // 验证JSON结构
      if (!validateJsonStructure(json)) {
        throw Exception('Invalid JSON structure');
      }

      // 解析metadata
      Map<String, dynamic> metadata = json['metadata'];
      QuestionBank questionBank = QuestionBank(
        id: bankId,
        title: metadata['title'],
        subject: metadata['subject'],
        difficulty: metadata['difficulty'],
        totalQuestions: metadata['total_questions'],
        createdDate: metadata['created_date'],
        scoreMode: metadata.containsKey('score_mode') ? metadata['score_mode'] : 'average',
      );

      // 解析questions
      List<dynamic> questionsJson = json['questions'];
      List<Question> questions = [];

      for (var questionJson in questionsJson) {
        // 验证题目必填字段
        if (!questionJson.containsKey('id') ||
            !questionJson.containsKey('type') ||
            !questionJson.containsKey('question') ||
            !questionJson.containsKey('correct_answer') ||
            !questionJson.containsKey('explanation')) {
          throw Exception('Invalid question structure');
        }

        // 解析题目
        Question question = Question(
          bankId: bankId,
          originalId: questionJson['id'],
          type: questionJson['type'],
          question: questionJson['question'],
          options: questionJson.containsKey('options') ? Map<String, String>.from(questionJson['options']) : {},
          correctAnswer: questionJson['correct_answer'],
          explanation: questionJson['explanation'],
          score: questionJson.containsKey('score') ? questionJson['score'] : 1,
        );

        questions.add(question);
      }

      return (questionBank, questions);
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }
}
