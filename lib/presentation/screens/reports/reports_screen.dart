import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا توجد بيانات'));
          final avg = list.isEmpty
              ? 0.0
              : list.map((s) => s.progressPercent).reduce((a, b) => a + b) /
                  list.length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('متوسط التقدم',
                          style: TextStyle(
                              fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text('${avg.toStringAsFixed(1)} %',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: avg / 100,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...list.map((s) => Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                          '${s.currentSurah} • ${s.currentAyahStart}-${s.currentAyahEnd}'),
                      trailing: Text('${s.progressPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
