import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/drawing_stroke.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_model.dart';
import '../../data/models/cosmetic.dart';
import '../../core/providers/service_providers.dart';
import '../../core/settings_provider.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/drawing_service.dart';
import '../../data/services/game_logic_service.dart';
import 'widgets/drawing_canvas.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

enum HapticType { selection, light, medium, heavy }

class NamedColor {
  final String name;
  final Color color;
  const NamedColor(this.name, this.color);
}

final List<NamedColor> _standardPalette = const [
  NamedColor('Blanc', Color(0xFFFFFFFF)),
  NamedColor('Noir', Color(0xFF111111)),
  NamedColor('Rouge Vif', Color(0xFFE53935)),
  NamedColor('Bleu Royal', Color(0xFF1565C0)),
  NamedColor('Vert Émeraude', Color(0xFF00897B)),
  NamedColor('Jaune Solaire', Color(0xFFFFB300)),
  NamedColor('Violet Électrique', Color(0xFF8E24AA)),
  NamedColor('Orange Fluo', Color(0xFFF4511E)),
  NamedColor('Rose Néon', Color(0xFFE91E63)),
  NamedColor('Cyan Ciel', Color(0xFF00BCD4)),
  NamedColor('Marron Chocolat', Color(0xFF795548)),
  NamedColor('Gris Anthracite', Color(0xFF607D8B)),
];

