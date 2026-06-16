import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsStreamProvider);
    final todays = ref.watch(todaysAttendanceProvider);
    final repo = ref.read(firestoreRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('حضور اليوم')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب للتسجيل'));
          }
          final map = <String, AttendanceStatus>{};
          todays.maybeWhen(
            data: (records) {
              for (final r in records) {
                map[r.studentId] = r.status;
              }
            },
            orElse: () {},
          );
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = list[i];
              final status = map[s.id];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(.15),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(s.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600))),
                      _StatusBtn(
                        icon: Icons.check,
                        color: Colors.green,
                        selected: status == AttendanceStatus.present,
                        onTap: () => repo.setAttendance(AttendanceRecord(
                            id: '',
                            studentId: s.id,
                            date: DateTime.now(),
                            status: AttendanceStatus.present)),
                      ),
                      _StatusBtn(
                        icon: Icons.access_time,
                        color: Colors.orange,
                        selected: status == AttendanceStatus.late,
                        onTap: () => repo.setAttendance(AttendanceRecord(
                            id: '',
                            studentId: s.id,
                            date: DateTime.now(),
                            status: AttendanceStatus.late)),
                      ),
                      _StatusBtn(
                        icon: Icons.close,
                        color: Colors.red,
                        selected: status == AttendanceStatus.absent,
                        onTap: () => repo.setAttendance(AttendanceRecord(
                            id: '',
                            studentId: s.id,
                            date: DateTime.now(),
                            status: AttendanceStatus.absent)),
                      ),
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
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn(
      {required this.icon,
      required this.color,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: selected ? Colors.white : color, size: 20),
        ),
      ),
    );
  }
}
