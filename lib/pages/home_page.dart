import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../data/database_service_factory.dart';
import '../data/models/question_bank.dart';
import '../data/models/question.dart';
import '../utils/json_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

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
      final databaseService = DatabaseServiceFactory.getInstance();
      final banks = await databaseService.getQuestionBanks();
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
      String jsonString;

      // 跨平台文件读取
      if (kIsWeb) {
        // Web平台：使用bytes属性并确保UTF-8编码
        if (file.bytes != null) {
          jsonString = utf8.decode(file.bytes!);
        } else {
          throw Exception('无法读取文件内容');
        }
      } else {
        // 移动平台：使用path属性并指定UTF-8编码
        String filePath = file.path!;
        jsonString = await File(filePath).readAsString(encoding: utf8);
      }

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

    // 获取数据库服务实例
    final databaseService = DatabaseServiceFactory.getInstance();

    // 插入题库元数据
    int bankId = await databaseService.insertQuestionBank(questionBank);

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
    await databaseService.batchInsertQuestions(updatedQuestions);
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
      backgroundColor:
          AppColors.adaptive(context, AppColors.pageBg, const Color(0xFF121212)),
      appBar: AppBar(
        title: const Text('答题助手'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          // 骨架屏：科目卡形状的呼吸占位
          ? ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      height: 96,
                      child: SkeletonBox(radius: 16),
                    ),
                  ),
              ],
            )
          : _questionBanks.isEmpty
              ? EmptyState(
                  icon: Icons.quiz_outlined,
                  title: '还没有题库',
                  message: '导入 JSON 格式的题库文件\n即可开始你的学习之旅',
                  actionLabel: '导入题库',
                  onAction: _importQuestionBank,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _getSubjects().length,
                  itemBuilder: (context, index) {
                    String subject = _getSubjects()[index];
                    int bankCount = _questionBanks.where((bank) => bank.subject == subject).length;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gradientStart.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          context.go('/subject/$subject');
                        },
                        borderRadius: BorderRadius.circular(16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      '共 $bankCount 个题库',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importQuestionBank,
        tooltip: '导入题库',
        icon: const Icon(Icons.add),
        label: const Text('导入题库'),
      ),
    );
  }
}
