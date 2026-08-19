import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/models/user_model.dart';

class PrivateChatScreen extends StatefulWidget {
  final UserModel friend;
  const PrivateChatScreen({super.key, required this.friend});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _chatId {
    List<String> ids = [_myUid, widget.friend.uid];
    ids.sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() async {
    var snap = await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(_chatId)
        .collection('messages')
        .where('senderUid', isEqualTo: widget.friend.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      doc.reference.update({'isRead': true});
    }

    await FirebaseFirestore.instance.collection('private_chats').doc(_chatId).set({
      'unreadCount_$_myUid': 0,
    }, SetOptions(merge: true));
  }

  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    final timestamp = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderUid': _myUid,
      'text': text,
      'createdAt': timestamp,
      'isRead': false,
    });

    await FirebaseFirestore.instance.collection('private_chats').doc(_chatId).set({
      'participants': [_myUid, widget.friend.uid],
      'lastMessage': text,
      'lastSenderUid': _myUid,
      'updatedAt': timestamp,
      'unreadCount_$_myUid': 0,
      'unreadCount_${widget.friend.uid}': FieldValue.increment(1),
    }, SetOptions(merge: true));

    _messageController.clear();
    _scrollToBottom();
  }

  void _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(_chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  void _showOptions(String messageId, String text, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Colors.white70),
            title: const Text('Copier le texte'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte copié !'), behavior: SnackBarBehavior.floating));
            },
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Supprimer pour tout le monde', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                _deleteMessage(messageId);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
                  child: Text(widget.friend.pseudo[0].toUpperCase(),
                      style: const TextStyle(fontSize: 16, color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
                ),
                if (widget.friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.friend.pseudo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    widget.friend.isOnline ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.friend.isOnline ? Colors.greenAccent : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('private_chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderUid'] == _myUid;
                    Timestamp? ts = data['createdAt'] as Timestamp?;
                    String time = ts != null ? DateFormat('HH:mm').format(ts.toDate()) : '';
                    bool isRead = data['isRead'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onLongPress: () => _showOptions(docs[index].id, data['text'], isMe),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isMe) ...[
                                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.white24)),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF7C4DFF) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(isMe ? 20 : 0),
                                        bottomRight: Radius.circular(isMe ? 0 : 20),
                                      ),
                                    ),
                                    child: Text(
                                      data['text'],
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                ),
                                if (!isMe) ...[
                                  const SizedBox(width: 8),
                                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.white24)),
                                ],
                              ],
                            ),
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 4),
                                child: Icon(
                                  Icons.done_all_rounded,
                                  size: 14,
                                  color: isRead ? Colors.blueAccent : Colors.white24,
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
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Votre message...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7C4DFF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
