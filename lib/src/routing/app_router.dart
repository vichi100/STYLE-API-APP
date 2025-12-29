import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/chat/presentation/chat_screen.dart';
import '../features/dashboard/presentation/scaffold_with_nav_bar.dart';
import '../features/mismatch/presentation/mismatch_screen.dart';
import '../features/recommendations/presentation/top_match_screen.dart';
import '../features/style_advisor/presentation/product_details_screen.dart';
import '../features/wardrobe/presentation/wardrobe_screen.dart';
import '../theme/theme_provider.dart'; // Correct import path

part 'app_router.g.dart';

// Private navigators to support maintaining state in each tab
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKaiKey = GlobalKey<NavigatorState>(debugLabel: 'shellKai');
final _shellNavigatorTopMatchKey = GlobalKey<NavigatorState>(debugLabel: 'shellTopMatch');
final _shellNavigatorMismatchKey = GlobalKey<NavigatorState>(debugLabel: 'shellMismatch');
final _shellNavigatorWardrobeKey = GlobalKey<NavigatorState>(debugLabel: 'shellWardrobe');

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/kai',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch Kai (Chat)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKaiKey,
            routes: [
              GoRoute(
                path: '/kai',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ChatScreen(),
                ),
              ),
            ],
          ),
          // Branch Top Match
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTopMatchKey,
            routes: [
              GoRoute(
                path: '/top-match',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TopMatchScreen(),
                ),
              ),
            ],
          ),
          // Branch Mismatch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMismatchKey,
            routes: [
              GoRoute(
                path: '/mismatch',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MismatchScreen(),
                ),
              ),
            ],
          ),
          // Branch Wardrobe
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWardrobeKey,
            routes: [
              GoRoute(
                path: '/wardrobe',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: WardrobeScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailsScreen(productId: id);
        },
      ),
    ],
  );
}
