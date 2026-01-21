import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/core/utils/auth_logger.dart';
import 'package:whdgkr/presentation/providers/auth_provider.dart';
import 'package:whdgkr/presentation/screens/trip_list_screen.dart';
import 'package:whdgkr/presentation/screens/create_trip_screen.dart';
import 'package:whdgkr/presentation/screens/trip_detail_screen.dart';
import 'package:whdgkr/presentation/screens/settlement_screen.dart';
import 'package:whdgkr/presentation/screens/add_expense_screen.dart';
import 'package:whdgkr/presentation/screens/edit_expense_screen.dart';
import 'package:whdgkr/presentation/screens/friend_list_screen.dart';
import 'package:whdgkr/presentation/screens/friend_form_screen.dart';
import 'package:whdgkr/presentation/screens/debug_screen.dart';
import 'package:whdgkr/presentation/screens/login_screen.dart';
import 'package:whdgkr/presentation/screens/signup_screen.dart';
import 'package:whdgkr/presentation/screens/reset_password_screen.dart';
import 'package:whdgkr/presentation/screens/statistics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthLogger.init();
  // [BOOT] 관측 신호 - 실행 경로 확인
  debugPrint('[BOOT] main=lib/main.dart, flavor=debug, baseUrl=${_getBaseUrl()}');
  runApp(const ProviderScope(child: MyApp()));
}

String _getBaseUrl() {
  // AppConfig에서 baseUrl 가져오기
  return 'http://localhost:8080/api';
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;
      final isInitial = authState.status == AuthStatus.initial;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/reset-password';

      debugPrint('[ROUTER] location=${state.matchedLocation}, auth=${authState.status}, isAuthRoute=$isAuthRoute');

      // 초기 또는 로딩 중에는 리다이렉트 하지 않음
      if (isLoading || isInitial) {
        debugPrint('[ROUTER] Skip redirect (loading or initial)');
        return null;
      }

      // 미인증 상태에서 인증 페이지가 아니면 로그인으로
      if (!isAuthenticated && !isAuthRoute) {
        debugPrint('[ROUTER] Redirect to /login (not authenticated)');
        return '/login';
      }

      // 인증 상태에서 인증 페이지면 홈으로
      if (isAuthenticated && isAuthRoute) {
        debugPrint('[ROUTER] Redirect to / (authenticated)');
        return '/';
      }

      debugPrint('[ROUTER] No redirect');
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
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
        path: '/trip/:id/statistics',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return StatisticsScreen(tripId: id);
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
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 인증 상태 확인
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: '여행 정산',
      theme: AppTheme.lightTheme,
      routerConfig: router,
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

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authProvider);

    int currentIndex;
    if (location == '/friends') {
      currentIndex = 1;
    } else if (location == '/debug') {
      currentIndex = 2;
    } else {
      currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(location)),
        actions: [
          if (authState.status == AuthStatus.authenticated)
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    authState.member?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    authState.member?.email ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('로그아웃'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
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

  String _getTitle(String location) {
    if (location == '/friends') return '친구';
    if (location == '/debug') return '개발자 도구';
    return '여행';
  }
}
