import 'package:firebase_database/firebase_database.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Envoyer un message dans le tchat de la salle
  Future<void> sendMessage({
    required String roomCode,
    required String senderUid,
    required String senderPseudo,
    required String text,
    bool isCorrect = false,
  }) async {
    final ref = _db.ref('chats/$roomCode').push();
    final message = ChatMessage(
      senderUid: senderUid,
      senderPseudo: senderPseudo,
      text: text,
      isCorrect: isCorrect,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(message.toMap());
  }

  // Stream pour lire les messages du tchat en temps réel
  Stream<List<ChatMessage>> getMessagesStream(String roomCode) {
    return _db.ref('chats/$roomCode').onValue.map((event) {
      if (event.snapshot.value == null) return [];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<ChatMessage> messages = [];

      data.forEach((key, value) {
        messages.add(ChatMessage.fromMap(Map<String, dynamic>.from(value)));
      });

      // Trier par ordre chronologique
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }
}