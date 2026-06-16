import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUser {
  final String email;
  const LocalUser(this.email);
}

/// Pure-local auth backed by SharedPreferences. No network/Firebase required.
/// A demo account (teacher@demo.com / demo1234) is pre-seeded on first launch.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  static const _kUsers = 'auth_users_v1';
  static const _kCurrent = 'auth_current_v1';
  static const String demoEmail = 'teacher@demo.com';
  static const String demoPassword = 'demo1234';

  final _ctrl = StreamController<LocalUser?>.broadcast();
  LocalUser? _current;
  late SharedPreferences _prefs;

  Stream<LocalUser?> authStateChanges() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  LocalUser? get currentUser => _current;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final users = _readUsers();
    // Seed demo account if missing.
    if (!users.containsKey(demoEmail)) {
      users[demoEmail] = _hash(demoPassword);
      await _writeUsers(users);
    }
    final saved = _prefs.getString(_kCurrent);
    if (saved != null && saved.isNotEmpty) {
      _current = LocalUser(saved);
    }
  }

  Map<String, String> _readUsers() {
    final raw = _prefs.getString(_kUsers);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _writeUsers(Map<String, String> users) =>
      _prefs.setString(_kUsers, jsonEncode(users));

  String _hash(String p) => sha256.convert(utf8.encode(p)).toString();

  Future<void> signIn(String email, String password) async {
    final users = _readUsers();
    final h = users[email.trim().toLowerCase()];
    if (h == null || h != _hash(password)) {
      throw Exception('بيانات الدخول غير صحيحة');
    }
    _current = LocalUser(email.trim().toLowerCase());
    await _prefs.setString(_kCurrent, _current!.email);
    _ctrl.add(_current);
  }

  Future<void> signUp(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) {
      throw Exception('البريد الإلكتروني غير صالح');
    }
    if (password.length < 6) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
    final users = _readUsers();
    if (users.containsKey(e)) {
      throw Exception('هذا الحساب موجود مسبقًا');
    }
    users[e] = _hash(password);
    await _writeUsers(users);
    _current = LocalUser(e);
    await _prefs.setString(_kCurrent, e);
    _ctrl.add(_current);
  }

  Future<void> signOut() async {
    _current = null;
    await _prefs.remove(_kCurrent);
    _ctrl.add(null);
  }
}
