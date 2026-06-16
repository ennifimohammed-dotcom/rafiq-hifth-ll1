import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/student.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/note.dart';
import 'auth_provider.dart';

final studentsStreamProvider = StreamProvider<List<Student>>(
    (ref) => ref.watch(firestoreRepositoryProvider).watchStudents());

final studentProvider =
    FutureProvider.family<Student?, String>((ref, id) async {
  return ref.watch(firestoreRepositoryProvider).getStudent(id);
});

final sessionsProvider = StreamProvider.family<List<SessionEntity>, String>(
    (ref, id) => ref.watch(firestoreRepositoryProvider).watchSessions(id));

final todaysSessionsProvider = StreamProvider<List<SessionEntity>>(
    (ref) => ref.watch(firestoreRepositoryProvider).watchAllSessionsToday());

final attendanceProvider = StreamProvider.family<List<AttendanceRecord>, String>(
    (ref, id) => ref.watch(firestoreRepositoryProvider).watchAttendance(id));

final todaysAttendanceProvider = StreamProvider<List<AttendanceRecord>>(
    (ref) => ref
        .watch(firestoreRepositoryProvider)
        .watchAttendanceForDate(DateTime.now()));

final notesProvider = StreamProvider.family<List<Note>, String>(
    (ref, id) => ref.watch(firestoreRepositoryProvider).watchNotes(id));
