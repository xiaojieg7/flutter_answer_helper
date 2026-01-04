import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/question_bank.dart';
import 'models/question.dart';
import 'models/user_record.dart';

class DatabaseHelper {
  static const _databaseName = 'answer_helper.db';
  static const _databaseVersion = 1;

  // 表名
  static const tableQuestionBanks = 'question_banks';
  static const tableQuestions = 'questions';
  static const tableUserRecords = 'user_records';

  // 单例模式
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 创建题库元数据表
    await db.execute('''
      CREATE TABLE $tableQuestionBanks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        score_mode TEXT NOT NULL DEFAULT 'average'
      )
    ''');

    // 创建题目表
    await db.execute('''
      CREATE TABLE $tableQuestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_id INTEGER NOT NULL,
        original_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (bank_id) REFERENCES $tableQuestionBanks (id)
      )
    ''');

    // 创建用户学习记录表
    await db.execute('''
      CREATE TABLE $tableUserRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        is_incorrect INTEGER DEFAULT 0,
        is_marked INTEGER DEFAULT 0,
        last_attempted TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id)
      )
    ''');
  }

  // 插入题库
  Future<int> insertQuestionBank(QuestionBank bank) async {
    Database db = await instance.database;
    // 创建一个不包含id字段的映射，让SQLite自动生成id
    final Map<String, dynamic> bankMap = bank.toMap();
    bankMap.remove('id'); // 移除id字段，让SQLite自动生成
    return await db.insert(tableQuestionBanks, bankMap);
  }

  // 获取所有题库
  Future<List<QuestionBank>> getQuestionBanks() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(tableQuestionBanks);
    return List.generate(maps.length, (i) {
      return QuestionBank.fromMap(maps[i]);
    });
  }

  // 插入题目
  Future<int> insertQuestion(Question question) async {
    Database db = await instance.database;
    return await db.insert(tableQuestions, question.toMap());
  }

  // 批量插入题目
  Future<void> batchInsertQuestions(List<Question> questions) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var question in questions) {
      batch.insert(tableQuestions, question.toMap());
    }
    await batch.commit();
  }

  // 根据bankId获取题目列表
  Future<List<Question>> getQuestionsByBankId(int bankId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableQuestions,
      where: 'bank_id = ?',
      whereArgs: [bankId],
    );
    return List.generate(maps.length, (i) {
      return Question.fromMap(maps[i]);
    });
  }

  // 插入或更新用户学习记录
  Future<int> insertOrUpdateUserRecord(UserRecord record) async {
    Database db = await instance.database;
    // 检查是否已存在记录
    List<Map<String, dynamic>> existing = await db.query(
      tableUserRecords,
      where: 'question_id = ?',
      whereArgs: [record.questionId],
    );

    if (existing.isNotEmpty) {
      // 更新现有记录
      return await db.update(
        tableUserRecords,
        record.toMap(),
        where: 'question_id = ?',
        whereArgs: [record.questionId],
      );
    } else {
      // 插入新记录
      return await db.insert(tableUserRecords, record.toMap());
    }
  }

  // 获取错题列表
  Future<List<Question>> getWrongQuestions() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT q.* FROM $tableQuestions q
      JOIN $tableUserRecords ur ON q.id = ur.question_id
      WHERE ur.is_incorrect = 1
    ''');
    return List.generate(maps.length, (i) {
      return Question.fromMap(maps[i]);
    });
  }

  // 获取收藏题目列表
  Future<List<Question>> getMarkedQuestions() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT q.* FROM $tableQuestions q
      JOIN $tableUserRecords ur ON q.id = ur.question_id
      WHERE ur.is_marked = 1
    ''');
    return List.generate(maps.length, (i) {
      return Question.fromMap(maps[i]);
    });
  }

  // 标记或取消标记题目
  Future<int> toggleMarkQuestion(int questionId, bool isMarked) async {
    Database db = await instance.database;
    return await db.update(
      tableUserRecords,
      {'is_marked': isMarked ? 1 : 0},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // 将错题标记为已掌握
  Future<int> markQuestionAsCorrect(int questionId) async {
    Database db = await instance.database;
    return await db.update(
      tableUserRecords,
      {'is_incorrect': 0},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // 清除所有数据
  Future<int> clearAllData() async {
    Database db = await instance.database;
    await db.delete(tableUserRecords);
    await db.delete(tableQuestions);
    return await db.delete(tableQuestionBanks);
  }
}
