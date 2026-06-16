import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/local_repository.dart';

final authRepositoryProvider = Provider((_) => AuthRepository.instance);
final firestoreRepositoryProvider =
    Provider((_) => LocalRepository.instance);

final authStateProvider = StreamProvider<LocalUser?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());
