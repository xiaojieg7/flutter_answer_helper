import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/question_bank_detail.dart';
import '../pages/answer_page.dart';
import '../pages/wrong_questions_page.dart';
import '../pages/favorites_page.dart';
import '../pages/settings_page.dart';
import '../pages/subject_detail_page.dart';
import '../layout/scaffold_with_bottom_tab.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    // 启用侧滑返回支持
    debugLogDiagnostics: true,
    routes: [
      // 使用ShellRoute实现底部tab栏，所有页面都嵌套在其中
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomTab(child: child),
        routes: [
          // 首页
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
            // 首页的子路由
            routes: [
              // 题库详情页
              GoRoute(
                path: 'bank/:id',
                name: 'bankDetail',
                builder: (context, state) {
                  final bankId = int.parse(state.pathParameters['id']!);
                  return QuestionBankDetailPage(bankId: bankId);
                },
                // 题库详情页的子路由
                routes: [
                  // 答题页
                  GoRoute(
                    path: 'answer',
                    name: 'answer',
                    builder: (context, state) {
                      final bankId = int.parse(state.pathParameters['id']!);
                      final mode = state.uri.queryParameters['mode'] ?? 'study'; // study或practice
                      final shuffle = state.uri.queryParameters['shuffle'] ?? 'false';
                      return AnswerPage(
                        bankId: bankId,
                        mode: mode,
                        shuffle: shuffle == 'true',
                      );
                    },
                  ),
                ],
              ),
              // 科目详情页
              GoRoute(
                path: 'subject/:subject',
                name: 'subjectDetail',
                builder: (context, state) {
                  final subject = state.pathParameters['subject']!;
                  return SubjectDetailPage(subject: subject);
                },
              ),
              // 错题本
              GoRoute(
                path: 'wrong-questions',
                name: 'wrongQuestions',
                builder: (context, state) => const WrongQuestionsPage(),
              ),
            ],
          ),
          // 收藏夹
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          // 设置页
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}
