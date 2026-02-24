import 'models/question_bank.dart';
import 'models/question.dart';
import 'models/user_record.dart';

// 数据库服务抽象接口
abstract class DatabaseService {
  // 初始化数据库
  Future<void> initialize();

  // 题库相关操作
  Future<int> insertQuestionBank(QuestionBank bank);
  Future<List<QuestionBank>> getQuestionBanks();
  Future<int> deleteQuestionBank(int bankId);

  // 题目相关操作
  Future<int> insertQuestion(Question question);
  Future<void> batchInsertQuestions(List<Question> questions);
  Future<List<Question>> getQuestionsByBankId(int bankId);

  // 用户记录相关操作
  Future<int> insertOrUpdateUserRecord(UserRecord record);
  Future<List<Question>> getWrongQuestions();
  Future<List<Question>> getMarkedQuestions();
  Future<int> toggleMarkQuestion(int questionId, bool isMarked);
  Future<int> markQuestionAsCorrect(int questionId);

  // 其他操作
  Future<int> clearAllData();
}
