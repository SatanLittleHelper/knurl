// mobile/lib/features/workout/data/workout_session_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class WorkoutSessionRepository {
  Stream<List<WorkoutSession>> watchAll();
  Future<WorkoutSession?> findById(String id);
  Future<void> upsert(WorkoutSession session);
  Future<void> delete(String id);
  Future<List<WorkoutSession>> findUnsynced();
}

class DriftWorkoutSessionRepository implements WorkoutSessionRepository {
  DriftWorkoutSessionRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WorkoutSession>> watchAll() =>
      (_db.select(_db.workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .watch();

  @override
  Future<WorkoutSession?> findById(String id) =>
      (_db.select(_db.workoutSessions)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  @override
  Future<void> upsert(WorkoutSession session) =>
      _db.into(_db.workoutSessions).insertOnConflictUpdate(session);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.workoutSessions)..where((s) => s.id.equals(id))).go();

  @override
  Future<List<WorkoutSession>> findUnsynced() =>
      (_db.select(_db.workoutSessions)..where((s) => s.synced.equals(false)))
          .get();
}

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>(
  (ref) => DriftWorkoutSessionRepository(ref.read(appDatabaseProvider)),
);
