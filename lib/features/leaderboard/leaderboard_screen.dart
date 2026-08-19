import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/social_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CLASSEMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C4DFF),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'MONDIAL'),
            Tab(text: 'AMIS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorldLeaderboard(),
          _buildFriendsLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildWorldLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalScore', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
        return _buildList(users);
      },
    );
  }

  Widget _buildFriendsLeaderboard() {
    return StreamBuilder<List<UserModel>>(
      stream: _socialService.getFriendsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        List<UserModel> friends = snapshot.data!;
        
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(_myUid).snapshots(),
          builder: (context, mySnap) {
            if (!mySnap.hasData) return const Center(child: CircularProgressIndicator());
            
            UserModel me = UserModel.fromMap(mySnap.data!.data() as Map<String, dynamic>);
            List<UserModel> combinedList = [me, ...friends];
            combinedList.sort((a, b) => b.totalScore.compareTo(a.totalScore));
            
            return _buildList(combinedList);
          },
        );
      },
    );
  }

  Widget _buildList(List<UserModel> users) {
    if (users.isEmpty) return const Center(child: Text('Aucun joueur trouvé.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        var user = users[index];
        bool isMe = user.uid == _myUid;
        int rank = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF7C4DFF).withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMe ? const Color(0xFF7C4DFF) : Colors.transparent),
          ),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  rank <= 3 ? (rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉') : '#$rank',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(user.pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (user.isOnline) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
            trailing: Text(
              '${user.totalScore} PTS',
              style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}
