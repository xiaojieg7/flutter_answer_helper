import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/database_service_factory.dart';
import '../data/models/question.dart';
import '../data/models/user_record.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/image_viewer.dart';

/// 选项卡视觉状态
enum _OptionVisualState { normal, selected, correct, wrong }

/// 答题页面 - 支持刷题和背题两种模式
///
/// 刷题模式(practice)：作答 -> 提交答案 -> 反馈（正确绿/错误红）-> 下一题
/// 背题模式(study)：直接显示答案和解析，仅浏览记忆
class AnswerPage extends StatefulWidget {
  final int bankId;
  final String mode;
  final bool shuffle;

  const AnswerPage({
    super.key,
    required this.bankId,
    required this.mode,
    this.shuffle = false,
  });

  @override
  State<AnswerPage> createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> {
  late final _databaseService = DatabaseServiceFactory.getInstance();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  dynamic _userAnswer;
  bool _isAnswered = false;
  bool _showResult = false;

  // 本次刷题会话的对错记录（用于结果页统计）
  final List<bool> _sessionResults = [];

  // 收藏状态缓存（questionId -> future），避免重复查询与重建闪烁
  final Map<int, Future<bool>> _markedFutures = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    try {
      var questions = await _databaseService.getQuestionsByBankId(widget.bankId);

      if (widget.shuffle) {
        questions..shuffle();
      }

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
        _currentQuestionIndex = 0;
        _userAnswer = null;
        _isAnswered = false;
        _showResult = false;
        _sessionResults.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载题目失败: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Question get _currentQuestion => _questions[_currentQuestionIndex];

  Future<bool> _isMarked(int questionId) {
    return _markedFutures.putIfAbsent(questionId, () async {
      final record = await _databaseService.getUserRecord(questionId);
      return record?.isMarked ?? false;
    });
  }

  void _toggleMark() async {
    try {
      final questionId = _currentQuestion.id!;
      final current = await _isMarked(questionId);
      final newValue = !current;
      // 先更新缓存保证 UI 即时响应，再落库
      _markedFutures[questionId] = Future.value(newValue);
      await _databaseService.toggleMarkQuestion(questionId, newValue);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记题目失败: $e')),
        );
      }
    }
  }

  // 提交当前答案
  Future<void> _submitAnswer() async {
    if (!_hasSelection()) return;

    final isCorrect = _checkAnswer();

    try {
      await _databaseService.insertOrUpdateUserRecord(UserRecord(
        questionId: _currentQuestion.id!,
        userAnswer: _userAnswer,
        isIncorrect: !isCorrect,
        lastAttempted: DateTime.now().toIso8601String(),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记录答题结果失败: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isAnswered = true;
        _sessionResults.add(isCorrect);
      });
    }
  }

  // 检查答案是否正确
  bool _checkAnswer() {
    final correct = _currentQuestion.correctAnswer;
    switch (_currentQuestion.type) {
      case 'multiple':
        if (_userAnswer is! List || correct is! List) return false;
        final correctKeys =
            Set<String>.from(correct.map((e) => e.toString()));
        final userKeys =
            Set<String>.from((_userAnswer as List).map((e) => e.toString()));
        return correctKeys.length == userKeys.length &&
            correctKeys.containsAll(userKeys);
      case 'true_false':
        // 答案可能是 bool 或字符串 'true'/'false'，统一归一化后比较
        final bool correctBool;
        if (correct is bool) {
          correctBool = correct;
        } else {
          correctBool = correct?.toString().toLowerCase() == 'true';
        }
        return _userAnswer == correctBool;
      default:
        // 单选/填空/简答：统一按字符串宽松比较
        return _userAnswer?.toString().trim().toLowerCase() ==
            correct?.toString().trim().toLowerCase();
    }
  }

