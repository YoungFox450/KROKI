class UserModel {
  final String uid;
  final String email;
  final String pseudo;
  final int totalScore;
  final int gamesPlayed;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.pseudo,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'pseudo': pseudo,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      pseudo: map['pseudo'] ?? 'Joueur',
      totalScore: map['totalScore'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}