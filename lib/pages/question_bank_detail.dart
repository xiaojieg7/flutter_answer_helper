import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database_helper.dart';
import '../data/models/question_bank.dart';
import '../data/models/question.dart';

class QuestionBankDetailPage extends StatefulWidget {
  final int bankId;

  const QuestionBankDetailPage({Key? key, required this.bankId}) : super(key: key);

  @override
  State<QuestionBankDetailPage> createState() => _QuestionBankDetailPageState();
}

class _QuestionBankDetailPageState extends State<QuestionBankDetailPage> {
  QuestionBank? _questionBank;
  List<Question>? _questions;
  bool _isLoading = true;
  bool _shuffle = false;

  @override
  void initState() {
    super.initState();
    _loadQuestionBankDetail();
  }

  // 加载题库详情
  Future<void> _loadQuestionBankDetail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 获取题库所有题库，找到对应的题库
      final banks = await DatabaseHelper.instance.getQuestionBanks();
      _questionBank = banks.firstWhere((bank) => bank.id == widget.bankId);

      // 获取该题库下的所有题目
      _questions = await DatabaseHelper.instance.getQuestionsByBankId(widget.bankId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载题库详情失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 开始答题
  void _startAnswering(String mode) {
    if (_questionBank == null || _questions == null || _questions!.isEmpty) {
      return;
    }

    // 构建带有查询参数的URL，使用正确的嵌套路由路径
    String url = '/bank/${widget.bankId}/answer?mode=$mode&shuffle=${_shuffle.toString()}';
    // 跳转到答题页
    context.go(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _questionBank != null ? Text(_questionBank!.title) : const Text('题库详情'),
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questionBank == null
              ? const Center(child: Text('题库不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 题库信息卡片
                      Card(
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _questionBank!.title,
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Row(
                                children: [
                                  const Text('科目: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_questionBank!.subject),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('难度: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_questionBank!.difficulty),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('题目数量: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_questionBank!.totalQuestions.toString()),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('创建日期: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_questionBank!.createdDate),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // 模式选择
                      const Text(
                        '选择学习模式',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 背题模式按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startAnswering('study'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16.0),
                            textStyle: const TextStyle(fontSize: 18.0),
                          ),
                          child: const Text('背题模式'),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // 刷题模式按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startAnswering('practice'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16.0),
                            textStyle: const TextStyle(fontSize: 18.0),
                          ),
                          child: const Text('刷题模式'),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // 排序选项
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '乱序答题',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _shuffle,
                            onChanged: (value) {
                              setState(() {
                                _shuffle = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
