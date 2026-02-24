import 'dart:convert';
import '../database_service.dart';
import '../models/question_bank.dart';
import '../models/question.dart';
import '../models/user_record.dart';

// Web平台的数据库服务实现（使用localStorage）
class WebDatabaseService implements DatabaseService {
  // localStorage键名
  static const String _keyQuestionBanks = 'question_banks';
  static const String _keyQuestions = 'questions';
  static const String _keyUserRecords = 'user_records';
  static const String _keyNextIds = 'next_ids';

  // 内存中的数据缓存
  List<QuestionBank> _questionBanks = [];
  List<Question> _questions = [];
  List<UserRecord> _userRecords = [];
  Map<String, int> _nextIds = {
    'question_banks': 1,
    'questions': 1,
    'user_records': 1,
  };

  @override
  Future<void> initialize() async {
    // 从localStorage加载数据
    _loadFromLocalStorage();
  }

  // 从localStorage加载数据
  void _loadFromLocalStorage() {
    // 加载题库数据
    final String? banksJson = _getFromLocalStorage(_keyQuestionBanks);
    if (banksJson != null) {
      final List<dynamic> banksList = jsonDecode(banksJson);
      _questionBanks = banksList.map((e) => QuestionBank.fromMap(e)).toList();
    }

    // 加载题目数据
    final String? questionsJson = _getFromLocalStorage(_keyQuestions);
    if (questionsJson != null) {
      final List<dynamic> questionsList = jsonDecode(questionsJson);
      _questions = questionsList.map((e) => Question.fromMap(e)).toList();
    }

    // 加载用户记录数据
    final String? recordsJson = _getFromLocalStorage(_keyUserRecords);
    if (recordsJson != null) {
      final List<dynamic> recordsList = jsonDecode(recordsJson);
      _userRecords = recordsList.map((e) => UserRecord.fromMap(e)).toList();
    }

    // 加载下一个ID
    final String? idsJson = _getFromLocalStorage(_keyNextIds);
    if (idsJson != null) {
      _nextIds = Map<String, int>.from(jsonDecode(idsJson));
    }

    // 更新下一个ID值
    _updateNextIds();
  }

  // 更新下一个ID值
  void _updateNextIds() {
    if (_questionBanks.isNotEmpty) {
      final maxBankId = _questionBanks.map((b) => b.id ?? 0).reduce((a, b) => a > b ? a : b);
      _nextIds['question_banks'] = maxBankId + 1;
    }

    if (_questions.isNotEmpty) {
      final maxQuestionId = _questions.map((q) => q.id ?? 0).reduce((a, b) => a > b ? a : b);
      _nextIds['questions'] = maxQuestionId + 1;
    }

    if (_userRecords.isNotEmpty) {
      final maxRecordId = _userRecords.map((r) => r.id ?? 0).reduce((a, b) => a > b ? a : b);
      _nextIds['user_records'] = maxRecordId + 1;
    }

    _saveNextIds();
  }

  // 保存数据到localStorage
  void _saveToLocalStorage() {
    // 保存题库数据
    _saveToLocalStorageKey(_keyQuestionBanks, _questionBanks.map((b) => b.toMap()).toList());

    // 保存题目数据
    _saveToLocalStorageKey(_keyQuestions, _questions.map((q) => q.toMap()).toList());

    // 保存用户记录数据
    _saveToLocalStorageKey(_keyUserRecords, _userRecords.map((r) => r.toMap()).toList());
  }

  // 保存下一个ID到localStorage
  void _saveNextIds() {
    _saveToLocalStorageKey(_keyNextIds, _nextIds);
  }

  // 从localStorage获取数据
  String? _getFromLocalStorage(String key) {
    // 在Web环境中，这里应该使用window.localStorage
    // 由于我们在模拟环境中，返回null
    return null;
  }

  // 保存数据到localStorage的指定键
  void _saveToLocalStorageKey(String key, dynamic value) {
    // 在Web环境中，这里应该使用window.localStorage.setItem(key, jsonEncode(value))
    // 由于我们在模拟环境中，不做实际保存
  }

