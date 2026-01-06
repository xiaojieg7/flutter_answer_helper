import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models/question.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Question> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 加载收藏的题目
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _favorites = await DatabaseHelper.instance.getMarkedQuestions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载收藏题目失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 取消收藏
  void _unmarkQuestion(int questionId) {
    DatabaseHelper.instance.toggleMarkQuestion(questionId, false);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏夹'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(child: Text('还没有收藏题目'))
              : ListView.builder(
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    Question question = _favorites[index];
                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.star, color: Colors.yellow),
                                  onPressed: () => _unmarkQuestion(question.id!),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
