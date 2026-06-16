import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/student.dart';
import '../../providers/auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});
  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _ayahStart = TextEditingController(text: '1');
  final _ayahEnd = TextEditingController(text: '7');
  String _surah = AppConstants.surahs.first;
  bool _saving = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final s = Student(
      id: '',
      name: _name.text.trim(),
      age: int.tryParse(_age.text),
      currentSurah: _surah,
      currentAyahStart: int.tryParse(_ayahStart.text) ?? 1,
      currentAyahEnd: int.tryParse(_ayahEnd.text) ?? 1,
      progressPercent: 0,
      createdAt: DateTime.now(),
    );
    await ref.read(firestoreRepositoryProvider).addStudent(s);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طالب جديد')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'الاسم الكامل'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'العمر (اختياري)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _surah,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'السورة الحالية'),
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
                decoration: const InputDecoration(labelText: 'من الآية'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _ayahEnd,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'إلى الآية'),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}
