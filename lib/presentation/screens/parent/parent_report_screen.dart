import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/latin_digits.dart';
import '../../../domain/entities/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/progress_chart.dart';

String _fmt(String pattern, DateTime d) =>
    toLatinDigits(DateFormat(pattern, 'ar').format(d));

class ParentReportScreen extends ConsumerStatefulWidget {
  const ParentReportScreen({super.key, required this.token});
  final String token;
  @override
  ConsumerState<ParentReportScreen> createState() =>
      _ParentReportScreenState();
}

class _ParentReportScreenState extends ConsumerState<ParentReportScreen> {
  String? _studentId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final id = await ref
        .read(firestoreRepositoryProvider)
        .resolveToken(widget.token);
    if (mounted) setState(() {
      _studentId = id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_studentId == null) {
      return const Scaffold(
        body: Center(
            child: Text('الرابط غير صالح أو منتهٍ',
                style: TextStyle(fontSize: 16))),
      );
    }

    final id = _studentId!;
    final studentAsync = ref.watch(studentProvider(id));
    final sessions = ref.watch(sessionsProvider(id));
    final attendance = ref.watch(attendanceProvider(id));
    final notes = ref.watch(notesProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير الطالب')),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (s) {
          if (s == null) return const Center(child: Text('غير موجود'));
          final attList = attendance.valueOrNull ?? <AttendanceRecord>[];
          final present = attList
              .where((a) => a.status == AttendanceStatus.present)
              .length;
          final rate = attList.isEmpty
              ? 0.0
              : (present / attList.length) * 100;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          '${s.currentSurah} • الآية ${s.currentAyahStart}-${s.currentAyahEnd}',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: s.progressPercent / 100,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 6),
                      Text('${s.progressPercent.toStringAsFixed(0)}% من التقدم',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الحضور',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('${rate.toStringAsFixed(0)} % نسبة الحضور',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('${attList.length} جلسة مسجلة',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('تطور الجلسات',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ProgressChart(
                            sessions: sessions.valueOrNull ?? const []),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('آخر الجلسات',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ...(sessions.valueOrNull ?? const []).take(5).map((s) => Card(
                    child: ListTile(
                      title: Text('${s.surah} ${s.ayahStart}-${s.ayahEnd}'),
                      subtitle: Text(_fmt('dd MMM yyyy', s.timestamp)),
                      trailing: Text(s.rating.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  )),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('ملاحظات المعلم',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ...(notes.valueOrNull ?? const []).map((n) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.content),
                          const SizedBox(height: 4),
                          Text(_fmt('dd MMM yyyy', n.createdAt),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
