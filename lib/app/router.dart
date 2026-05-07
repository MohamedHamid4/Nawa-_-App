import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/views/auth/forgot_password_screen.dart';
import '../presentation/views/auth/sign_in_screen.dart';
import '../presentation/views/auth/sign_up_screen.dart';
import '../presentation/views/calendar/calendar_screen.dart';
import '../presentation/views/home/home_screen.dart';
import '../presentation/views/lock_screen.dart';
import '../presentation/views/legal/about_screen.dart';
import '../presentation/views/legal/contact_screen.dart';
import '../presentation/views/legal/data_usage_screen.dart';
import '../presentation/views/legal/privacy_screen.dart';
import '../presentation/views/legal/subscription_terms_screen.dart';
import '../presentation/views/legal/terms_screen.dart';
import '../presentation/views/note_editor/note_editor_screen.dart';
import '../presentation/views/notifications/notifications_screen.dart';
import '../presentation/views/onboarding/onboarding_screen.dart';
import '../presentation/views/search/search_screen.dart';
import '../presentation/views/friends/friends_screen.dart';
import '../presentation/views/friends/qr_scanner_screen.dart';
import '../presentation/views/friends/qr_screen.dart';
import '../presentation/views/settings/account_screen.dart';
import '../presentation/views/settings/profile_screen.dart';
import '../presentation/views/settings/settings_screen.dart';
import '../presentation/views/settings/username_setup_screen.dart';
import '../presentation/views/subscription/paywall_screen.dart';
import '../presentation/views/subscription/subscription_screen.dart';
import '../presentation/views/workspace/workspace_screen.dart';
import 'providers.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const lock = '/lock';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgot = '/forgot-password';
  static const home = '/home';
  static const noteEditor = '/note';
  static const search = '/search';
  static const calendar = '/calendar';
  static const workspaces = '/workspaces';
  static const settings = '/settings';
  static const account = '/account';
  static const profile = '/settings/profile';
  static const friends = '/friends';
  static const qrCode = '/friends/qr';
  static const qrScan = '/friends/scan';
  static const usernameSetup = '/settings/username';
  static const paywall = '/paywall';
  static const subscription = '/subscription';
  static const about = '/legal/about';
  static const privacy = '/legal/privacy';
  static const terms = '/legal/terms';
  static const contact = '/legal/contact';
  static const dataUsage = '/legal/data-usage';
  static const subscriptionTerms = '/legal/subscription-terms';
  static const notifications = '/notifications';
}

class _RouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription<dynamic> _sub;
  _RouterRefreshNotifier(WidgetRef ref) {
    _sub = ref.listenManual(authStateProvider, (prev, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

String _resolveInitialLocation(WidgetRef ref) {
  try {
    final prefs = ref.read(prefsProvider);
    if (!prefs.isOnboardingDone) return AppRoutes.onboarding;
    final user = ref.read(authStateProvider).value;
    if (user == null) return AppRoutes.signIn;
    if (prefs.biometricEnabled) return AppRoutes.lock;
    return AppRoutes.home;
  } catch (_) {
    return AppRoutes.signIn;
  }
}

GoRouter buildRouter(WidgetRef ref) {
  final refresh = _RouterRefreshNotifier(ref);
  return GoRouter(
    initialLocation: _resolveInitialLocation(ref),
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash path is just a decision stub — never render, always redirect.
      if (loc == AppRoutes.splash) {
        return _resolveInitialLocation(ref);
      }

      final auth = ref.read(authStateProvider);
      final loggedIn = auth.value != null;

      if (loc == AppRoutes.onboarding) return null;
      if (loc == AppRoutes.lock) return null;

      const authPaths = [
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgot,
      ];

      if (!loggedIn && !authPaths.contains(loc)) {
        return AppRoutes.signIn;
      }
      if (loggedIn && authPaths.contains(loc)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        redirect: (context, state) => _resolveInitialLocation(ref),
      ),
      GoRoute(
        path: AppRoutes.lock,
        builder: (_, __) => const LockScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.noteEditor}/:id',
        builder: (_, st) =>
            NoteEditorScreen(noteId: st.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (_, __) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.workspaces,
        builder: (_, __) => const WorkspaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, __) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.friends,
        builder: (_, __) => const FriendsScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrCode,
        builder: (_, __) => const QrCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.usernameSetup,
        builder: (_, __) => const UsernameSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(path: AppRoutes.about, builder: (_, __) => const AboutScreen()),
      GoRoute(path: AppRoutes.privacy, builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: AppRoutes.contact, builder: (_, __) => const ContactScreen()),
      GoRoute(
        path: AppRoutes.dataUsage,
        builder: (_, __) => const DataUsageScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionTerms,
        builder: (_, __) => const SubscriptionTermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (_, st) => Scaffold(
      body: Center(child: Text('Not found: ${st.matchedLocation}')),
    ),
  );
}
