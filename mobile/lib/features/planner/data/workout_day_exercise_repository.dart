// mobile/lib/features/planner/data/workout_day_exercise_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class WorkoutDayExerciseRepository {
  Future<List<WorkoutDayExercise>> findByDayId(String dayId);
  Future<void> upsert(WorkoutDayExercise exercise);
  Future<void> deleteByDayId(String dayId);
  Future<List<WorkoutDayExercise>> findUnsynced();
}

class DriftWorkoutDayExerciseRepository implements WorkoutDayExerciseRepository {
  DriftWorkoutDayExerciseRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<WorkoutDayExercise>> findByDayId(String dayId) =>
      (_db.select(_db.workoutDayExercises)
            ..where((e) => e.dayId.equals(dayId))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();

  @override
  Future<void> upsert(WorkoutDayExercise exercise) =>
      _db.into(_db.workoutDayExercises).insertOnConflictUpdate(exercise);

  @override
  Future<void> deleteByDayId(String dayId) =>
      (_db.delete(_db.workoutDayExercises)..where((e) => e.dayId.equals(dayId)))
          .go();

  @override
  Future<List<WorkoutDayExercise>> findUnsynced() =>
      (_db.select(_db.workoutDayExercises)
            ..where((e) => e.synced.equals(false)))
          .get();
}

final workoutDayExerciseRepositoryProvider =
    Provider<WorkoutDayExerciseRepository>(
  (ref) => DriftWorkoutDayExerciseRepository(ref.read(appDatabaseProvider)),
);
