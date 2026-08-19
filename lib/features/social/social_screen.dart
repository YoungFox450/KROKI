import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/social_service.dart';
import 'private_chat_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _myPseudo;

  @override
  void initState() {
    super.initState();
    _loadMyPseudo();
  }

  void _loadMyPseudo() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() => _myPseudo = doc.data()?['pseudo']);
    }
  }

  void _onSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    var results = await _socialService.searchUsers(_searchController.text.trim());
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOCIAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: 'Chercher un pseudo...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _isSearching 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: _onSearch),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var user = _searchResults[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.2), child: Text(user.pseudo[0].toUpperCase())),
                        const SizedBox(height: 8),
                        Text(user.pseudo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _socialService.sendFriendRequest(user, _myPseudo ?? 'Joueur');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée !'), behavior: SnackBarBehavior.floating));
                            setState(() => _searchResults.removeAt(index));
                          },
                          child: const Icon(Icons.add_circle_rounded, color: Color(0xFF7C4DFF), size: 24),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10),
          ],
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: const Color(0xFF7C4DFF),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelColor: Colors.white38,
                    tabs: [
                      const Tab(text: 'CHATS'),
                      const Tab(text: 'AMIS'),
                      Tab(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _socialService.getIncomingRequestsStream(),
                          builder: (context, snapshot) {
                            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('DEMANDES'),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRecentChats(),
                        _buildFriendsList(),
                        _buildRequestsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChats() {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('private_chats')
          .where('participants', arrayContains: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Aucun chat récent.', style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var chatData = docs[index].data() as Map<String, dynamic>;
            List<dynamic> participants = chatData['participants'];
            String friendUid = participants.firstWhere((id) => id != myUid);
            int unreadCount = chatData['unreadCount_$myUid'] ?? 0;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return const SizedBox();
                if (!userSnap.hasData || userSnap.data?.data() == null) return const SizedBox();
                var friend = UserModel.fromMap(userSnap.data!.data() as Map<String, dynamic>);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(friend: friend))),
                      leading: Stack(
                        children: [
                          CircleAvatar(backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1), child: Text(friend.pseudo[0].toUpperCase(), style: const TextStyle(color: Color(0xFF7C4DFF)))),
                          if (friend.isOnline) Positioned(right: 0, bottom: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle))),
                        ],
                      ),
                      title: Text(friend.pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(chatData['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unreadCount > 0 ? Colors.white : Colors.white38)),
                      trailing: unreadCount > 0 
                        ? Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle), child: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                        : null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<UserModel>>(
      stream: _socialService.getFriendsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var friends = snapshot.data!;
        if (friends.isEmpty) return const Center(child: Text('Liste d\'amis vide.', style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            var friend = friends[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1), child: Text(friend.pseudo[0].toUpperCase(), style: const TextStyle(color: Color(0xFF7C4DFF)))),
                  title: Text(friend.pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(friend.isOnline ? 'En ligne' : 'Hors ligne', style: TextStyle(color: friend.isOnline ? Colors.greenAccent : Colors.white38, fontSize: 11)),
                  trailing: IconButton(icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C4DFF)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(friend: friend)))),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _socialService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Aucune demande.', style: TextStyle(color: Colors.white38)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: Colors.white10, child: Text(data['fromPseudo'][0].toUpperCase())),
                  const SizedBox(width: 12),
                  Expanded(child: Text(data['fromPseudo'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.check_rounded, color: Colors.greenAccent), onPressed: () => _socialService.acceptFriendRequest(docs[index].id, data['fromUid'])),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.redAccent), onPressed: () => _socialService.rejectFriendRequest(docs[index].id)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
