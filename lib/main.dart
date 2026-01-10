import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/presentation/screens/trip_list_screen.dart';
import 'package:whdgkr/presentation/screens/create_trip_screen.dart';
import 'package:whdgkr/presentation/screens/trip_detail_screen.dart';
import 'package:whdgkr/presentation/screens/settlement_screen.dart';
import 'package:whdgkr/presentation/screens/add_expense_screen.dart';
import 'package:whdgkr/presentation/screens/edit_expense_screen.dart';
import 'package:whdgkr/presentation/screens/friend_list_screen.dart';
import 'package:whdgkr/presentation/screens/friend_form_screen.dart';
import 'package:whdgkr/presentation/screens/debug_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TripListScreen(),
        ),
        GoRoute(
          path: '/friends',
          builder: (context, state) => const FriendListScreen(),
        ),
        // 개발/테스트 전용 디버그 화면 (kDebugMode에서만 노출)
        if (kDebugMode)
          GoRoute(
            path: '/debug',
            builder: (context, state) => const DebugScreen(),
          ),
      ],
    ),
    GoRoute(
      path: '/create-trip',
      builder: (context, state) => const CreateTripScreen(),
    ),
    GoRoute(
      path: '/trip/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TripDetailScreen(tripId: id);
      },
    ),
    GoRoute(
      path: '/trip/:id/settlement',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return SettlementScreen(tripId: id);
      },
    ),
    GoRoute(
      path: '/trip/:id/add-expense',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddExpenseScreen(tripId: id);
      },
    ),
    GoRoute(
      path: '/trip/:tripId/expense/:expenseId',
      builder: (context, state) {
        final tripId = int.parse(state.pathParameters['tripId']!);
        final expenseId = int.parse(state.pathParameters['expenseId']!);
        return EditExpenseScreen(tripId: tripId, expenseId: expenseId);
      },
    ),
    GoRoute(
      path: '/friends/add',
      builder: (context, state) => const FriendFormScreen(),
    ),
    GoRoute(
      path: '/friends/edit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return FriendFormScreen(friendId: id);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '여행 정산',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // 디버그 모드에서는 3개 탭, 아니면 2개 탭
    int currentIndex;
    if (location == '/friends') {
      currentIndex = 1;
    } else if (location == '/debug') {
      currentIndex = 2;
    } else {
      currentIndex = 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/friends');
          } else if (index == 2 && kDebugMode) {
            context.go('/debug');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: '여행',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '친구',
          ),
          // 개발/테스트 전용 (kDebugMode에서만 노출)
          if (kDebugMode)
            NavigationDestination(
              icon: Icon(Icons.developer_mode_outlined, color: Colors.red.shade300),
              selectedIcon: Icon(Icons.developer_mode, color: Colors.red),
              label: '개발',
            ),
        ],
      ),
    );
  }
}
