import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/drawing_service.dart';
import '../../data/services/game_logic_service.dart';
import '../../data/services/room_service.dart';
import '../../data/services/social_service.dart';
import '../../data/services/weekly_challenge_service.dart';
import '../../data/models/weekly_challenge.dart';
import '../../data/services/cosmetic_service.dart';
import '../../data/services/moderation_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/season_service.dart';
import '../../data/services/community_word_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final drawingServiceProvider = Provider<DrawingService>((ref) => DrawingService());
final roomServiceProvider = Provider<RoomService>((ref) => RoomService());
final socialServiceProvider = Provider<SocialService>((ref) => SocialService());
final weeklyChallengeServiceProvider = Provider<WeeklyChallengeService>((ref) => WeeklyChallengeService());
final cosmeticServiceProvider = Provider<CosmeticService>((ref) => CosmeticService());
final moderationServiceProvider = Provider<ModerationService>((ref) => ModerationService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final seasonServiceProvider = Provider<SeasonService>((ref) => SeasonService());
final communityWordServiceProvider = Provider<CommunityWordService>((ref) => CommunityWordService());
final weeklyChallengeProvider = FutureProvider<WeeklyChallengeStatus>((ref) {
  return ref.watch(weeklyChallengeServiceProvider).loadStatus();
});

final gameLogicServiceProvider = Provider<GameLogicService>((ref) {
  final service = GameLogicService(
    drawingService: ref.watch(drawingServiceProvider),
    seasonService: ref.watch(seasonServiceProvider),
    communityWords: ref.watch(communityWordServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
