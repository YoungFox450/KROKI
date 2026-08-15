class ChatMessage {
  final String senderUid;
  final String senderPseudo;
  final String text;
  final bool isCorrect;
  final int timestamp;

  ChatMessage({
    required this.senderUid,
    required this.senderPseudo,
    required this.text,
    this.isCorrect = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderPseudo': senderPseudo,
      'text': text,
      'isCorrect': isCorrect,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderUid: map['senderUid'] ?? '',
      senderPseudo: map['senderPseudo'] ?? 'Joueur',
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      timestamp: map['timestamp'] ?? 0,
    );
  }
}