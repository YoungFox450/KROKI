import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/terms_of_use_screen.dart';
import '../../features/settings/cosmetics_screen.dart';
import '../../features/social/private_chat_screen.dart';
import '../../features/social/social_screen.dart';
import '../../features/replay/replay_screen.dart';
import '../../features/spectator/spectator_screen.dart';
import '../../features/solo/solo_training_screen.dart';
import '../../data/models/user_model.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter() {
  final authRefresh = _AuthRefresh();
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isSignedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!isSignedIn && !isAuthRoute) return '/login';
      if (isSignedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (_, state) => ProfileScreen(user: state.extra! as UserModel)),
      GoRoute(
        path: '/lobby/:roomCode',
        builder: (_, state) => LobbyScreen(
          roomCode: state.pathParameters['roomCode']!,
          isHost: state.uri.queryParameters['host'] == 'true',
        ),
      ),
      GoRoute(
        path: '/game/:roomCode',
        builder: (_, state) => GameScreen(
          roomCode: state.pathParameters['roomCode']!,
          isHost: state.uri.queryParameters['host'] == 'true',
        ),
      ),
      GoRoute(path: '/social', builder: (_, __) => const SocialScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsOfUseScreen()),
      GoRoute(path: '/cosmetics', builder: (_, __) => const CosmeticsScreen()),
      GoRoute(path: '/chat', builder: (_, state) => PrivateChatScreen(friend: state.extra! as UserModel)),
      GoRoute(path: '/replay/:roomCode', builder: (_, state) => ReplayScreen(roomCode: state.pathParameters['roomCode']!)),
      GoRoute(path: '/spectate/:roomCode', builder: (_, state) => SpectatorScreen(roomCode: state.pathParameters['roomCode']!)),
      GoRoute(path: '/solo', builder: (_, __) => const SoloTrainingScreen()),
    ],
  );
}
