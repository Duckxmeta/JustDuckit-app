import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';
import '../models/incubation_batch.dart';
import '../services/task_engine.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  // Local cache of completed task states mapped by task.id
  final Map<String, bool> _completedTasksMap = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Care Checklist'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('incubation_batches')
            .where('uid', isEqualTo: user?.uid ?? 'anonymous')
            .snapshots(),
        builder: (context, batchesSnapshot) {
          if (batchesSnapshot.hasError) {
            return Center(child: Text('Error loading batches: ${batchesSnapshot.error}'));
          }
          if (batchesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final batches = batchesSnapshot.data!.docs
              .map((doc) => IncubationBatch.fromFirestore(doc))
              .toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('birds')
                .where('uid', isEqualTo: user?.uid ?? 'anonymous')
                .snapshots(),
            builder: (context, birdsSnapshot) {
              if (birdsSnapshot.hasError) {
                return Center(child: Text('Error loading birds: ${birdsSnapshot.error}'));
              }
              if (birdsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final birds = birdsSnapshot.data!.docs
                  .map((doc) => Bird.fromFirestore(doc))
                  .toList();

              // Generate tasks based on engine rules
              final allTasks = TaskEngine.generateTasks(birds: birds, batches: batches);

              // Apply completed states from map
              for (final task in allTasks) {
                task.isCompleted = _completedTasksMap[task.id] ?? false;
              }

              if (allTasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No tasks generated for today! Enjoy your quiet day.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              final completedCount = allTasks.where((t) => t.isCompleted).length;
              final progress = allTasks.isNotEmpty ? completedCount / allTasks.length : 0.0;

              // Group tasks
              final urgentTasks = allTasks.where((t) => t.category == 'Urgent').toList();
              final morningTasks = allTasks.where((t) => t.category == 'Morning').toList();
              final eveningTasks = allTasks.where((t) => t.category == 'Evening').toList();
              final generalTasks = allTasks.where((t) => t.category == 'General').toList();

              return Column(
                children: [
                  // Progress Card
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Today\'s Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              Text(
                                '$completedCount / ${allTasks.length} Done',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.teal.shade50,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Scrollable tasks list
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        if (urgentTasks.isNotEmpty)
                          _buildCategoryGroup(
                            title: '🚨 Urgent Alerts',
                            tasks: urgentTasks,
                            cardColor: Colors.orange.shade50,
                            borderColor: Colors.orange,
                          ),
                        if (morningTasks.isNotEmpty)
                          _buildCategoryGroup(
                            title: '🌅 Morning Routine',
                            tasks: morningTasks,
                          ),
                        if (eveningTasks.isNotEmpty)
                          _buildCategoryGroup(
                            title: '🌙 Evening Lockdown',
                            tasks: eveningTasks,
                          ),
                        if (generalTasks.isNotEmpty)
                          _buildCategoryGroup(
                            title: '📅 General Care',
                            tasks: generalTasks,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup({
    required String title,
    required List<GeneratedTask> tasks,
    Color? cardColor,
    Color? borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
          ),
        ),
        Card(
          color: cardColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.5)
                : BorderSide(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return CheckboxListTile(
                value: task.isCompleted,
                activeColor: Colors.teal,
                title: Row(
                  children: [
                    Text(
                      task.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 4.0),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      color: task.isCompleted ? Colors.grey.shade500 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _completedTasksMap[task.id] = value;
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
