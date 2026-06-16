import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/student.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/note.dart';

/// Local persistent store replacing Firestore. Pure offline.
class LocalRepository {
  LocalRepository._();
  static final LocalRepository instance = LocalRepository._();

  static const _kStudents = 'data_students_v1';
  static const _kSessions = 'data_sessions_v1';
  static const _kAttendance = 'data_attendance_v1';
  static const _kNotes = 'data_notes_v1';
  static const _kShared = 'data_shared_v1';

  late SharedPreferences _prefs;
  final _uuid = const Uuid();

  final _studentsCtrl = StreamController<List<Student>>.broadcast();
  final _sessionsCtrl = StreamController<void>.broadcast();
  final _attendanceCtrl = StreamController<void>.broadcast();
  final _notesCtrl = StreamController<void>.broadcast();

  List<Student> _students = [];
  List<SessionEntity> _sessions = [];
  List<AttendanceRecord> _attendance = [];
  List<Note> _notes = [];
  Map<String, String> _shared = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _students = _decode(_kStudents, _studentFromJson);
    _sessions = _decode(_kSessions, _sessionFromJson);
    _attendance = _decode(_kAttendance, _attendanceFromJson);
    _notes = _decode(_kNotes, _noteFromJson);
    final s = _prefs.getString(_kShared);
    _shared = s == null ? {} : Map<String, String>.from(jsonDecode(s));
  }

  List<T> _decode<T>(String k, T Function(Map<String, dynamic>) fn) {
    final raw = _prefs.getString(k);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => fn(e as Map<String, dynamic>)).toList();
  }

  Future<void> _persist<T>(String k, List<T> list, Map<String, dynamic> Function(T) toJson) =>
      _prefs.setString(k, jsonEncode(list.map(toJson).toList()));

  // ---------- STUDENTS ----------
  Stream<List<Student>> watchStudents() async* {
    yield _sortedStudents();
    yield* _studentsCtrl.stream;
  }

  List<Student> _sortedStudents() {
    final l = [..._students];
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  Future<Student?> getStudent(String id) async {
    for (final s in _students) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<String> addStudent(Student s) async {
    final withId = Student(
      id: _uuid.v4(),
      name: s.name,
      age: s.age,
      currentSurah: s.currentSurah,
      currentAyahStart: s.currentAyahStart,
      currentAyahEnd: s.currentAyahEnd,
      progressPercent: s.progressPercent,
      createdAt: s.createdAt,
    );
    _students.add(withId);
    await _persist(_kStudents, _students, _studentToJson);
    _studentsCtrl.add(_sortedStudents());
    return withId.id;
  }

  Future<void> updateStudent(Student s) async {
    final idx = _students.indexWhere((e) => e.id == s.id);
    if (idx == -1) return;
    _students[idx] = s;
    await _persist(_kStudents, _students, _studentToJson);
    _studentsCtrl.add(_sortedStudents());
  }

  Future<void> deleteStudent(String id) async {
    _students.removeWhere((e) => e.id == id);
    _sessions.removeWhere((e) => e.studentId == id);
    _attendance.removeWhere((e) => e.studentId == id);
    _notes.removeWhere((e) => e.studentId == id);
    await _persist(_kStudents, _students, _studentToJson);
    await _persist(_kSessions, _sessions, _sessionToJson);
    await _persist(_kAttendance, _attendance, _attendanceToJson);
    await _persist(_kNotes, _notes, _noteToJson);
    _studentsCtrl.add(_sortedStudents());
    _sessionsCtrl.add(null);
    _attendanceCtrl.add(null);
    _notesCtrl.add(null);
  }

  // ---------- SESSIONS ----------
  Stream<List<SessionEntity>> watchSessions(String studentId) async* {
    yield _sessionsFor(studentId);
    await for (final _ in _sessionsCtrl.stream) {
      yield _sessionsFor(studentId);
    }
  }

  List<SessionEntity> _sessionsFor(String studentId) {
    final l = _sessions.where((e) => e.studentId == studentId).toList();
    l.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return l;
  }

  Stream<List<SessionEntity>> watchAllSessionsToday() async* {
    yield _sessionsToday();
    await for (final _ in _sessionsCtrl.stream) {
      yield _sessionsToday();
    }
  }

  List<SessionEntity> _sessionsToday() {
    final start = DateTime.now().subtract(const Duration(hours: 24));
    return _sessions.where((e) => e.timestamp.isAfter(start)).toList();
  }

  Future<void> addSession(SessionEntity s) async {
    _sessions.add(SessionEntity(
      id: _uuid.v4(),
      studentId: s.studentId,
      type: s.type,
      surah: s.surah,
      ayahStart: s.ayahStart,
      ayahEnd: s.ayahEnd,
      rating: s.rating,
      mistakes: s.mistakes,
      notes: s.notes,
      timestamp: s.timestamp,
    ));
    await _persist(_kSessions, _sessions, _sessionToJson);
    _sessionsCtrl.add(null);
  }

  // ---------- ATTENDANCE ----------
  Stream<List<AttendanceRecord>> watchAttendance(String studentId) async* {
    yield _attendanceFor(studentId);
    await for (final _ in _attendanceCtrl.stream) {
      yield _attendanceFor(studentId);
    }
  }

  List<AttendanceRecord> _attendanceFor(String studentId) {
    final l = _attendance.where((e) => e.studentId == studentId).toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  Stream<List<AttendanceRecord>> watchAttendanceForDate(DateTime date) async* {
    yield _attendanceForDate(date);
    await for (final _ in _attendanceCtrl.stream) {
      yield _attendanceForDate(date);
    }
  }

  List<AttendanceRecord> _attendanceForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _attendance
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList();
  }

  Future<void> setAttendance(AttendanceRecord a) async {
    final start = DateTime(a.date.year, a.date.month, a.date.day);
    final end = start.add(const Duration(days: 1));
    final idx = _attendance.indexWhere((e) =>
        e.studentId == a.studentId &&
        !e.date.isBefore(start) &&
        e.date.isBefore(end));
    if (idx >= 0) {
      _attendance[idx] = AttendanceRecord(
        id: _attendance[idx].id,
        studentId: a.studentId,
        date: _attendance[idx].date,
        status: a.status,
      );
    } else {
      _attendance.add(AttendanceRecord(
        id: _uuid.v4(),
        studentId: a.studentId,
        date: a.date,
        status: a.status,
      ));
    }
    await _persist(_kAttendance, _attendance, _attendanceToJson);
    _attendanceCtrl.add(null);
  }

  // ---------- NOTES ----------
  Stream<List<Note>> watchNotes(String studentId) async* {
    yield _notesFor(studentId);
    await for (final _ in _notesCtrl.stream) {
      yield _notesFor(studentId);
    }
  }

  List<Note> _notesFor(String studentId) {
    final l = _notes.where((e) => e.studentId == studentId).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  Future<void> addNote(Note n) async {
    _notes.add(Note(
      id: _uuid.v4(),
      studentId: n.studentId,
      content: n.content,
      createdAt: n.createdAt,
    ));
    await _persist(_kNotes, _notes, _noteToJson);
    _notesCtrl.add(null);
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((e) => e.id == id);
    await _persist(_kNotes, _notes, _noteToJson);
    _notesCtrl.add(null);
  }

  // ---------- SHARED TOKEN ----------
  Future<String> createShareToken(String studentId) async {
    final token = _uuid.v4().replaceAll('-', '');
    _shared[token] = studentId;
    await _prefs.setString(_kShared, jsonEncode(_shared));
    return token;
  }

  Future<String?> resolveToken(String token) async => _shared[token];

  // ---------- JSON ----------
  Map<String, dynamic> _studentToJson(Student s) => {
        'id': s.id,
        'name': s.name,
        'age': s.age,
        'currentSurah': s.currentSurah,
        'currentAyahStart': s.currentAyahStart,
        'currentAyahEnd': s.currentAyahEnd,
        'progressPercent': s.progressPercent,
        'createdAt': s.createdAt.toIso8601String(),
      };
  Student _studentFromJson(Map<String, dynamic> d) => Student(
        id: d['id'] as String,
        name: d['name'] as String,
        age: d['age'] as int?,
        currentSurah: d['currentSurah'] as String,
        currentAyahStart: d['currentAyahStart'] as int,
        currentAyahEnd: d['currentAyahEnd'] as int,
        progressPercent: (d['progressPercent'] as num).toDouble(),
        createdAt: DateTime.parse(d['createdAt'] as String),
      );

  Map<String, dynamic> _sessionToJson(SessionEntity s) => {
        'id': s.id,
        'studentId': s.studentId,
        'type': s.type.name,
        'surah': s.surah,
        'ayahStart': s.ayahStart,
        'ayahEnd': s.ayahEnd,
        'rating': s.rating.name,
        'mistakes': s.mistakes,
        'notes': s.notes,
        'timestamp': s.timestamp.toIso8601String(),
      };
  SessionEntity _sessionFromJson(Map<String, dynamic> d) => SessionEntity(
        id: d['id'] as String,
        studentId: d['studentId'] as String,
        type: SessionType.values.firstWhere((e) => e.name == d['type'],
            orElse: () => SessionType.memorization),
        surah: d['surah'] as String,
        ayahStart: d['ayahStart'] as int,
        ayahEnd: d['ayahEnd'] as int,
        rating: SessionRating.values.firstWhere((e) => e.name == d['rating'],
            orElse: () => SessionRating.good),
        mistakes: List<String>.from(d['mistakes'] ?? const []),
        notes: (d['notes'] ?? '') as String,
        timestamp: DateTime.parse(d['timestamp'] as String),
      );

  Map<String, dynamic> _attendanceToJson(AttendanceRecord a) => {
        'id': a.id,
        'studentId': a.studentId,
        'date': a.date.toIso8601String(),
        'status': a.status.name,
      };
  AttendanceRecord _attendanceFromJson(Map<String, dynamic> d) =>
      AttendanceRecord(
        id: d['id'] as String,
        studentId: d['studentId'] as String,
        date: DateTime.parse(d['date'] as String),
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == d['status'],
          orElse: () => AttendanceStatus.present,
        ),
      );

  Map<String, dynamic> _noteToJson(Note n) => {
        'id': n.id,
        'studentId': n.studentId,
        'content': n.content,
        'createdAt': n.createdAt.toIso8601String(),
      };
  Note _noteFromJson(Map<String, dynamic> d) => Note(
        id: d['id'] as String,
        studentId: d['studentId'] as String,
        content: d['content'] as String,
        createdAt: DateTime.parse(d['createdAt'] as String),
      );
}