  /// 当前是否已作出有效选择（决定"提交答案"按钮是否可点）
  bool _hasSelection() {
    final type = _currentQuestion.type;
    if (type == 'multiple') {
      return _userAnswer is List && (_userAnswer as List).isNotEmpty;
    }
    if (type == 'fill_in_blank' || type == 'short_answer') {
      return _userAnswer != null && _userAnswer.toString().trim().isNotEmpty;
    }
    return _userAnswer != null;
  }

  /// 移动到下一题，若已是最后一题则进入结果视图
  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = null;
        _isAnswered = false;
      });
    } else {
      setState(() => _showResult = true);
    }
  }

  /// 返回上一题
  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _userAnswer = null;
        _isAnswered = false;
      });
    }
  }

  /// 重启本轮答题
  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswer = null;
      _isAnswered = false;
      _showResult = false;
      _sessionResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题')),
        body: const EmptyState(
          icon: Icons.quiz_outlined,
          title: '没有题目',
          message: '这个题库还没有题目\n去编辑题库添加题目或导入新题库吧',
        ),
      );
    }

    // 结果视图
    if (_showResult) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题结束')),
        body: _buildResultView(),
      );
    }

    final isStudyMode = widget.mode == 'study';

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudyMode ? '背题模式' : '刷题模式'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.adaptive(
                  context, AppColors.textPrimary, Colors.white),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重新开始'),
                  content: const Text('确定要清空当前进度，重新开始答题吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restartQuiz();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            minHeight: 4,
            backgroundColor: AppColors.adaptive(
                context, AppColors.border, const Color(0xFF2E2E2E)),
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionHeader(),
                  _buildQuestionText(_currentQuestion),
                  _buildQuestionImage(_currentQuestion),
                  const SizedBox(height: 24),
                  ..._buildOptions(),

                  // 解析卡
                  const SizedBox(height: 24),
                  _buildAnswerAndExplanation(),
                ],
              ),
            ),
          ),

          // 底部按钮区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(child: _buildBottomButtons()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '${_currentQuestionIndex + 1}/${_questions.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.adaptive(
                    context, AppColors.textTertiary, Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.adaptive(
                    context, AppColors.selectedBg, const Color(0xFF17334D)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _typeLabel(_currentQuestion.type),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.adaptive(
                      context, AppColors.primary, const Color(0xFF64B5F6)),
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _toggleMark,
          child: FutureBuilder<bool>(
            future: _isMarked(_currentQuestion.id!),
            builder: (context, snapshot) {
              final isMarked = snapshot.data ?? false;
              return Icon(
                isMarked ? Icons.star : Icons.star_border,
                size: 28,
                color: AppColors.starAmber,
              );
            },
          ),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'single':
        return '单选题';
      case 'multiple':
        return '多选题';
      case 'true_false':
        return '判断题';
      case 'fill_in_blank':
        return '填空题';
      case 'short_answer':
        return '简答题';
      default:
        return type;
    }
  }

  Widget _buildQuestionText(Question question) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: 18,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: AppColors.adaptive(
              context, AppColors.textPrimary, const Color(0xFFE1E1E1)),
        ),
      ),
    );
  }

  Widget _buildQuestionImage(Question question) {
    final imageBase64 = question.imageBase64;
    if (imageBase64 == null || imageBase64.isEmpty) {
      return const SizedBox.shrink();
    }
    Uint8List bytes;
    try {
      final b64 =
          imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
      bytes = base64Decode(b64);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => ImageViewer.show(context, imageBase64),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptions() {
    final question = _currentQuestion;
    switch (question.type) {
      case 'single':
        return _buildSingleChoiceOptions(question);
      case 'multiple':
        return _buildMultipleChoiceOptions(question);
      case 'true_false':
        return _buildTrueFalseOptions(question);
      case 'fill_in_blank':
        return _buildTextInputOptions(question);
      case 'short_answer':
        return _buildTextInputOptions(question, multiline: true);
      default:
        return [
          Text(
            '不支持的题型: ${question.type}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        ];
    }
  }

  bool get _canInteract => widget.mode == 'practice' && !_isAnswered;

  List<Widget> _buildSingleChoiceOptions(Question question) {
    final isPracticeFeedback = widget.mode == 'practice' && _isAnswered;
    final correctKey = question.correctAnswer?.toString();

    // 背题模式预选中正确答案；刷题模式用当前所选
    final effectiveSelectedKey = _userAnswer?.toString() ??
        (widget.mode == 'study' ? question.correctAnswer?.toString() : null);

    return List.generate(question.options.entries.length, (index) {
      final entry = question.options.entries.elementAt(index);
      final key = entry.key;

      _OptionVisualState state;
      VoidCallback? onTap;

      if (isPracticeFeedback) {
        // 提交后反馈：正确的标绿，选错的标红，其余保持普通
        if (key == correctKey) {
          state = _OptionVisualState.correct;
        } else if (_userAnswer?.toString() == key) {
          state = _OptionVisualState.wrong;
        } else {
          state = _OptionVisualState.normal;
        }
      } else {
        state = effectiveSelectedKey == key
            ? _OptionVisualState.selected
            : _OptionVisualState.normal;
        onTap = _canInteract ? () => setState(() => _userAnswer = key) : null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _OptionCard(
          text: '${entry.key}. ${entry.value}',
          multiSelect: false,
          visualState: state,
          dimmed:
              !isPracticeFeedback && state == _OptionVisualState.normal && !_canInteract,
          onTap: onTap,
        ),
      );
    });
  }

  List<Widget> _buildMultipleChoiceOptions(Question question) {
    final isPracticeFeedback = widget.mode == 'practice' && _isAnswered;

    Set<String> selectedKeys = {};
    if (widget.mode == 'study' && _userAnswer == null) {
      // 背题模式：预选中正确答案
      if (question.correctAnswer is List) {
        selectedKeys = Set<String>.from(
            question.correctAnswer.map((e) => e.toString()));
      }
    } else if (_userAnswer is List) {
      selectedKeys = Set<String>.from((_userAnswer as List).cast<String>());
    }

    Set<String> correctKeys = {};
    if (question.correctAnswer is List) {
      correctKeys =
          Set<String>.from(question.correctAnswer.map((e) => e.toString()));
    }

    return List.generate(question.options.entries.length, (index) {
      final entry = question.options.entries.elementAt(index);
      final key = entry.key;

      _OptionVisualState state;
      VoidCallback? onTap;

      if (isPracticeFeedback) {
        // 提交后反馈：正确的标绿，错选的标红，漏选的正确项也标绿提示
        if (correctKeys.contains(key)) {
          state = _OptionVisualState.correct;
        } else if (selectedKeys.contains(key)) {
          state = _OptionVisualState.wrong;
        } else {
          state = _OptionVisualState.normal;
        }
      } else {
        state = selectedKeys.contains(key)
            ? _OptionVisualState.selected
            : _OptionVisualState.normal;
        onTap = _canInteract
            ? () {
                setState(() {
                  final current = _userAnswer is List
                      ? List<String>.from(_userAnswer as List)
                      : <String>[];
                  if (current.contains(key)) {
                    current.remove(key);
                  } else {
                    current.add(key);
                  }
                  _userAnswer = current;
                });
              }
            : null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _OptionCard(
          text: '${entry.key}. ${entry.value}',
          multiSelect: true, // 多选题使用方形框
          visualState: state,
          dimmed:
              !isPracticeFeedback && state == _OptionVisualState.normal && !_canInteract,
          onTap: onTap,
        ),
      );
    });
  }

  List<Widget> _buildTrueFalseOptions(Question question) {
    final isPracticeFeedback = widget.mode == 'practice' && _isAnswered;

    // 归一化正确答案为 bool
    final correct = question.correctAnswer;
    final bool correctBool = correct is bool
        ? correct
        : correct?.toString().toLowerCase() == 'true';

    // 背题模式预选正确答案；刷题模式用当前所选
    final bool? effectiveSelected =
        _userAnswer is bool ? _userAnswer as bool? : null;

    return List.generate(2, (index) {
      final value = index == 0;
      final label = index == 0 ? '正确' : '错误';

      _OptionVisualState state;
      VoidCallback? onTap;

      if (isPracticeFeedback) {
        if (value == correctBool) {
          state = _OptionVisualState.correct;
        } else if (_userAnswer == value) {
          state = _OptionVisualState.wrong;
        } else {
          state = _OptionVisualState.normal;
        }
      } else {
        state = (effectiveSelected ?? (widget.mode == 'study' ? correctBool : null)) ==
                value
            ? _OptionVisualState.selected
            : _OptionVisualState.normal;
        onTap =
            _canInteract ? () => setState(() => _userAnswer = value) : null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _OptionCard(
          text: label,
          multiSelect: false,
          visualState: state,
          dimmed:
              !isPracticeFeedback && state == _OptionVisualState.normal && !_canInteract,
          onTap: onTap,
        ),
      );
    });
  }

  List<Widget> _buildTextInputOptions(Question question,
      {bool multiline = false}) {
    final controller = TextEditingController(text: _userAnswer?.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      TextField(
        controller: controller,
        maxLines: multiline ? 4 : 1,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        readOnly: !_canInteract,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.adaptive(
              context, AppColors.textPrimary, const Color(0xFFE1E1E1)),
        ),
        decoration: InputDecoration(
          hintText: '请输入你的答案',
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.adaptive(
                context, AppColors.textQuaternary, Colors.grey.shade600),
          ),
          filled: true,
          fillColor: AppColors.adaptive(
              context,
              !_canInteract ? AppColors.cardPlainBg : Colors.white,
              !_canInteract ? const Color(0xFF252525) : const Color(0xFF1E1E1E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF3A3A3A) : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF3A3A3A) : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() => _userAnswer = value),
      )
    ];
  }

  /// 答案解析卡（对齐设计稿：#F5F5F5底、圆角12、"答案解析"绿色标签）
  Widget _buildAnswerAndExplanation() {
    final question = _currentQuestion;
    // 只在背题模式，或者刷题模式下已提交答案时展示
    final showExplanation =
        widget.mode == 'study' || (widget.mode == 'practice' && _isAnswered);
    if (!showExplanation) {
      return const SizedBox.shrink();
    }

    final greenLabel = AppColors.adaptive(
        context, AppColors.successGreen, const Color(0xFF81C784));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptive(
            context, AppColors.cardPlainBg, const Color(0xFF252525)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 答案区域
          Text(
            '答案',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.adaptive(
                  context, AppColors.textSecondary, Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _answerText(question),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.adaptive(
                  context, AppColors.textPrimary, const Color(0xFFE1E1E1)),
            ),
          ),

          const SizedBox(height: 16),

          // 解析区域
          Text(
            '答案解析',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: greenLabel,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question.explanation.isEmpty ? '暂无解析' : question.explanation,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.adaptive(
                  context, AppColors.textSecondary, Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  String _answerText(Question question) {
    final answer = question.correctAnswer;
    if (question.type == 'true_false') {
      final bool b = answer is bool
          ? answer
          : answer?.toString().toLowerCase() == 'true';
      return b ? '正确' : '错误';
    }
    if (answer is List) {
      return answer.map((e) => e.toString()).join('、');
    }
    return answer?.toString() ?? '-';
  }

  /// 底部按钮区：
  /// - 刷题模式未提交：全宽「提交答案」按钮（多选题尤其需要显式提交）
  /// - 刷题模式已提交 / 背题模式：「上一题」「下一题」双按钮
  Widget _buildBottomButtons() {
    final isPractice = widget.mode == 'practice';

    // 刷题且未提交：显示全宽提交按钮
    if (isPractice && !_isAnswered) {
      final canSubmit = _hasSelection();
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? _submitAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? Theme.of(context).colorScheme.primary
                : AppColors.adaptive(
                    context, AppColors.border, const Color(0xFF3A3A3A)),
            foregroundColor: canSubmit
                ? Colors.white
                : AppColors.adaptive(
                    context, AppColors.textTertiary, Colors.grey.shade600),
            disabledBackgroundColor: AppColors.adaptive(
                context, AppColors.border, const Color(0xFF3A3A3A)),
            disabledForegroundColor: AppColors.adaptive(
                context, AppColors.textTertiary, Colors.grey.shade600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Text('提交答案'),
        ),
      );
    }

    final isLastQuestion = _currentQuestionIndex >= _questions.length - 1;
    final nextLabel =
        (isPractice && isLastQuestion) ? '查看结果' : '下一题';
    final nextOnPressed =
        (isPractice && isLastQuestion) && _sessionResults.isEmpty
            ? null
            : _goToNextQuestion;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一题：灰色按钮
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed:
                _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adaptive(
                  context, AppColors.border, const Color(0xFF3A3A3A)),
              foregroundColor: AppColors.adaptive(
                  context, AppColors.textTertiary, Colors.grey.shade300),
              disabledBackgroundColor: AppColors.adaptive(
                  context, AppColors.border, const Color(0xFF3A3A3A)),
              disabledForegroundColor: AppColors.adaptive(
                  context, AppColors.textQuaternary, Colors.grey.shade600),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('上一题'),
          ),
        ),
        const SizedBox(width: 12),

        // 下一题 / 查看结果：主色按钮
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: nextOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }

  /// 结果视图：分数圆环滚动动画 + 统计卡 + 返回按钮
  Widget _buildResultView() {
    final score = _calculateScore();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 分数颜色语义化：≥80 绿 / ≥60 蓝 / <60 红
    final Color scoreColor = score >= 80
        ? AppColors.adaptive(
            context, AppColors.successGreen, const Color(0xFF81C784))
        : score >= 60
            ? AppColors.adaptive(
                context, AppColors.primary, const Color(0xFF64B5F6))
            : AppColors.adaptive(
                context, AppColors.errorRed, const Color(0xFFEF9A9A));

    final int totalCount = _questions.length;
    final int answeredCount = _sessionResults.length;
    final int correctCount = _sessionResults.where((r) => r).length;
    final int wrongCount = answeredCount - correctCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // 圆环分数动画
          Center(
            child: _ScoreRing(score: score, color: scoreColor),
          ),

          const SizedBox(height: 40),

          // 统计卡
          Row(
            children: [
              _buildStatItem('总题数', '$totalCount', isDark),
              const SizedBox(width: 12),
              _buildStatItem('已答', '$answeredCount', isDark),
              const SizedBox(width: 12),
              _buildStatItem('错误数', '$wrongCount', isDark),
              const SizedBox(width: 12),
              _buildStatItem('正确率', '${score.toStringAsFixed(0)}%', isDark),
            ],
          ),

          const SizedBox(height: 40),

          // 返回题库按钮
          SizedBox(
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('返回题库'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.adaptive(
              context, AppColors.cardPlainBg, const Color(0xFF252525)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.adaptive(
                    context, AppColors.textSecondary, Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.adaptive(
                    context, AppColors.textPrimary, const Color(0xFFE1E1E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateScore() {
    if (_sessionResults.isEmpty) return 0;
    final correctCount = _sessionResults.where((r) => r).length;
    return (correctCount / _sessionResults.length) * 100;
  }
}

/// 自绘选项卡组件（对齐设计稿）：
/// - 普通态：白底 + 1px灰边框 + 空心图标
/// - 选中态：浅蓝底 #E3F2FD + 主蓝边框 2px + 实心图标
/// - 正确态：浅绿底 #E8F5E9 + 绿边框 2px
/// - 错误态：浅红底 #FFEBEE + 红边框 2px #F44336
class _OptionCard extends StatelessWidget {
  final String text;
  final bool multiSelect; // 多选使用方形框，单选使用圆形
  final _OptionVisualState visualState;
  final bool dimmed; // 不可交互时弱化文本
  final VoidCallback? onTap; // 为 null 时不可点击

  const _OptionCard({
    required this.text,
    required this.multiSelect,
    required this.visualState,
    this.dimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bgColor;
    late final Color borderColor;
    late final double borderWidth;
    late final Widget leadIcon;

    switch (visualState) {
      case _OptionVisualState.normal:
        bgColor = Theme.of(context).cardColor;
        borderColor = isDark ? const Color(0xFF3A3A3A) : AppColors.border;
        borderWidth = 1;
        leadIcon = _baseLeadIcon(context, isDark);
        break;
      case _OptionVisualState.selected:
        bgColor = isDark
            ? const Color(0xFF17334D)
            : AppColors.selectedBg;
        borderColor = Theme.of(context).colorScheme.primary;
        borderWidth = 2;
        leadIcon = Icon(
          multiSelect ? Icons.check_box : Icons.check_circle,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        );
        break;
      case _OptionVisualState.correct:
        bgColor =
            isDark ? const Color(0xFF12331C) : AppColors.successBg;
        borderColor = AppColors.adaptive(
            context, AppColors.successGreen, const Color(0xFF81C784));
        borderWidth = 2;
        leadIcon = Icon(
          multiSelect ? Icons.check_box : Icons.check_circle,
          size: 20,
          color: AppColors.adaptive(
              context, AppColors.successGreen, const Color(0xFF81C784)),
        );
        break;
      case _OptionVisualState.wrong:
        bgColor = isDark ? const Color(0xFF3A1A1A) : AppColors.errorBg;
        borderColor = AppColors.adaptive(
            context, AppColors.errorRed, const Color(0xFFEF9A9A));
        borderWidth = 2;
        leadIcon = Icon(
          Icons.cancel_rounded,
          size: 20,
          color: AppColors.adaptive(
              context, AppColors.errorRed, const Color(0xFFEF9A9A)),
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 56, // 设计稿行高56，触控目标达标
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey('$visualState-$multiSelect'),
                      child: leadIcon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: visualState == _OptionVisualState.normal
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: _textColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _baseLeadIcon(BuildContext context, bool isDark) {
    final color = AppColors.adaptive(
        context, AppColors.textQuaternary, Colors.grey.shade600);
    return multiSelect
        ? Icon(Icons.check_box_outline_blank, size: 20, color: color)
        : Icon(Icons.radio_button_unchecked, size: 20, color: color);
  }

  Color _textColor(BuildContext context) {
    switch (visualState) {
      case _OptionVisualState.correct:
        return AppColors.adaptive(
            context, AppColors.successGreen, const Color(0xFF81C784));
      case _OptionVisualState.wrong:
        return AppColors.adaptive(
            context, AppColors.errorRed, const Color(0xFFEF9A9A));
      case _OptionVisualState.selected:
        return AppColors.adaptive(
            context, AppColors.primary, const Color(0xFF64B5F6));
      case _OptionVisualState.normal:
        if (dimmed) {
          return AppColors.adaptive(
              context, AppColors.textQuaternary, Colors.grey.shade500);
        }
        return AppColors.adaptive(
            context, AppColors.textPrimary, const Color(0xFFE1E1E1));
    }
  }
}

/// 分数圆环：数字滚动 + 进度弧动画
class _ScoreRing extends StatelessWidget {
  final double score;
  final Color color;

  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, fraction, _) {
        final displayed = score * fraction;
        return SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(190, 190),
                painter: _RingPainter(
                  fraction: fraction,
                  color: color,
                  trackColor: AppColors.adaptive(
                      context, AppColors.border, const Color(0xFF2E2E2E)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayed.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '分',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.adaptive(
                          context, AppColors.textTertiary, Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 圆环画笔
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // 轨道
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    // 进度弧
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2, // 从顶部开始
      2 * 3.14159265 * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
