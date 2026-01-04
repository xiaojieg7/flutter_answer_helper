import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models/question.dart';

class WrongQuestionsPage extends StatefulWidget {
  const WrongQuestionsPage({Key? key}) : super(key: key);

  @override
  State<WrongQuestionsPage> createState() => _WrongQuestionsPageState();
}

class _WrongQuestionsPageState extends State<WrongQuestionsPage> {
  List<Question> _wrongQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWrongQuestions();
  }

  // 加载错题列表
  Future<void> _loadWrongQuestions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _wrongQuestions = await DatabaseHelper.instance.getWrongQuestions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载错题失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 标记错题为已掌握
  void _markAsCorrect(int questionId) {
    DatabaseHelper.instance.markQuestionAsCorrect(questionId);
    _loadWrongQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wrongQuestions.isEmpty
              ? const Center(child: Text('还没有错题'))
              : ListView.builder(
                  itemCount: _wrongQuestions.length,
                  itemBuilder: (context, index) {
                    Question question = _wrongQuestions[index];
                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12.0),
                            // 显示选项
                            Column(
                              children: question.options.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                                  child: Text('${entry.key}. ${entry.value}'),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12.0),
                            // 显示正确答案
                            Text(
                              '正确答案: ${question.correctAnswer}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            // 显示解析
                            Text(
                              '解析: ${question.explanation}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                            const SizedBox(height: 12.0),
                            // 已掌握按钮
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => _markAsCorrect(question.id!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                ),
                                child: const Text('已掌握'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
