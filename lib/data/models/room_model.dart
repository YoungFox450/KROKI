class PlayerModel {
  final String uid;
  final String pseudo;
  final int score;
  final bool isHost;

  PlayerModel({
    required this.uid,
    required this.pseudo,
    this.score = 0,
    required this.isHost,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'pseudo': pseudo,
      'score': score,
      'isHost': isHost,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      uid: map['uid'] ?? '',
      pseudo: map['pseudo'] ?? 'Joueur',
      score: map['score'] ?? 0,
      isHost: map['isHost'] ?? false,
    );
  }
}

class RoomModel {
  final String code;
  final String hostId;
  final String status; // "lobby", "active", "intermission", "ended", "closed"
  final int currentRound;
  final int maxRounds;
  final String? currentWord;
  final String? drawerUid;

  RoomModel({
    required this.code,
    required this.hostId,
    this.status = "lobby",
    this.currentRound = 0,
    this.maxRounds = 3,
    this.currentWord,
    this.drawerUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'hostId': hostId,
      'status': status,
      'currentRound': currentRound,
      'maxRounds': maxRounds,
      'currentWord': currentWord,
      'drawerUid': drawerUid,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      code: map['code'] ?? '',
      hostId: map['hostId'] ?? '',
      status: map['status'] ?? 'lobby',
      currentRound: map['currentRound'] ?? 0,
      maxRounds: map['maxRounds'] ?? 3,
      currentWord: map['currentWord'],
      drawerUid: map['drawerUid'],
    );
  }
}
