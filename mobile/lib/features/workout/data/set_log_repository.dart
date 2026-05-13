// mobile/lib/features/workout/data/set_log_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class SetLogRepository {
  Future<List<SetLog>> findBySessionId(String sessionId);
  Future<void> upsert(SetLog log);
  Future<void> delete(String id);
  Future<List<SetLog>> findUnsynced();
}

class DriftSetLogRepository implements SetLogRepository {
  DriftSetLogRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<SetLog>> findBySessionId(String sessionId) =>
      (_db.select(_db.setLogs)
            ..where((l) => l.sessionId.equals(sessionId))
            ..orderBy([(l) => OrderingTerm.asc(l.setNumber)]))
          .get();

  @override
  Future<void> upsert(SetLog log) =>
      _db.into(_db.setLogs).insertOnConflictUpdate(log);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.setLogs)..where((l) => l.id.equals(id))).go();

  @override
  Future<List<SetLog>> findUnsynced() =>
      (_db.select(_db.setLogs)..where((l) => l.synced.equals(false))).get();
}

final setLogRepositoryProvider = Provider<SetLogRepository>(
  (ref) => DriftSetLogRepository(ref.read(appDatabaseProvider)),
);
