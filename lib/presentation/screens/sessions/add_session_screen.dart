import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/session.dart';
import '../../providers/auth_provider.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  const AddSessionScreen({super.key, required this.studentId});
  final String studentId;
  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  SessionType _type = SessionType.memorization;
  String _surah = AppConstants.surahs.first;
  final _ayahStart = TextEditingController(text: '1');
  final _ayahEnd = TextEditingController(text: '7');
  SessionRating _rating = SessionRating.good;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final s = await ref
          .read(firestoreRepositoryProvider)
          .getStudent(widget.studentId);
      if (s != null && mounted) {
        setState(() {
          _surah = s.currentSurah;
          _ayahStart.text = s.currentAyahStart.toString();
          _ayahEnd.text = s.currentAyahEnd.toString();
        });
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(firestoreRepositoryProvider);
    final session = SessionEntity(
      id: '',
      studentId: widget.studentId,
      type: _type,
      surah: _surah,
      ayahStart: int.tryParse(_ayahStart.text) ?? 1,
      ayahEnd: int.tryParse(_ayahEnd.text) ?? 1,
      rating: _rating,
      mistakes: const [],
      notes: _notes.text.trim(),
      timestamp: DateTime.now(),
    );
    await repo.addSession(session);

    final s = await repo.getStudent(widget.studentId);
    if (s != null) {
      final newProgress = (s.progressPercent +
              (_rating == SessionRating.weak ? 0.5 : 1.5))
          .clamp(0, 100)
          .toDouble();
      await repo.updateStudent(s.copyWith(
        currentSurah: _surah,
        currentAyahStart: session.ayahStart,
        currentAyahEnd: session.ayahEnd,
        progressPercent: newProgress,
      ));
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جلسة جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<SessionType>(
            segments: const [
              ButtonSegment(
                  value: SessionType.memorization,
                  label: Text('حفظ'),
                  icon: Icon(Icons.menu_book)),
              ButtonSegment(
                  value: SessionType.revision,
                  label: Text('مراجعة'),
                  icon: Icon(Icons.refresh)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _surah,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'السورة'),
            items: AppConstants.surahs
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _surah = v ?? _surah),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _ayahStart,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'من الآية'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _ayahEnd,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'إلى الآية'))),
          ]),
          const SizedBox(height: 20),
          const Text('التقييم',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: SessionRating.values.map((r) {
              final selected = r == _rating;
              final color = r == SessionRating.excellent
                  ? Colors.green
                  : r == SessionRating.good
                      ? Colors.orange
                      : Colors.red;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _rating = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(.15) : Colors.white,
                        border: Border.all(
                            color: selected ? color : Colors.grey.shade300,
                            width: selected ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Icon(Icons.star, color: color),
                        const SizedBox(height: 4),
                        Text(r.label,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}
