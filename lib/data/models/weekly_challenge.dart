class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;

  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
  });
}

class WeeklyChallengeStatus {
  final WeeklyChallenge challenge;
  final int progress;

  const WeeklyChallengeStatus({required this.challenge, required this.progress});

  double get ratio => (progress / challenge.target).clamp(0.0, 1.0).toDouble();
  bool get isComplete => progress >= challenge.target;
}
