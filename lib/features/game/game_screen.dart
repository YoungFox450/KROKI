import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/drawing_stroke.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_model.dart';
import '../../data/services/drawing_service.dart';
import '../../data/services/chat_service.dart';
import 'widgets/drawing_canvas.dart';

class GameScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final DrawingService _drawingService = DrawingService();
  final ChatService _chatService = ChatService();
  final TextEditingController _guessController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  bool get _isDrawer => widget.isHost;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _currentUser = UserModel.fromMap(doc.data()!);
      });
    }
  }

  void _sendMessage() {
    String text = _guessController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    _chatService.sendMessage(
      roomCode: widget.roomCode,
      senderUid: _currentUser!.uid,
      senderPseudo: _currentUser!.pseudo,
      text: text,
      isCorrect: false, // La validation exacte du mot sera câblée avec la logique serveur
    );

    _guessController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDrawer ? 'Tu dessines !' : 'Devine le mot !'),
        actions: [
          if (_isDrawer)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _drawingService.clearCanvas(widget.roomCode),
              tooltip: 'Effacer le dessin',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. ZONE DE DESSIN (Ajustée à 50% de la hauteur)
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
                ),
                child: StreamBuilder<List<DrawingStroke>>(
                  stream: _drawingService.getStrokesStream(widget.roomCode),
                  builder: (context, snapshot) {
                    List<DrawingStroke> strokes = snapshot.data ?? [];
                    return DrawingCanvas(
                      strokes: strokes,
                      isDrawer: _isDrawer,
                      onStrokeCompleted: (stroke) {
                        _drawingService.sendStroke(widget.roomCode, stroke);
                      },
                    );
                  },
                ),
              ),
            ),

            // 2. ZONE DE TCHAT PUBLIQUE (Tout le monde voit ce que les autres écrivent)
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessagesStream(widget.roomCode),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<ChatMessage> messages = snapshot.data!;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        ChatMessage msg = messages[index];
                        bool isMe = msg.senderUid == FirebaseAuth.instance.currentUser?.uid;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${msg.senderPseudo} : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.deepPurpleAccent : Colors.amber,
                                  ),
                                ),
                                TextSpan(
                                  text: msg.text,
                                  style: TextStyle(
                                    color: msg.isCorrect ? Colors.greenAccent : Colors.white,
                                    fontWeight: msg.isCorrect ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // 3. BARRE DE SAISIE DE MESSAGE
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _guessController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isDrawer
                            ? 'Discute avec les joueurs...'
                            : 'Propose un mot...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}