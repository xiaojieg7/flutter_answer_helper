import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database_helper.dart';
import '../data/models/question_bank.dart';

class SubjectDetailPage extends StatefulWidget {
  final String subject;

  const SubjectDetailPage({Key? key, required this.subject}) : super(key: key);

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  List<QuestionBank> _subjectQuestionBanks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectQuestionBanks();
  }

  // 加载该科目下的所有题库
  Future<void> _loadSubjectQuestionBanks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allBanks = await DatabaseHelper.instance.getQuestionBanks();
      setState(() {
        _subjectQuestionBanks = allBanks.where((bank) => bank.subject == widget.subject).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject}题库'),
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjectQuestionBanks.isEmpty
              ? const Center(child: Text('该科目下还没有题库'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _subjectQuestionBanks.length,
                  itemBuilder: (context, index) {
                    QuestionBank bank = _subjectQuestionBanks[index];
                    return Card(
                      elevation: 4.0,
                      child: InkWell(
                        onTap: () {
                          // 跳转到题库详情页
                          context.go('/bank/${bank.id}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bank.title,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '科目: ${bank.subject}',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '难度: ${bank.difficulty}',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '题目数量: ${bank.totalQuestions}',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              const Spacer(),
                              LinearProgressIndicator(
                                value: 0.0, // 这里可以添加实际的学习进度
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              const SizedBox(height: 4.0),
                              const Text(
                                '学习进度: 0%',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
