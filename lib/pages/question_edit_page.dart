import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/database_service_factory.dart';
import '../data/models/question.dart';
import '../widgets/image_viewer.dart';

/// 题目编辑页面：编辑/新增单道题目，支持题干、选项、答案、解析和单张配图
class QuestionEditPage extends StatefulWidget {
  final int bankId;
  final int? questionId; // 为空时表示新增题目

  const QuestionEditPage({
    Key? key,
    required this.bankId,
    this.questionId,
  }) : super(key: key);

  @override
  State<QuestionEditPage> createState() => _QuestionEditPageState();
}

class _QuestionEditPageState extends State<QuestionEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _stemController = TextEditingController();
  final _analysisController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  List<String> _optionKeys = [];
  String _questionType = 'single'; // single: 单选, multiple: 多选
  String _correctAnswer = ''; // 单选：正确选项字母
  final Set<String> _correctAnswers = {}; // 多选：正确选项字母集合
  String? _imageBase64;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _originalId;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _stemController.dispose();
    _analysisController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() => _isLoading = true);
    try {
      if (widget.questionId != null) {
        // 编辑已有题目
        final databaseService = DatabaseServiceFactory.getInstance();
        final questions = await databaseService.getQuestionsByBankId(widget.bankId);
        final question = questions.firstWhere((q) => q.id == widget.questionId);
        _stemController.text = question.question;
        _analysisController.text = question.explanation;
        _imageBase64 = question.imageBase64;
        _originalId = question.originalId;
        _questionType = question.type == 'multiple' ? 'multiple' : 'single';
        _optionKeys = question.options.keys.toList();
        // 根据题型加载正确答案
        if (_questionType == 'multiple') {
          if (question.correctAnswer is List) {
            _correctAnswers.addAll(
              List<String>.from(question.correctAnswer),
            );
          }
        } else {
          _correctAnswer = question.correctAnswer?.toString() ?? '';
        }
        for (final key in _optionKeys) {
          _optionControllers.add(
            TextEditingController(text: question.options[key]),
          );
        }
      } else {
        // 新增题目：默认A-D四个选项
        _optionKeys = ['A', 'B', 'C', 'D'];
        for (final _ in _optionKeys) {
          _optionControllers.add(TextEditingController());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载题目失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 选择配图（相册/文件），统一转为base64存入数据库
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // 统一读取文件字节，转base64存储
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final base64Str = base64Encode(bytes);
      setState(() => _imageBase64 = base64Str);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  // 移除配图
  void _removeImage() {
    setState(() => _imageBase64 = null);
  }

  // 添加选项
  void _addOption() {
    if (_optionKeys.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多支持8个选项')),
      );
      return;
    }
    // 生成下一个选项字母
    final nextKey = String.fromCharCode(65 + _optionKeys.length);
    setState(() {
      _optionKeys.add(nextKey);
      _optionControllers.add(TextEditingController());
    });
  }

  // 删除选项（至少保留2个）
  void _removeOption(int index) {
    if (_optionKeys.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要保留2个选项')),
      );
      return;
    }
    final removedKey = _optionKeys[index];
    setState(() {
      _optionKeys.removeAt(index);
      _optionControllers.removeAt(index).dispose();
      // 重新排列选项字母
      for (var i = 0; i < _optionKeys.length; i++) {
        _optionKeys[i] = String.fromCharCode(65 + i);
      }
      // 清理被删除选项的正确答案状态
      _correctAnswers.remove(removedKey);
      if (_correctAnswer == removedKey) {
        _correctAnswer = '';
      }
    });
  }

  // 切换题型（单选/多选），清空已设置的答案
  void _switchQuestionType(String type) {
    if (type == _questionType) return;
    setState(() {
      _questionType = type;
      _correctAnswer = '';
      _correctAnswers.clear();
    });
  }

  // 点击选项图标：设置/取消正确答案
  void _toggleCorrectAnswer(String key) {
    setState(() {
      if (_questionType == 'multiple') {
        // 多选：方形框，可多选
        if (_correctAnswers.contains(key)) {
          _correctAnswers.remove(key);
        } else {
          _correctAnswers.add(key);
        }
      } else {
        // 单选：圆点，只能选一个
        _correctAnswer = key;
      }
    });
  }

  // 保存题目
  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // 校验正确答案
    if (_questionType == 'multiple') {
      if (_correctAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请勾选至少一个正确答案')),
        );
        return;
      }
    } else {
      if (_correctAnswer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请点击圆点设置正确答案')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final databaseService = DatabaseServiceFactory.getInstance();

      // 构建选项映射
      final options = <String, String>{};
      for (var i = 0; i < _optionKeys.length; i++) {
        final text = _optionControllers[i].text.trim();
        if (text.isNotEmpty) {
          options[_optionKeys[i]] = text;
        }
      }

      // 根据题型设置正确答案：多选存列表，单选存字符串
      final dynamic correctAnswer = _questionType == 'multiple'
          ? _correctAnswers.toList()
          : _correctAnswer;

      final question = Question(
        id: widget.questionId,
        bankId: widget.bankId,
        originalId: _originalId ?? widget.questionId ?? 0,
        type: _questionType, // single: 单选, multiple: 多选
        question: _stemController.text.trim(),
        options: options,
        correctAnswer: correctAnswer,
        explanation: _analysisController.text.trim(),
        imageBase64: _imageBase64,
      );

      if (widget.questionId != null) {
        // 更新题目
        await databaseService.updateQuestion(question);
      } else {
        // 新增题目
        await databaseService.insertQuestion(question);
        // 同步题库题目数量
        final banks = await databaseService.getQuestionBanks();
        final bank = banks.firstWhere((b) => b.id == widget.bankId);
        final questions = await databaseService.getQuestionsByBankId(widget.bankId);
        await databaseService.updateQuestionBank(
          bank.copyWith(totalQuestions: questions.length),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.questionId != null ? '题目已更新' : '题目已添加')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 删除题目
  Future<void> _deleteQuestion() async {
    if (widget.questionId == null) return;

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
      await databaseService.deleteQuestion(widget.questionId!);
      // 同步题库题目数量
      final banks = await databaseService.getQuestionBanks();
      final bank = banks.firstWhere((b) => b.id == widget.bankId);
      final questions = await databaseService.getQuestionsByBankId(widget.bankId);
      await databaseService.updateQuestionBank(
        bank.copyWith(totalQuestions: questions.length),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('题目已删除')),
        );
        context.pop();
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
        title: Text(
          widget.questionId != null ? '编辑题目' : '新增题目',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF4A90E2)),
            onPressed: _isSaving ? null : _saveQuestion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 题型切换（单选/多选）
                  Row(
                    children: [
                      const Text(
                        '题型：',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('单选'),
                        selected: _questionType == 'single',
                        selectedColor: const Color(0xFFE3F2FD),
                        labelStyle: TextStyle(
                          color: _questionType == 'single'
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFF757575),
                          fontWeight: _questionType == 'single'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => _switchQuestionType('single'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('多选'),
                        selected: _questionType == 'multiple',
                        selectedColor: const Color(0xFFE3F2FD),
                        labelStyle: TextStyle(
                          color: _questionType == 'multiple'
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFF757575),
                          fontWeight: _questionType == 'multiple'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => _switchQuestionType('multiple'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 题干
                  const Text(
                    '题干',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stemController,
                      maxLines: 4,
                      decoration: _inputDecoration('请输入题干'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '题干不能为空';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 配图区域（单张）
                    const Text(
                      '配图（单张）',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildImageArea(),
                    const SizedBox(height: 16),

                    // 选项
                    Text(
                      _questionType == 'multiple'
                          ? '选项（点击方框设置正确答案，可多选）'
                          : '选项（点击圆点设置正确答案）',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildOptionFields(),
                    // 添加选项
                    TextButton(
                      onPressed: _addOption,
                      child: const Text(
                        '+ 添加选项',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 解析
                    const Text(
                      '解析',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _analysisController,
                      maxLines: 3,
                      decoration: _inputDecoration('请输入解析'),
                    ),
                    const SizedBox(height: 24),

                    // 删除题目按钮（仅编辑模式）
                    if (widget.questionId != null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _deleteQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            foregroundColor: const Color(0xFFF44336),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '删除题目',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // 输入框统一样式
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // 配图区域：已有配图缩略图 + 添加配图按钮
  Widget _buildImageArea() {
    return Row(
      children: [
        // 已有配图的缩略图（点击放大查看）
        if (_imageBase64 != null) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => ImageViewer.show(context, _imageBase64!),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImageWidget(_imageBase64!),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
        // 添加配图按钮（已有配图时隐藏）
        if (_imageBase64 == null)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A90E2)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 28,
                    color: Color(0xFF4A90E2),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '添加配图',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 根据base64字符串解码并展示图片
  Widget _buildImageWidget(String base64Str) {
    try {
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          color: Color(0xFF9E9E9E),
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.broken_image,
        color: Color(0xFF9E9E9E),
      );
    }
  }

  // 构建所有选项输入行
  List<Widget> _buildOptionFields() {
    final widgets = <Widget>[];
    for (var i = 0; i < _optionKeys.length; i++) {
      final key = _optionKeys[i];
      // 单选：圆点单选；多选：方形框可多选
      final isCorrect = _questionType == 'multiple'
          ? _correctAnswers.contains(key)
          : _correctAnswer == key;
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isCorrect
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: isCorrect
                ? Border.all(color: const Color(0xFF4A90E2), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // 点击图标设置正确答案：单选圆点 / 多选方框
              GestureDetector(
                onTap: () => _toggleCorrectAnswer(key),
                child: Icon(
                  _questionType == 'multiple'
                      ? (isCorrect
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (isCorrect
                          ? Icons.check_circle
                          : Icons.circle_outlined),
                  size: 20,
                  color: isCorrect ? const Color(0xFF4A90E2) : const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$key.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  controller: _optionControllers[i],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '请输入选项内容',
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '选项内容不能为空';
                    }
                    return null;
                  },
                ),
              ),
              // 删除选项按钮
              GestureDetector(
                onTap: () => _removeOption(i),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}