final List<NamedColor> _colorblindPalette = const [
  NamedColor('Noir Profond', Color(0xFF000000)),
  NamedColor('Orange Vif', Color(0xFFE69F00)),
  NamedColor('Bleu Ciel', Color(0xFF56B4E9)),
  NamedColor('Vert Bluish', Color(0xFF009E73)),
  NamedColor('Jaune Vif', Color(0xFFF0E442)),
  NamedColor('Bleu Marine', Color(0xFF0072B2)),
  NamedColor('Vermillon', Color(0xFFD55E00)),
  NamedColor('Violet Reddish', Color(0xFFCC79A7)),
  NamedColor('Blanc Intratable', Color(0xFFFFFFFF)),
];

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  final TextEditingController _guessController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  String _currentWord = '';
  String _drawerUid = '';
  String _gameMode = 'classic';
  String _status = 'active';
  int _timeLeft = 60;
  int _cooldownLeft = 15;
  int _currentRound = 1;
  int _maxRounds = 3;
  bool _hasGuessedCorrectly = false;
  bool _hasHandledClosed = false;
  final List<DrawingStroke> _undoStack = [];
  final List<DrawingStroke> _redoStack = [];

  // Drawing state
  Color _selectedColor = Colors.white;
  double _selectedWidth = 4.0;
  bool _isEraser = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAssignedDrawer => _myUid == _drawerUid;
  bool get _isDrawer => _isAssignedDrawer || _gameMode == 'cooperative';

  DrawingService get _drawingService => ref.read(drawingServiceProvider);
  ChatService get _chatService => ref.read(chatServiceProvider);
  GameLogicService get _gameLogicService => ref.read(gameLogicServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _loadCosmetics();
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

    if (_isAssignedDrawer || _hasGuessedCorrectly) return;

    String senderPseudo = _currentUser?.pseudo ?? 'Joueur';
    bool isMatch = text.toUpperCase() == _currentWord.toUpperCase();

    if (isMatch) {
      _triggerHaptic(HapticType.heavy);
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
      await ref.read(weeklyChallengeServiceProvider).addProgress(1);
      ref.invalidate(weeklyChallengeProvider);

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
          _gameMode = roomData['gameMode'] ?? 'classic';
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
                            : (_isAssignedDrawer && _gameMode != 'cooperative'
                                ? 'MOT : $_currentWord'
                                : (_gameMode == 'cooperative' ? 'COOPÉRATIF' : 'DEVINE !')),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return Column(
                    children: [
                      if (hostDisconnectedAt != null) _buildHostDisconnectBanner(),
                      _buildPlayersList(),
                      if (isWide)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildDrawingArea(),
                                    if (_isDrawer && _status == 'active') _buildDrawingTools(),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [_buildChatArea(), _buildInputArea()],
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildDrawingArea(),
                        if (_isDrawer && _status == 'active') _buildDrawingTools(),
                        _buildChatArea(),
                        _buildInputArea(),
                      ],
                    ],
                  );
                },
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
                    isEraser: _isEraser,
                    onStrokeCompleted: _handleStroke,
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

  void _triggerHaptic(HapticType type) {
    if (!ref.read(settingsProvider).hapticEnabled) return;
    switch (type) {
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> _handleStroke(DrawingStroke stroke) async {
    _triggerHaptic(HapticType.selection);
    final id = await _drawingService.sendStroke(widget.roomCode, stroke);
    if (!mounted) return;
    setState(() {
      _undoStack.add(DrawingStroke(
        id: id,
        points: stroke.points,
        colorHex: stroke.colorHex,
        strokeWidth: stroke.strokeWidth,
        isEraser: stroke.isEraser,
      ));
      _redoStack.clear();
    });
  }

  Future<void> _loadCosmetics() async {
    final id = await ref.read(cosmeticServiceProvider).selectedId(CosmeticType.color);
    final matches = CosmeticCatalog.items.where((item) => item.id == id).toList();
    if (matches.isNotEmpty && mounted) setState(() => _selectedColor = Color(matches.first.color));
  }

  Future<void> _undo() async {
    if (_undoStack.isEmpty) return;
    final stroke = _undoStack.removeLast();
    if (stroke.id != null) await _drawingService.deleteStroke(widget.roomCode, stroke.id!);
    if (!mounted) return;
    _triggerHaptic(HapticType.light);
    setState(() => _redoStack.add(stroke));
  }

  Future<void> _redo() async {
    if (_redoStack.isEmpty) return;
    final stroke = _redoStack.removeLast();
    final id = await _drawingService.sendStroke(widget.roomCode, stroke);
    if (!mounted) return;
    _triggerHaptic(HapticType.light);
    setState(() => _undoStack.add(DrawingStroke(
          id: id,
          points: stroke.points,
          colorHex: stroke.colorHex,
          strokeWidth: stroke.strokeWidth,
          isEraser: stroke.isEraser,
        )));
  }

  Future<void> _clearDrawing() async {
    await _drawingService.clearCanvas(widget.roomCode);
    if (!mounted) return;
    _triggerHaptic(HapticType.medium);
    setState(() {
      _undoStack.clear();
      _redoStack.clear();
    });
  }

  Widget _buildDrawingTools() {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final palette = settings.colorblindMode ? _colorblindPalette : _standardPalette;

    return Semantics(
      container: true,
      label: 'Outils de dessin',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Pinceau',
                onPressed: () {
                  _triggerHaptic(HapticType.selection);
                  setState(() => _isEraser = false);
                },
                isSelected: !_isEraser,
                icon: const Icon(Icons.brush),
              ),
              IconButton.filledTonal(
                tooltip: 'Gomme',
                onPressed: () {
                  _triggerHaptic(HapticType.selection);
                  setState(() => _isEraser = true);
                },
                isSelected: _isEraser,
                icon: const Icon(Icons.auto_fix_high),
              ),
              IconButton(
                tooltip: 'Annuler le dernier trait',
                onPressed: _undoStack.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: 'Rétablir le dernier trait',
                onPressed: _redoStack.isEmpty ? null : _redo,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                tooltip: 'Tout effacer',
                onPressed: _undoStack.isEmpty ? null : _clearDrawing,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
              IconButton(
                tooltip: settings.colorblindMode ? 'Palette Standard' : 'Palette Daltonienne',
                onPressed: () {
                  _triggerHaptic(HapticType.light);
                  notifier.toggleColorblindMode(!settings.colorblindMode);
                },
                icon: Icon(
                  settings.colorblindMode ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                  color: settings.colorblindMode ? Colors.amber : Colors.white70,
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedWidth,
            min: 2,
            max: 24,
            divisions: 11,
            label: 'Taille ${_selectedWidth.round()}',
            onChanged: (value) => setState(() => _selectedWidth = value),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: palette.length,
              itemBuilder: (context, index) {
                final item = palette[index];
                final isSelected = !_isEraser && _selectedColor == item.color;
                return Tooltip(
                  message: item.name,
                  child: Semantics(
                    button: true,
                    label: 'Couleur : ${item.name}',
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {
                        _triggerHaptic(HapticType.selection);
                        setState(() {
                          _selectedColor = item.color;
                          _isEraser = false;
                        });
                      },
                      child: Container(
                        width: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.white54,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: settings.colorblindMode
                            ? Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
              enabled: _status == 'intermission' || (!_isAssignedDrawer && !_hasGuessedCorrectly),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
              hintText: _isAssignedDrawer && _gameMode != 'cooperative' ? 'Vous dessinez...' : 'Votre réponse...',
                fillColor: Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: (_status == 'intermission' || (!_isAssignedDrawer && !_hasGuessedCorrectly)) ? _sendMessage : null,
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
