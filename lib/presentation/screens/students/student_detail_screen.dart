import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/latin_digits.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/progress_chart.dart';

String _fmt(String pattern, DateTime d) =>
    toLatinDigits(DateFormat(pattern, 'ar').format(d));

class StudentDetailScreen extends ConsumerStatefulWidget {
  const StudentDetailScreen({super.key, required this.studentId});
  final String studentId;
  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  Future<void> _addNote() async {
    final ctl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ملاحظة جديدة'),
        content: TextField(
          controller: ctl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'ملاحظة...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (saved == true && ctl.text.trim().isNotEmpty) {
      await ref.read(firestoreRepositoryProvider).addNote(Note(
            id: '',
            studentId: widget.studentId,
            content: ctl.text.trim(),
            createdAt: DateTime.now(),
          ));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف هذا الطالب؟'),
        content: const Text('هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(firestoreRepositoryProvider).deleteStudent(widget.studentId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentProvider(widget.studentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطالب'),
        actions: [
          IconButton(
              icon: const Icon(Icons.qr_code),
              tooltip: 'مشاركة التقرير',
              onPressed: () =>
                  context.push('/students/${widget.studentId}/share')),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete),
        ],
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'الجلسات'),
          Tab(text: 'الحضور'),
          Tab(text: 'الملاحظات'),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/students/${widget.studentId}/session'),
        icon: const Icon(Icons.add),
        label: const Text('جلسة'),
      ),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (s) {
          if (s == null) return const Center(child: Text('الطالب غير موجود'));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            '${s.currentSurah} • الآية ${s.currentAyahStart}-${s.currentAyahEnd}',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: s.progressPercent / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 4),
                        Text('${s.progressPercent.toStringAsFixed(0)}% من التقدم'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(controller: _tab, children: [
                  _SessionsTab(studentId: widget.studentId),
                  _AttendanceTab(studentId: widget.studentId),
                  _NotesTab(studentId: widget.studentId, onAdd: _addNote),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionsTab extends ConsumerWidget {
  const _SessionsTab({required this.studentId});
  final String studentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider(studentId));
    return sessions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('لا توجد جلسات'));
        return Column(
          children: [
            SizedBox(height: 180, child: ProgressChart(sessions: list)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = list[i];
                  Color c = switch (s.rating) {
                    SessionRating.excellent => Colors.green,
                    SessionRating.good => Colors.orange,
                    SessionRating.weak => Colors.red,
                  };
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: c.withOpacity(.15),
                          child: Icon(Icons.menu_book, color: c)),
                      title: Text('${s.surah} ${s.ayahStart}-${s.ayahEnd}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${s.type == SessionType.memorization ? "حفظ" : "مراجعة"} • ${_fmt('dd MMM HH:mm', s.timestamp)}'),
                      trailing: Text(s.rating.label,
                          style:
                              TextStyle(color: c, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.studentId});
  final String studentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final att = ref.watch(attendanceProvider(studentId));
    return att.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('لا يوجد سجل'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final a = list[i];
            final color = a.status.name == 'present'
                ? Colors.green
                : a.status.name == 'late'
                    ? Colors.orange
                    : Colors.red;
            return Card(
              child: ListTile(
                leading: Icon(Icons.circle, color: color, size: 14),
                title: Text(_fmt('EEEE dd MMM yyyy', a.date)),
                trailing: Text(a.status.label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.studentId, required this.onAdd});
  final String studentId;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider(studentId));
    return Stack(
      children: [
        notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
          data: (list) {
            if (list.isEmpty) return const Center(child: Text('لا توجد ملاحظات'));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list[i].content),
                      const SizedBox(height: 6),
                      Text(_fmt('dd MMM yyyy', list[i].createdAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'note-add',
            onPressed: onAdd,
            child: const Icon(Icons.note_add_outlined),
          ),
        ),
      ],
    );
  }
}
