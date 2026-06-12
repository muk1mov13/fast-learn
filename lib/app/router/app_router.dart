import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_user_detail_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/topic/topic_screen.dart';
import '../../state/auth_providers.dart';

/// Auth holati o'zgarganda go_router'ni qayta baholashga majburlovchi listenable.
class _RouterRefresh extends ChangeNotifier {
  void poke() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  // authProvider har o'zgarganda (kirish/chiqish/profil yuklash) router yangilanadi.
  ref.listen(authProvider, (_, __) => refresh.poke());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final onAuthPages = loc == '/login' || loc == '/register';

      // Auth holati hali aniqlanmagan — splash'da kutamiz.
      if (auth.status == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }

      final loggedIn = auth.status == AuthStatus.authenticated;
      if (!loggedIn) {
        return onAuthPages ? null : '/login';
      }

      // Kirgan: splash yoki auth sahifalaridan asosiy joyga yo'naltiramiz.
      if (onAuthPages || loc == '/splash') {
        return auth.isAdmin ? '/admin' : '/';
      }
      // Student admin sahifaga kira olmaydi.
      if (loc.startsWith('/admin') && !auth.isAdmin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return TopicScreen(topicId: id, initialTab: tab);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/user/:uid',
        builder: (context, state) => AdminUserDetailScreen(
          uid: state.pathParameters['uid'] ?? '',
        ),
      ),
    ],
  );
});
