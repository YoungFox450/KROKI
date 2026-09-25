import 'package:shared_preferences/shared_preferences.dart';

import '../models/weekly_challenge.dart';

class WeeklyChallengeService {
  static const _challenges = <WeeklyChallenge>[
    WeeklyChallenge(id: 'draw-animals', title: 'Safari de Kin', description: 'Gagne 3 parties avec un thème animaux.', target: 3),
    WeeklyChallenge(id: 'draw-kin', title: 'Ambiance kinoise', description: 'Joue 5 parties avec le pack Kinshasa.', target: 5),
    WeeklyChallenge(id: 'guess-fast', title: 'Œil rapide', description: 'Trouve 10 mots avant la fin du tour.', target: 10),
  ];

  WeeklyChallenge get current {
    final week = DateTime.now().difference(DateTime.utc(2024, 1, 1)).inDays ~/ 7;
    return _challenges[week % _challenges.length];
  }

  Future<WeeklyChallengeStatus> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final challenge = current;
    final progress = prefs.getInt('weekly_progress_${challenge.id}') ?? 0;
    return WeeklyChallengeStatus(challenge: challenge, progress: progress);
  }

  Future<void> addProgress(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final challenge = current;
    final key = 'weekly_progress_${challenge.id}';
    final progress = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, (progress + amount).clamp(0, challenge.target).toInt());
  }
}
