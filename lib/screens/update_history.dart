import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateHistoryScreen extends StatelessWidget {
   UpdateHistoryScreen({super.key});

  final FirebaseFirestore db = FirebaseFirestore.instance;

  String formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();

    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return "$day/$month/$year  $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Update History",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("updates")
            .orderBy("time", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D47A1),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                      Icons.history_rounded,
                      size: 40,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No history found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Updates will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return Column(
            children: [

              // ── Header Count ──
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "${docs.length} total update${docs.length == 1 ? '' : 's'} found",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];
                    String message = data["message"] ?? '';
                    String time = '';

                    if (data["time"] != null) {
                      time = formatTime(data["time"]);
                    }

                    bool isFirst = index == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isFirst
                            ? Border.all(
                          color: const Color(0xFF0D47A1),
                          width: 1.5,
                        )
                            : Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isFirst
                                ? const Color(0xFF0D47A1).withOpacity(0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isFirst
                                ? Icons.bolt_rounded
                                : Icons.history_rounded,
                            color: isFirst
                                ? const Color(0xFF0D47A1)
                                : Colors.grey.shade400,
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
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time.isEmpty ? 'Time unavailable' : time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (isFirst) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D47A1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Latest",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0D47A1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 13,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}