import 'package:flutter/material.dart';

import '../data/database_service_factory.dart';
import '../data/models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// 单个题库的收藏详情页：对齐设计稿「XX - 收藏」画板
class FavoritesBankDetailPage extends StatefulWidget {
  final int bankId;
  final String bankTitle;

  const FavoritesBankDetailPage({
    Key? key,
    required this.bankId,
    required this.bankTitle,
  }) : super(key: key);

  @override
  State<FavoritesBankDetailPage> createState() =>
      _FavoritesBankDetailPageState();
}

class _FavoritesBankDetailPageState extends State<FavoritesBankDetailPage> {
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final databaseService = DatabaseServiceFactory.getInstance();
      final allMarked = await databaseService.getMarkedQuestions();
      if (!mounted) return;
      setState(() {
        _questions = allMarked
            .where((q) => q.bankId == widget.bankId)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载收藏失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unmarkQuestion(int questionId) async {
    try {
      await DatabaseServiceFactory.getInstance()
          .toggleMarkQuestion(questionId, false);
      // 列表为空时返回上一页，避免停留在空详情页
      final remaining =
          _questions.where((q) => q.id != questionId).length;
      if (remaining == 0 && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _loadFavorites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消收藏失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          '${widget.bankTitle} - 收藏',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SkeletonBox(height: 160, radius: 12),
              ),
            )
          : _questions.isEmpty
              ? EmptyState(
                  icon: Icons.star_outline,
                  title: '该题库暂无收藏',
                  message: '在答题页点击右上角星标即可收藏题目',
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        _buildQuestionCard(_questions[index], index + 1),
                  ),
                ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$index. ${question.question}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adaptive(context, AppColors.textPrimary,
                        const Color(0xFFE1E1E1)),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.star, color: AppColors.starAmber, size: 22),
                tooltip: '取消收藏',
                onPressed: () => _unmarkQuestion(question.id!),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          ...question.options.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${entry.key}. ${entry.value}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.adaptive(context, AppColors.textSecondary,
                        const Color(0xFFB0B0B0)),
                  ),
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '正确答案：${question.correctAnswer}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.adaptive(context, AppColors.successGreen,
                    const Color(0xFF81C784)),
              ),
            ),
          ),
          Divider(height: 24, color: borderColor),
          Text(
            '解析：${question.explanation}',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.adaptive(context, AppColors.textTertiary,
                  const Color(0xFF9E9E9E)),
            ),
          ),
        ],
      ),
    );
  }
}