  // 获取下一个ID
  int _getNextId(String tableName) {
    final id = _nextIds[tableName] ?? 1;
    _nextIds[tableName] = id + 1;
    _saveNextIds();
    return id;
  }

  @override
  Future<int> insertQuestionBank(QuestionBank bank) async {
    final id = _getNextId('question_banks');
    final newBank = bank.copyWith(id: id);
    _questionBanks.add(newBank);
    _saveToLocalStorage();
    return id;
  }

  @override
  Future<List<QuestionBank>> getQuestionBanks() async {
    return _questionBanks;
  }

  @override
  Future<int> deleteQuestionBank(int bankId) async {
    // 删除题库
    final bankIndex = _questionBanks.indexWhere((b) => b.id == bankId);
    if (bankIndex == -1) return 0;

    _questionBanks.removeAt(bankIndex);

    // 删除该题库下的所有题目
    final questionsToDelete = _questions.where((q) => q.bankId == bankId).toList();
    final questionIdsToDelete = questionsToDelete.map((q) => q.id!).toList();
    _questions.removeWhere((q) => q.bankId == bankId);

    // 删除与这些题目相关的用户记录
    _userRecords.removeWhere((r) => questionIdsToDelete.contains(r.questionId));

    _saveToLocalStorage();
    return 1;
  }

  @override
  Future<int> insertQuestion(Question question) async {
    final id = _getNextId('questions');
    final newQuestion = question.copyWith(id: id);
    _questions.add(newQuestion);
    _saveToLocalStorage();
    return id;
  }

  @override
  Future<void> batchInsertQuestions(List<Question> questions) async {
    for (var question in questions) {
      final id = _getNextId('questions');
      final newQuestion = question.copyWith(id: id);
      _questions.add(newQuestion);
    }
    _saveToLocalStorage();
  }

  @override
  Future<List<Question>> getQuestionsByBankId(int bankId) async {
    return _questions.where((q) => q.bankId == bankId).toList();
  }

  @override
  Future<int> insertOrUpdateUserRecord(UserRecord record) async {
    final existingIndex = _userRecords.indexWhere((r) => r.questionId == record.questionId);

    if (existingIndex != -1) {
      // 更新现有记录
      _userRecords[existingIndex] = record;
    } else {
      // 插入新记录
      final id = _getNextId('user_records');
      final newRecord = record.copyWith(id: id);
      _userRecords.add(newRecord);
    }

    _saveToLocalStorage();
    return 1;
  }

  @override
  Future<List<Question>> getWrongQuestions() async {
    final wrongQuestionIds = _userRecords
        .where((r) => r.isIncorrect)
        .map((r) => r.questionId)
        .toSet();

    return _questions.where((q) => wrongQuestionIds.contains(q.id)).toList();
  }

  @override
  Future<List<Question>> getMarkedQuestions() async {
    final markedQuestionIds = _userRecords
        .where((r) => r.isMarked)
        .map((r) => r.questionId)
        .toSet();

    return _questions.where((q) => markedQuestionIds.contains(q.id)).toList();
  }

  @override
  Future<int> toggleMarkQuestion(int questionId, bool isMarked) async {
    final recordIndex = _userRecords.indexWhere((r) => r.questionId == questionId);
    if (recordIndex != -1) {
      _userRecords[recordIndex] = _userRecords[recordIndex].copyWith(
        isMarked: isMarked,
      );
      _saveToLocalStorage();
      return 1;
    }
    return 0;
  }

  @override
  Future<int> markQuestionAsCorrect(int questionId) async {
    final recordIndex = _userRecords.indexWhere((r) => r.questionId == questionId);
    if (recordIndex != -1) {
      _userRecords[recordIndex] = _userRecords[recordIndex].copyWith(
        isIncorrect: false,
      );
      _saveToLocalStorage();
      return 1;
    }
    return 0;
  }

  @override
  Future<int> clearAllData() async {
    _questionBanks.clear();
    _questions.clear();
    _userRecords.clear();
    _nextIds = {
      'question_banks': 1,
      'questions': 1,
      'user_records': 1,
    };
    _saveToLocalStorage();
    _saveNextIds();
    return 1;
  }
}
