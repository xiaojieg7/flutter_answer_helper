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
  
  // 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(int bankId, String bankTitle) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 用户必须点击按钮才能关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('您确定要删除题库 "$bankTitle" 吗？'),
                const Text('删除后将无法恢复，包含该题库下的所有题目和学习记录。'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('删除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                // 关闭对话框
                Navigator.of(context).pop();
                
                // 执行删除操作
                try {
                  await DatabaseHelper.instance.deleteQuestionBank(bankId);
                  
                  // 重新加载题库列表
                  await _loadSubjectQuestionBanks();
                  
                  // 显示删除成功提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('题库删除成功')),
                  );
                } catch (e) {
                  // 显示删除失败提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
              : SafeArea(
                  child: GridView.builder(
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
                        onLongPress: () {
                          // 长按删除题库
                          _showDeleteConfirmDialog(bank.id!, bank.title);
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(14.0),
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
                                const SizedBox(height: 6.0),
                                Text(
                                  '科目: ${bank.subject}',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  '难度: ${bank.difficulty}',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  '题目数量: ${bank.totalQuestions}',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                const SizedBox(height: 6.0),
                                const Spacer(),
                                SizedBox(
                                  height: 6.0,
                                  child: LinearProgressIndicator(
                                    value: 0.0, // 这里可以添加实际的学习进度
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                const Text(
                                  '学习进度: 0%',
                                  style: const TextStyle(
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
              ),
    );
  }
}
