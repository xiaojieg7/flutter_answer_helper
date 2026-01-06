import 'package:flutter/material.dart';
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
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomTab(child: child),
        routes: [
          // 首页
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => _buildPageWithSwipeDirection(
              key: state.pageKey,
              child: const HomePage(),
              swipeDirection: state.uri.queryParameters['swipe'],
            ),
            routes: [
              // 题库详情页
              GoRoute(
                path: 'bank/:id',
                name: 'bankDetail',
                pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                  key: state.pageKey,
                  child: QuestionBankDetailPage(bankId: int.parse(state.pathParameters['id']!)),
                  swipeDirection: state.uri.queryParameters['swipe'],
                ),
                routes: [
                  // 答题页
                  GoRoute(
                    path: 'answer',
                    name: 'answer',
                    pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                      key: state.pageKey,
                      child: AnswerPage(
                        bankId: int.parse(state.pathParameters['id']!),
                        mode: state.uri.queryParameters['mode'] ?? 'study',
                        shuffle: state.uri.queryParameters['shuffle'] == 'true',
                      ),
                      swipeDirection: state.uri.queryParameters['swipe'],
                    ),
                  ),
                ],
              ),
              // 科目详情页
              GoRoute(
                path: 'subject/:subject',
                name: 'subjectDetail',
                pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                  key: state.pageKey,
                  child: SubjectDetailPage(subject: state.pathParameters['subject']!),
                  swipeDirection: state.uri.queryParameters['swipe'],
                ),
                routes: [
                  // 科目下的题库详情页
                  GoRoute(
                    path: 'bank/:id',
                    name: 'subjectBankDetail',
                    pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                      key: state.pageKey,
                      child: QuestionBankDetailPage(bankId: int.parse(state.pathParameters['id']!)),
                      swipeDirection: state.uri.queryParameters['swipe'],
                    ),
                    routes: [
                      // 答题页
                      GoRoute(
                        path: 'answer',
                        name: 'subjectAnswer',
                        pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                          key: state.pageKey,
                          child: AnswerPage(
                            bankId: int.parse(state.pathParameters['id']!),
                            mode: state.uri.queryParameters['mode'] ?? 'study',
                            shuffle: state.uri.queryParameters['shuffle'] == 'true',
                          ),
                          swipeDirection: state.uri.queryParameters['swipe'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 错题本
              GoRoute(
                path: 'wrong-questions',
                name: 'wrongQuestions',
                pageBuilder: (context, state) => _buildPageWithSwipeDirection(
                  key: state.pageKey,
                  child: const WrongQuestionsPage(),
                  swipeDirection: state.uri.queryParameters['swipe'],
                ),
              ),
            ],
          ),
          // 收藏夹
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            pageBuilder: (context, state) => _buildPageWithSwipeDirection(
              key: state.pageKey,
              child: const FavoritesPage(),
              swipeDirection: state.uri.queryParameters['swipe'],
            ),
          ),
          // 设置页
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildPageWithSwipeDirection(
              key: state.pageKey,
              child: const SettingsPage(),
              swipeDirection: state.uri.queryParameters['swipe'],
            ),
          ),
        ],
      ),
    ],
  );

  // 根据滑动方向构建页面
  static CustomTransitionPage _buildPageWithSwipeDirection({
    required LocalKey key,
    required Widget child,
    String? swipeDirection,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 确定动画开始位置
        Offset beginOffset;
        
        // 如果有滑动方向参数，优先使用
        if (swipeDirection == 'left') {
          // 左滑，切换到下一个页面，新页面从右向左滑入
          beginOffset = const Offset(1.0, 0.0);
        } else if (swipeDirection == 'right') {
          // 右滑，切换到上一个页面，新页面从左向右滑入
          beginOffset = const Offset(-1.0, 0.0);
        } else {
          // 默认情况，新页面从右向左滑入
          beginOffset = const Offset(1.0, 0.0);
        }
        
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
