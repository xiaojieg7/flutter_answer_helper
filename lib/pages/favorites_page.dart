import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/database_service_factory.dart';
import '../data/models/question.dart';
import '../data/models/question_bank.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

enum FavoritesViewMode { byBank, all }

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Question> _favorites = [];
  Map<int, QuestionBank> _banks = {};
  bool _isLoading = true;
  FavoritesViewMode _viewMode = FavoritesViewMode.byBank;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 加载收藏的题目与题库信息（用于按题库分组与标签展示）
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final databaseService = DatabaseServiceFactory.getInstance();
      final results =
          await Future.wait([databaseService.getMarkedQuestions(), databaseService.getQuestionBanks()]);
      if (!mounted) return;
      setState(() {
        _favorites = results[0] as List<Question>;
        final bankList = results[1] as List<QuestionBank>;
        _banks = {for (final b in bankList) b.id!: b};
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

  // 取消收藏
  void _unmarkQuestion(int questionId) {
    final databaseService = DatabaseServiceFactory.getInstance();
    databaseService.toggleMarkQuestion(questionId, false);
    _loadFavorites();
  }

  // 按 bankId 分组；某题已查不到所属题库时归入 id=-1 组
  Map<int, List<Question>> get _groupedFavorites {
    final map = <int, List<Question>>{};
    for (final q in _favorites) {
      final key = q.bankId;
      (map[key] ??= []).add(q);
    }
    // 收藏数多的排前面
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(entries);
  }

  String _bankTitle(int bankId) =>
      _banks[bankId]?.title ?? (bankId == -1 ? '未知来源' : '题库 #$bankId');

  void _openBankDetail(int bankId) {
    final title = _bankTitle(bankId);
    context
        .push(
            '/favorites-detail/$bankId?title=${Uri.encodeComponent(title)}')
        .then((_) => _loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          AppColors.adaptive(context, Colors.white, const Color(0xFF121212)),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          '我的收藏',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<FavoritesViewMode>(
              segments: const [
                ButtonSegment(
                  value: FavoritesViewMode.byBank,
                  icon: Icon(Icons.folder_outlined, size: 18),
                  label: Text('按题库'),
                ),
                ButtonSegment(
                  value: FavoritesViewMode.all,
                  icon: Icon(Icons.view_list_outlined, size: 18),
                  label: Text('全部'),
                ),
              ],
              selected: {_viewMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _viewMode = selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: MaterialStatePropertyAll(BorderSide(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : AppColors.border)),
                shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonBox(height: 72, radius: 12),
        ),
      );
    }
    if (_favorites.isEmpty) {
      return EmptyState(
        icon: Icons.star_outline,
        title: '还没有收藏题目',
        message: '答题时点击右上角星标即可收藏题目',
      );
    }
    switch (_viewMode) {
      case FavoritesViewMode.byBank:
        return _buildBankListView();
      case FavoritesViewMode.all:
        return _buildAllListView();
    }
  }

  /// 按题库分组视图（对齐设计稿「收藏页面」画板）
  Widget _buildBankListView() {
    final grouped = _groupedFavorites;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : AppColors.border;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: grouped.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        final count = entry.value.length;
        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openBankDetail(entry.key),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bankTitle(entry.key),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.adaptive(context,
                                AppColors.textPrimary, const Color(0xFFE1E1E1)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '已收藏 $count 题',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.adaptive(context,
                                AppColors.textTertiary, const Color(0xFF9E9E9E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 18,
                      color: AppColors.adaptive(context, AppColors.textTertiary,
                          const Color(0xFF757575))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 全部平铺视图（沿用原卡片样式 + 题库名小标签）
  Widget _buildAllListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        Question question = _favorites[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        question.question,
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.star, color: AppColors.starAmber),
                      onPressed: () => _unmarkQuestion(question.id!),
                      padding: EdgeInsets.zero,
                      tooltip: '取消收藏',
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _bankTitle(question.bankId),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.adaptive(context, AppColors.textTertiary,
                          const Color(0xFF9E9E9E)),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                // 显示选项
                Column(
                  children: question.options.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Text('${entry.key}. ${entry.value}'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8.0),
                // 显示正确答案
                Text(
                  '正确答案: ${question.correctAnswer}',
                  style: TextStyle(
                      color: AppColors.adaptive(context, AppColors.successGreen,
                          const Color(0xFF81C784)),
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                // 显示解析
                Text(
                  '解析: ${question.explanation}',
                  style: TextStyle(
                      color: AppColors.adaptive(context, AppColors.primary,
                          const Color(0xFF64B5F6))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
