import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> findAll();
  Future<Exercise?> findById(String id);
  Future<void> upsertAll(List<ExercisesCompanion> exercises);
  Future<void> deleteAll();
}

class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<Exercise>> findAll() => _db.select(_db.exercises).get();

  @override
  Future<Exercise?> findById(String id) =>
      (_db.select(_db.exercises)..where((e) => e.id.equals(id)))
          .getSingleOrNull();

  @override
  Future<void> upsertAll(List<ExercisesCompanion> exercises) =>
      _db.batch((batch) => batch.insertAllOnConflictUpdate(_db.exercises, exercises));

  @override
  Future<void> deleteAll() => _db.delete(_db.exercises).go();
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => DriftExerciseRepository(ref.read(appDatabaseProvider)),
);
