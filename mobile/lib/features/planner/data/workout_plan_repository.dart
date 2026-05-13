// mobile/lib/features/planner/data/workout_plan_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/database/app_database.dart';

abstract class WorkoutPlanRepository {
  Stream<List<WorkoutPlan>> watchAll();
  Future<WorkoutPlan?> findById(String id);
  Future<void> upsert(WorkoutPlan plan);
  Future<void> delete(String id);
  Future<List<WorkoutPlan>> findUnsynced();
}

class DriftWorkoutPlanRepository implements WorkoutPlanRepository {
  DriftWorkoutPlanRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WorkoutPlan>> watchAll() =>
      (_db.select(_db.workoutPlans)
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  @override
  Future<WorkoutPlan?> findById(String id) =>
      (_db.select(_db.workoutPlans)..where((p) => p.id.equals(id)))
          .getSingleOrNull();

  @override
  Future<void> upsert(WorkoutPlan plan) =>
      _db.into(_db.workoutPlans).insertOnConflictUpdate(plan);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.workoutPlans)..where((p) => p.id.equals(id))).go();

  @override
  Future<List<WorkoutPlan>> findUnsynced() =>
      (_db.select(_db.workoutPlans)..where((p) => p.synced.equals(false))).get();
}

final workoutPlanRepositoryProvider = Provider<WorkoutPlanRepository>(
  (ref) => DriftWorkoutPlanRepository(ref.read(appDatabaseProvider)),
);
