import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'admin_login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = FirebaseService();

  @override
  void initState() {
    super.initState();
    _autoDeleteOldUpdates();
  }

  // ── Auto-delete updates older than 24h, always keep latest (index 0) ──
  Future<void> _autoDeleteOldUpdates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('updates')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      for (int i = 1; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final ts = (doc.data())['timestamp'];
        if (ts is Timestamp && ts.toDate().isBefore(cutoff)) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Auto-delete error: $e');
    }
  }

  // ── "X ago" label ──
  String _formatTimeAgo(dynamic ts) {
    if (ts == null) return '';
    if (ts is! Timestamp) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Full date + time ──
  String _formatFull(dynamic ts) {
    if (ts == null || ts is! Timestamp) return '';
    final dt = ts.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  •  $hour:$min $period';
  }

  // ── Is older than 20h (near expiry) ──
  bool _isNearExpiry(dynamic ts) {
    if (ts == null || ts is! Timestamp) return false;
    return DateTime.now().difference(ts.toDate()).inHours >= 20;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: StreamBuilder(
        stream: service.getUpdates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return RefreshIndicator(
            color: const Color(0xFF0D47A1),
            onRefresh: () async => _autoDeleteOldUpdates(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Latest pinned card
                _buildLatestCard(docs[0]),

                // History section
                if (docs.length > 1) ...[
                  _buildHistoryHeader(docs.length - 1),
                  ...List.generate(
                    docs.length - 1,
                        (i) => _buildHistoryItem(docs[i + 1]),
                  ),
                ] else
                  _buildNoHistoryNote(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAdminButton(context),
    );
  }

  // ── AppBar ──
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D47A1),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Metro Updates",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF69F0AE), size: 8),
              SizedBox(width: 5),
              Text("Live", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Latest Card (always pinned) ──
  Widget _buildLatestCard(QueryDocumentSnapshot doc) {
    final message = doc['message'] ?? '';
    final ts = (doc.data() as Map?)?['timestamp'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "LATEST UPDATE",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_formatTimeAgo(ts).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatTimeAgo(ts),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Message
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Full date
          if (_formatFull(ts).isNotEmpty)
            Text(
              _formatFull(ts),
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
              ),
            ),

          const SizedBox(height: 10),

          // Pinned badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.push_pin_rounded, size: 11, color: Color(0xFF69F0AE)),
                SizedBox(width: 4),
                Text(
                  "Pinned",
                  style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── History Section Header ──
  Widget _buildHistoryHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: Color(0xFF0D47A1)),
              SizedBox(width: 6),
              Text(
                "Update History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$count update${count == 1 ? '' : 's'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.orange.shade700),
                    const SizedBox(width: 3),
                    Text(
                      "Auto-delete 24h",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── History Item ──
  Widget _buildHistoryItem(QueryDocumentSnapshot doc) {
    final message = doc['message'] ?? '';
    final ts = (doc.data() as Map?)?['timestamp'];
    final nearExpiry = _isNearExpiry(ts);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: nearExpiry ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: nearExpiry
                    ? Colors.orange.shade50
                    : const Color(0xFF0D47A1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.train_rounded,
                color: nearExpiry
                    ? Colors.orange.shade600
                    : const Color(0xFF0D47A1),
                size: 22,
              ),
            ),
            title: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Metro Service Update",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (_formatFull(ts).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _formatFull(ts),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: nearExpiry
                    ? Colors.orange.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatTimeAgo(ts),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: nearExpiry
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),

          // Expiry warning bar
          if (nearExpiry)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 12, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "Expiring soon — will be deleted automatically",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── No History Note ──
  Widget _buildNoHistoryNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No previous updates yet. History appears here and auto-deletes after 24 hours.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.train_rounded,
              size: 40,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No updates yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Check back soon",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Admin FAB (long press to access) ──
  Widget _buildAdminButton(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLogin()),
        );
      },
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: () {},
        child: const Icon(Icons.lock_outline, color: Colors.white),
      ),
    );
  }
}