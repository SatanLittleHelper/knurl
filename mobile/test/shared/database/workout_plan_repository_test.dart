// mobile/test/shared/database/workout_plan_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/database/app_database.dart';
import 'package:knurl/features/planner/data/workout_plan_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutPlanRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftWorkoutPlanRepository(db);
  });

  tearDown(() => db.close());

  test('watchAll эмитит пустой список если нет данных', () async {
    final plans = await repository.watchAll().first;
    expect(plans, isEmpty);
  });

  test('upsert сохраняет план и watchAll его возвращает', () async {
    final plan = WorkoutPlan(
      id: 'plan-1',
      name: 'Push Pull Legs',
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    );
    await repository.upsert(plan);
    final plans = await repository.watchAll().first;
    expect(plans.length, 1);
    expect(plans.first.name, 'Push Pull Legs');
  });

  test('findById возвращает план по id', () async {
    final plan = WorkoutPlan(
      id: 'plan-1',
      name: 'Upper Lower',
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    );
    await repository.upsert(plan);
    final found = await repository.findById('plan-1');
    expect(found?.name, 'Upper Lower');
  });

  test('findById возвращает null для несуществующего id', () async {
    final found = await repository.findById('nonexistent');
    expect(found, isNull);
  });

  test('delete удаляет план', () async {
    final plan = WorkoutPlan(
      id: 'plan-1',
      name: 'Full Body',
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    );
    await repository.upsert(plan);
    await repository.delete('plan-1');
    final found = await repository.findById('plan-1');
    expect(found, isNull);
  });

  test('findUnsynced возвращает только планы с synced=false', () async {
    await repository.upsert(WorkoutPlan(
      id: 'plan-1',
      name: 'Unsynced',
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.upsert(WorkoutPlan(
      id: 'plan-2',
      name: 'Synced',
      updatedAt: DateTime(2026, 1, 1),
      synced: true,
    ));
    final unsynced = await repository.findUnsynced();
    expect(unsynced.length, 1);
    expect(unsynced.first.id, 'plan-1');
  });

  test('upsert обновляет существующий план', () async {
    await repository.upsert(WorkoutPlan(
      id: 'plan-1',
      name: 'Old Name',
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.upsert(WorkoutPlan(
      id: 'plan-1',
      name: 'New Name',
      updatedAt: DateTime(2026, 1, 2),
      synced: false,
    ));
    final found = await repository.findById('plan-1');
    expect(found?.name, 'New Name');
  });
}
