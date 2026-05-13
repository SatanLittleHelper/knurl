// mobile/lib/features/planner/data/workout_day_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class WorkoutDayRepository {
  Future<List<WorkoutDay>> findByPlanId(String planId);
  Future<void> upsert(WorkoutDay day);
  Future<void> deleteByPlanId(String planId);
  Future<List<WorkoutDay>> findUnsynced();
}

class DriftWorkoutDayRepository implements WorkoutDayRepository {
  DriftWorkoutDayRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<WorkoutDay>> findByPlanId(String planId) =>
      (_db.select(_db.workoutDays)..where((d) => d.planId.equals(planId))).get();

  @override
  Future<void> upsert(WorkoutDay day) =>
      _db.into(_db.workoutDays).insertOnConflictUpdate(day);

  @override
  Future<void> deleteByPlanId(String planId) =>
      (_db.delete(_db.workoutDays)..where((d) => d.planId.equals(planId))).go();

  @override
  Future<List<WorkoutDay>> findUnsynced() =>
      (_db.select(_db.workoutDays)..where((d) => d.synced.equals(false))).get();
}

final workoutDayRepositoryProvider = Provider<WorkoutDayRepository>(
  (ref) => DriftWorkoutDayRepository(ref.read(appDatabaseProvider)),
);
