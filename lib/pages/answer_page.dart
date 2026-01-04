import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models/question.dart';
import '../data/models/user_record.dart';

class AnswerPage extends StatefulWidget {
  final int bankId;
  final String mode; // study: 背题模式, practice: 刷题模式
  final bool shuffle; // 是否乱序

  const AnswerPage({
    Key? key,
    required this.bankId,
    required this.mode,
    required this.shuffle,
  }) : super(key: key);

  @override
  State<AnswerPage> createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> {
  List<Question> _questions = [];
  List<Question> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  dynamic _userAnswer;
  
  // 答题结果记录
  final Map<int, bool> _answerResults = {}; // 题目ID -> 是否正确
  final List<Question> _wrongQuestions = []; // 错题列表
  int _correctCount = 0; // 正确题数
  int _incorrectCount = 0; // 错误题数
  
  // 结果显示状态
  bool _showingResult = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // 加载题目
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _questions = await DatabaseHelper.instance.getQuestionsByBankId(widget.bankId);
      
      if (widget.shuffle) {
        _currentQuestions = [..._questions]..shuffle(Random());
      } else {
        _currentQuestions = [..._questions];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载题目失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 提交答案
  void _submitAnswer() {
    if (_currentQuestionIndex >= _currentQuestions.length) {
      return;
    }

    Question question = _currentQuestions[_currentQuestionIndex];
    bool isCorrect = _checkAnswer(question, _userAnswer);

    setState(() {
      _isAnswered = true;
      
      // 记录答题结果
      _answerResults[question.id!] = isCorrect;
      
      if (isCorrect) {
        _correctCount++;
      } else {
        _incorrectCount++;
        if (!_wrongQuestions.contains(question)) {
          _wrongQuestions.add(question);
        }
      }
    });

    // 记录答题结果到数据库
    _recordAnswer(question.id!, _userAnswer, !isCorrect);
  }

  // 检查答案是否正确
  bool _checkAnswer(Question question, dynamic userAnswer) {
    switch (question.type) {
      case 'single':
        // 单选题
        return userAnswer == question.correctAnswer;
      
      case 'multiple':
        // 多选题，比较两个数组是否相同
        if (userAnswer is List && question.correctAnswer is List) {
          List<String> userAnswers = List<String>.from(userAnswer)..sort();
          List<String> correctAnswers = List<String>.from(question.correctAnswer)..sort();
          return userAnswers.length == correctAnswers.length &&
              userAnswers.every((answer) => correctAnswers.contains(answer));
        }
        return false;
      
      case 'true_false':
        // 判断题
        return userAnswer == question.correctAnswer;
      
      case 'fill_in_blank':
        // 填空题，简单比较字符串
        return userAnswer?.toString().trim().toLowerCase() == 
               question.correctAnswer?.toString().trim().toLowerCase();
      
      case 'short_answer':
        // 简答题，这里简化处理，实际应用中可能需要更复杂的评分逻辑
        return userAnswer?.toString().trim().isNotEmpty == true;
      
      default:
        return false;
    }
  }

  // 记录答题结果到数据库
  Future<void> _recordAnswer(int questionId, dynamic userAnswer, bool isIncorrect) async {
    UserRecord record = UserRecord(
      questionId: questionId,
      isIncorrect: isIncorrect,
      isMarked: false,
      lastAttempted: DateTime.now().toString(),
      userAnswer: userAnswer,
    );

    await DatabaseHelper.instance.insertOrUpdateUserRecord(record);
  }

  // 下一题
  void _nextQuestion() {
    // 如果当前题未提交答案，自动提交
    if (!_isAnswered && _userAnswer != null && (_userAnswer is List ? _userAnswer.isNotEmpty : true)) {
      _submitAnswer();
    }
    
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        // 初始化下一题的答案
        Question nextQuestion = _currentQuestions[_currentQuestionIndex];
        _userAnswer = null; // 重置用户答案，在_buildOptions中会根据题型重新初始化
      });
    } else {
      // 最后一题如果未提交，先提交
      if (!_isAnswered && _userAnswer != null && (_userAnswer is List ? _userAnswer.isNotEmpty : true)) {
        _submitAnswer();
      }
      // 答题结束，显示结果
      _showResult();
    }
  }

  // 上一题
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _isAnswered = false;
        _userAnswer = null; // 重置用户答案，在_buildOptions中会根据题型重新初始化
      });
    }
  }

  // 答题结束，返回上一页
  void _finishAnswering() {
    // 确保在返回前重置状态，避免黑屏
    setState(() {
      _showingResult = false;
    });
    // 使用安全导航，确保能正确返回
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  // 显示答题结果
  void _showResult() {
    setState(() {
      _showingResult = true;
    });
  }
  
  // 计算得分
  double _calculateScore() {
    if (_currentQuestions.isEmpty) return 0.0;
    
    // 这里需要获取当前题库的计分模式，暂时使用average作为默认
    String scoreMode = 'average';
    
    switch (scoreMode) {
      case 'single':
        // 单题计分：根据每个题目的score字段计算总分
        int totalScore = 0;
        int earnedScore = 0;
        
        for (var question in _currentQuestions) {
          totalScore += question.score;
          if (_answerResults[question.id!] == true) {
            earnedScore += question.score;
          }
        }
        
        // 计算百分比得分
        return totalScore > 0 ? (earnedScore / totalScore) * 100 : 0.0;
        
      case 'average':
      default:
        // 平均计分：总题数除以100
        return (_correctCount / _currentQuestions.length) * 100;
    }
  }

  // 切换收藏状态
  void _toggleMark() {
    if (_currentQuestionIndex < _currentQuestions.length) {
      int questionId = _currentQuestions[_currentQuestionIndex].id!;
      DatabaseHelper.instance.toggleMarkQuestion(questionId, !_getIsMarked());
    }
  }

  // 获取当前题目是否被收藏
  bool _getIsMarked() {
    // 这里需要从数据库获取，简化实现
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode == 'study' ? '背题' : '刷题'}模式'),
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _getIsMarked() ? Icons.star : Icons.star_border,
              color: _getIsMarked() ? Colors.yellow : null,
            ),
            onPressed: _toggleMark,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentQuestions.isEmpty
              ? const Center(child: Text('没有题目'))
              : _showingResult
                  ? _buildResultView()
                  : _buildQuestionView(),
    );
  }

  // 构建题目视图
  Widget _buildQuestionView() {
    if (_currentQuestionIndex >= _currentQuestions.length) {
      return const Center(child: Text('答题结束'));
    }

    Question question = _currentQuestions[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 进度条
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _currentQuestions.length,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8.0),

        // 题号
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${_currentQuestionIndex + 1}/${_currentQuestions.length}',
            style: const TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
        ),

        // 题目内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),

                // 选项
                _buildOptions(question),

                // 只有背题模式下直接显示答案，刷题模式下答案只在结果页显示
                if (widget.mode == 'study')
                  _buildAnswerAndExplanation(question),
              ],
            ),
          ),
        ),

        // 底部操作按钮
        _buildBottomButtons(),
      ],
    );
  }

  // 构建选项
  Widget _buildOptions(Question question) {
    // 根据题目类型初始化用户答案
    if (_userAnswer == null) {
      switch (question.type) {
        case 'single':
          _userAnswer = null;
          break;
        case 'multiple':
          _userAnswer = [];
          break;
        case 'true_false':
          _userAnswer = null;
          break;
        case 'fill_in_blank':
        case 'short_answer':
          _userAnswer = '';
          break;
      }
    }

    // 根据题目类型构建不同的选项UI
    switch (question.type) {
      case 'single':
        return _buildSingleChoiceOptions(question);
      case 'multiple':
        return _buildMultipleChoiceOptions(question);
      case 'true_false':
        return _buildTrueFalseOptions(question);
      case 'fill_in_blank':
      case 'short_answer':
        return _buildTextInputOptions(question);
      default:
        return const Text('不支持的题型');
    }
  }

  // 构建单选题选项
  Widget _buildSingleChoiceOptions(Question question) {
    List<Widget> optionsWidgets = [];

    question.options.forEach((key, value) {
      optionsWidgets.add(RadioListTile(
        title: Text(value),
        value: key,
        groupValue: _userAnswer,
        onChanged: widget.mode == 'practice' && !_isAnswered
            ? (value) {
                setState(() {
                  _userAnswer = value;
                });
              }
            : null,
        activeColor: Colors.blue,
      ));
    });

    return Column(children: optionsWidgets);
  }

  // 构建多选题选项
  Widget _buildMultipleChoiceOptions(Question question) {
    List<Widget> optionsWidgets = [];

    question.options.forEach((key, value) {
      optionsWidgets.add(CheckboxListTile(
        title: Text(value),
        value: _userAnswer is List && _userAnswer.contains(key),
        onChanged: widget.mode == 'practice' && !_isAnswered
            ? (value) {
                setState(() {
                  if (value == true) {
                    if (_userAnswer is List) {
                      _userAnswer.add(key);
                    } else {
                      _userAnswer = [key];
                    }
                  } else {
                    if (_userAnswer is List) {
                      _userAnswer.remove(key);
                    }
                  }
                });
              }
            : null,
        activeColor: Colors.blue,
        checkColor: Colors.white,
      ));
    });

    return Column(children: optionsWidgets);
  }

  // 构建判断题选项
  Widget _buildTrueFalseOptions(Question question) {
    return Column(
      children: [
        RadioListTile(
          title: const Text('正确'),
          value: true,
          groupValue: _userAnswer,
          onChanged: widget.mode == 'practice' && !_isAnswered
              ? (value) {
                  setState(() {
                    _userAnswer = value;
                  });
                }
              : null,
          activeColor: Colors.blue,
        ),
        RadioListTile(
          title: const Text('错误'),
          value: false,
          groupValue: _userAnswer,
          onChanged: widget.mode == 'practice' && !_isAnswered
              ? (value) {
                  setState(() {
                    _userAnswer = value;
                  });
                }
              : null,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  // 构建填空题和简答题的文本输入
  Widget _buildTextInputOptions(Question question) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: TextEditingController(text: _userAnswer?.toString() ?? ''),
        onChanged: widget.mode == 'practice' && !_isAnswered
            ? (value) {
                setState(() {
                  _userAnswer = value;
                });
              }
            : null,
        maxLines: question.type == 'short_answer' ? 5 : 1,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: question.type == 'fill_in_blank' ? '请输入答案' : '请简要回答',
        ),
      ),
    );
  }

  // 构建答案和解析
  Widget _buildAnswerAndExplanation(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '正确答案:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  question.correctAnswer.toString(),
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  '解析:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(question.explanation),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建底部操作按钮
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一题按钮
          ElevatedButton(
            onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
            child: const Text('上一题'),
          ),

          // 下一题按钮
          ElevatedButton(
            onPressed: _nextQuestion,
            child: const Text('下一题'),
          ),
        ],
      ),
    );
  }

  // 构建结果展示界面
  Widget _buildResultView() {
    double score = _calculateScore();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 得分展示
          const SizedBox(height: 32.0),
          const Text(
            '答题结束',
            style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24.0),
          
          // 得分圆形卡片
          Container(
            width: 200.0,
            height: 200.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue, width: 3.0),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const Text(
                    '分',
                    style: TextStyle(fontSize: 24.0, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32.0),
          
          // 答题统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('总题数', _currentQuestions.length.toString()),
              _buildStatCard('正确', _correctCount.toString()),
              _buildStatCard('错误', _incorrectCount.toString()),
              _buildStatCard('正确率', '${score.toStringAsFixed(1)}%'),
            ],
          ),
          
          const SizedBox(height: 32.0),
          
          // 错题列表
          if (_wrongQuestions.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '错题列表',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wrongQuestions.length,
              itemBuilder: (context, index) {
                Question question = _wrongQuestions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${question.question}',
                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '正确答案: ${question.correctAnswer}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '解析: ${question.explanation}',
                          style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          
          const SizedBox(height: 32.0),
          
          // 返回按钮
          ElevatedButton(
            onPressed: _finishAnswering,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50.0),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text(
              '返回题库',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  // 构建统计卡片
  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
            const SizedBox(height: 8.0),
            Text(
              value,
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
