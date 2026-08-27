import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database_service_factory.dart';
import '../data/models/question.dart';
import '../data/models/question_bank.dart';

/// 编辑题库页面：长按题库进入，可修改题库名、查看/编辑/添加/删除题目
class QuestionBankEditPage extends StatefulWidget {
  final int bankId;

  const QuestionBankEditPage({Key? key, required this.bankId}) : super(key: key);

  @override
  State<QuestionBankEditPage> createState() => _QuestionBankEditPageState();
}

class _QuestionBankEditPageState extends State<QuestionBankEditPage> {
  final _bankNameController = TextEditingController();
  QuestionBank? _bank;
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final databaseService = DatabaseServiceFactory.getInstance();
      final banks = await databaseService.getQuestionBanks();
      final bank = banks.firstWhere((b) => b.id == widget.bankId);
      final questions = await databaseService.getQuestionsByBankId(widget.bankId);
      setState(() {
        _bank = bank;
        _questions = questions;
        _bankNameController.text = bank.title;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载题库失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 保存题库名称并同步题目数量
  Future<void> _saveBankName() async {
    if (_bank == null) return;
    final newTitle = _bankNameController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('题库名称不能为空')),
      );
      return;
    }
    try {
      final databaseService = DatabaseServiceFactory.getInstance();
      await databaseService.updateQuestionBank(
        _bank!.copyWith(title: newTitle, totalQuestions: _questions.length),
      );
      setState(() {
        _bank = _bank!.copyWith(title: newTitle, totalQuestions: _questions.length);
        _isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('题库名称已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  // 删除题目（含确认对话框）
  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这道题目吗？相关的学习记录也会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final databaseService = DatabaseServiceFactory.getInstance();
      await databaseService.deleteQuestion(question.id!);
      // 同步题库题目数量
      await databaseService.updateQuestionBank(
        _bank!.copyWith(totalQuestions: _questions.length - 1),
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('题目已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '编辑题库',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bank == null
              ? const Center(child: Text('题库不存在'))
              : SafeArea(
                  child: Column(
                    children: [
                      // 题库信息栏
                      _buildBankInfoBar(),
                      const SizedBox(height: 8),
                      // 题目列表
                      Expanded(child: _buildQuestionList()),
                    ],
                  ),
                ),
    );
  }

  // 题库信息栏（可编辑题库名）
  Widget _buildBankInfoBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '题库名称',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _isEditingName
                          ? TextField(
                              controller: _bankNameController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _saveBankName(),
                            )
                          : Text(
                              _bank!.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditingName ? Icons.check : Icons.edit,
                        size: 18,
                        color: const Color(0xFF4A90E2),
                      ),
                      onPressed: () {
                        if (_isEditingName) {
                          _saveBankName();
                        } else {
                          setState(() => _isEditingName = true);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '共 ${_questions.length} 题',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 题目列表（紧凑行列表 + 底部添加按钮）
  Widget _buildQuestionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _questions.length + 1,
      itemBuilder: (context, index) {
        // 最后一项为添加题目按钮
        if (index == _questions.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildAddQuestionButton(),
          );
        }
        final question = _questions[index];
        return Column(
          children: [
            _buildQuestionRow(index + 1, question),
            if (index < _questions.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],
        );
      },
    );
  }

  // 单个题目行
  Widget _buildQuestionRow(int number, Question question) {
    // 多选题答案为列表，拼接展示
    String correctAnswer;
    if (question.correctAnswer is List) {
      correctAnswer = (question.correctAnswer as List).join('');
    } else {
      correctAnswer = question.correctAnswer?.toString() ?? '';
    }
    return InkWell(
      onTap: () {
        // 跳转到题目编辑页
        context.go('/bank/${widget.bankId}/edit/question?questionId=${question.id}');
      },
      onLongPress: () => _deleteQuestion(question),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.question,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '答案 $correctAnswer',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  // 添加题目按钮（虚线边框）
  Widget _buildAddQuestionButton() {
    return GestureDetector(
      onTap: () {
        // 跳转到新增题目页（不传questionId）
        context.go('/bank/${widget.bankId}/edit/question');
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4A90E2),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20, color: Color(0xFF4A90E2)),
            SizedBox(width: 8),
            Text(
              '添加题目',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
