import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/drawing_stroke.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_model.dart';
import '../../data/services/drawing_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/game_logic_service.dart';
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final DrawingService _drawingService = DrawingService();
  final ChatService _chatService = ChatService();
  final GameLogicService _gameLogicService = GameLogicService();
  final TextEditingController _guessController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  String _currentWord = '';
  String _drawerUid = '';
  String _status = 'active';
  int _timeLeft = 60;
  int _cooldownLeft = 15;
  int _currentRound = 1;
  int _maxRounds = 3;
  bool _hasGuessedCorrectly = false;
  bool _hasHandledClosed = false;

  // Drawing state
  Color _selectedColor = Colors.white;
  double _selectedWidth = 4.0;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isDrawer => _myUid == _drawerUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    if (widget.isHost) {
      _gameLogicService.startTimer(widget.roomCode);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameLogicService.stopTimer();
    _guessController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isHost) return;
    var roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      roomRef.update({'hostDisconnectedAt': FieldValue.serverTimestamp()});
    } else if (state == AppLifecycleState.resumed) {
      roomRef.update({'hostDisconnectedAt': null});
    }
  }

  Future<void> _loadUserProfile() async {
    if (_myUid.isEmpty) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(_myUid).get();
    if (doc.exists && mounted) {
      setState(() => _currentUser = UserModel.fromMap(doc.data()!));
    }
  }

  Future<void> _confirmLeaveOrClose() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isHost ? 'Fermer le salon ?' : 'Quitter la partie ?'),
        content: Text(
          widget.isHost
              ? 'Si vous quittez, le salon sera fermé et tous les joueurs seront expulsés.'
              : 'Êtes-vous sûr de vouloir quitter la partie ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(100, 45)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.isHost ? 'FERMER' : 'QUITTER'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.isHost) {
        await _gameLogicService.closeRoom(widget.roomCode);
      } else {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _sendMessage() async {
    String text = _guessController.text.trim();
    if (text.isEmpty) return;

    if (_status == 'intermission') {
      _chatService.sendMessage(
        roomCode: widget.roomCode,
        senderUid: _myUid,
        senderPseudo: _currentUser?.pseudo ?? 'Joueur',
        text: text,
        isCorrect: false,
      );
      _guessController.clear();
      return;
    }

    if (_isDrawer || _hasGuessedCorrectly) return;

    String senderPseudo = _currentUser?.pseudo ?? 'Joueur';
    bool isMatch = text.toUpperCase() == _currentWord.toUpperCase();

    if (isMatch) {
      setState(() => _hasGuessedCorrectly = true);
      _chatService.sendMessage(
        roomCode: widget.roomCode,
        senderUid: _myUid,
        senderPseudo: senderPseudo,
        text: 'A TROUVÉ LE MOT ! 🎉',
        isCorrect: true,
      );

      int pointsEarned = await _gameLogicService.awardPoints(
        roomCode: widget.roomCode,
        playerUid: _myUid,
        timeLeft: _timeLeft,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Bravo ! +$pointsEarned points !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      _chatService.sendMessage(
        roomCode: widget.roomCode,
        senderUid: _myUid,
        senderPseudo: senderPseudo,
        text: text,
        isCorrect: false,
      );
    }
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).snapshots(),
      builder: (context, roomSnap) {
        if (roomSnap.hasData && roomSnap.data!.exists) {
          var roomData = roomSnap.data!.data() as Map<String, dynamic>;
          _status = roomData['status'] ?? 'active';
          _currentWord = roomData['currentWord'] ?? '';
          _drawerUid = roomData['drawerUid'] ?? '';
          _timeLeft = roomData['timeLeft'] ?? 60;
          _cooldownLeft = roomData['cooldownLeft'] ?? 15;
          _currentRound = roomData['currentRound'] ?? 1;
          _maxRounds = roomData['maxRounds'] ?? 3;
          Timestamp? hostDisconnectedAt = roomData['hostDisconnectedAt'];

          // RÉINITIALISATION DU STATUT "MOT TROUVÉ" À CHAQUE NOUVEAU TOUR OU PAUSE
          List<dynamic> guessedPlayers = roomData['guessedPlayers'] ?? [];
          if ((_status == 'intermission' || !guessedPlayers.contains(_myUid)) && _hasGuessedCorrectly) {
            _hasGuessedCorrectly = false;
          }

          if (_status == 'closed' && !_hasHandledClosed) {
            _hasHandledClosed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le salon a été fermé.'), behavior: SnackBarBehavior.floating),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }

          if (_status == 'ended') return _buildEndScreen();

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _confirmLeaveOrClose,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Text('$_currentRound/$_maxRounds', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        _status == 'intermission'
                            ? 'PRÉPARATION...'
                            : (_isDrawer ? 'MOT : $_currentWord' : 'DEVINE !'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _isDrawer ? const Color(0xFF7C4DFF) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTimerWidget(),
                ],
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (hostDisconnectedAt != null) _buildHostDisconnectBanner(),
                  _buildPlayersList(),
                  _buildDrawingArea(),
                  if (_isDrawer && _status == 'active') _buildColorPicker(),
                  _buildChatArea(),
                  _buildInputArea(),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildTimerWidget() {
    bool lowTime = _timeLeft <= 10 && _status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _status == 'intermission' ? Colors.amber : (lowTime ? Colors.redAccent : const Color(0xFF7C4DFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_status == 'intermission' ? _cooldownLeft : _timeLeft}s',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildHostDisconnectBanner() {
    return Container(
      color: Colors.redAccent,
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: const Text(
        '⚠️ Hôte déconnecté. Le salon fermera bientôt...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildPlayersList() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .collection('players')
            .orderBy('score', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          var players = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            itemBuilder: (context, index) {
              var p = players[index].data() as Map<String, dynamic>;
              bool isDrawer = p['uid'] == _drawerUid;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDrawer ? const Color(0xFF7C4DFF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: isDrawer ? const Color(0xFF7C4DFF) : Colors.transparent),
                ),
                child: Center(
                  child: Row(
                    children: [
                      Text(p['pseudo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('${p['score'] ?? 0}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawingArea() {
    return Expanded(
      flex: 5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              StreamBuilder<List<DrawingStroke>>(
                stream: _drawingService.getStrokesStream(widget.roomCode),
                builder: (context, snapshot) {
                  return DrawingCanvas(
                    strokes: snapshot.data ?? [],
                    isDrawer: _isDrawer && _status == 'active',
                    selectedColor: _selectedColor,
                    selectedWidth: _selectedWidth,
                    onStrokeCompleted: (stroke) => _drawingService.sendStroke(widget.roomCode, stroke),
                  );
                },
              ),
              if (_status == 'intermission') _buildIntermissionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntermissionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isDrawer ? 'C\'EST VOTRE TOUR ! 🎨' : 'PRÉPAREZ-VOUS !',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'La manche commence dans',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              Text(
                '$_cooldownLeft',
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF7C4DFF)),
              ),
              if (_isDrawer) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _gameLogicService.skipCooldown(widget.roomCode),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  child: const Text('DÉMARRER MAINTENANT'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.white, Colors.black, Colors.red, Colors.green, Colors.blue, 
      Colors.yellow, Colors.orange, Colors.pink, Colors.brown, Colors.purple
    ];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedColor == colors[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colors[index]),
            child: Container(
              width: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.amber : Colors.white24, width: isSelected ? 3 : 1),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StreamBuilder<List<ChatMessage>>(
          stream: _chatService.getMessagesStream(widget.roomCode),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var messages = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            return ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isMe = msg.senderUid == _myUid;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${msg.senderPseudo}: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? const Color(0xFF7C4DFF) : Colors.amber),
                        ),
                        TextSpan(
                          text: msg.text,
                          style: TextStyle(
                            color: msg.isCorrect ? Colors.greenAccent : Colors.white70,
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
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _guessController,
              enabled: _status == 'intermission' || (!_isDrawer && !_hasGuessedCorrectly),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isDrawer ? 'Vous dessinez...' : 'Votre réponse...',
                fillColor: Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: (_status == 'intermission' || (!_isDrawer && !_hasGuessedCorrectly)) ? _sendMessage : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildEndScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text('PARTIE TERMINÉE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 40),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomCode)
                      .collection('players')
                      .orderBy('score', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var players = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        var p = players[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(width: 16),
                              Text(p['pseudo'], style: const TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text('${p['score']} pts', style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w900)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('RETOUR À L\'ACCUEIL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
