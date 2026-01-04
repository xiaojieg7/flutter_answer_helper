import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../data/database_helper.dart';
import '../data/models/question_bank.dart';
import '../data/models/question.dart';
import '../utils/json_parser.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QuestionBank> _questionBanks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionBanks();
  }

  // 加载所有题库
  Future<void> _loadQuestionBanks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final banks = await DatabaseHelper.instance.getQuestionBanks();
      setState(() {
        _questionBanks = banks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载题库失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 导入题库
  Future<void> _importQuestionBank() async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        return; // 用户取消选择
      }

      PlatformFile file = result.files.first;
      String filePath = file.path!;

      // 读取文件内容
      String jsonString = await File(filePath).readAsString();

      // 插入数据库
      await _insertQuestionBank(jsonString);

      // 重新加载题库
      _loadQuestionBanks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  // 插入题库到数据库
  Future<void> _insertQuestionBank(String jsonString) async {
    // 解析JSON
    final (questionBank, questions) = await JsonParser.parseJson(jsonString, 0);

    // 插入题库元数据
    int bankId = await DatabaseHelper.instance.insertQuestionBank(questionBank);

    // 更新题目所属的bankId
    List<Question> updatedQuestions = questions.map((q) {
      return Question(
        bankId: bankId,
        originalId: q.originalId,
        type: q.type,
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
      );
    }).toList();

    // 批量插入题目
    await DatabaseHelper.instance.batchInsertQuestions(updatedQuestions);
  }

  // 获取所有科目列表（去重）
  List<String> _getSubjects() {
    Set<String> subjects = {};
    for (var bank in _questionBanks) {
      subjects.add(bank.subject);
    }
    return subjects.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('答题助手'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questionBanks.isEmpty
              ? const Center(
                  child: Text('还没有导入题库，点击右下角按钮导入'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _getSubjects().length,
                  itemBuilder: (context, index) {
                    String subject = _getSubjects()[index];
                    // 获取该科目下的题库数量
                    int bankCount = _questionBanks.where((bank) => bank.subject == subject).length;
                    
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          // 跳转到科目详情页
                          context.go('/subject/$subject');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject,
                                    style: const TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    '共 $bankCount 个题库',
                                    style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importQuestionBank,
        tooltip: '导入题库',
        child: const Icon(Icons.add),
      ),
    );
  }
}
