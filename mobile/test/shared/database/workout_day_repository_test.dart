// mobile/test/shared/database/workout_day_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/database/app_database.dart';
import 'package:knurl/features/planner/data/workout_day_repository.dart';
import 'package:knurl/features/planner/data/workout_day_exercise_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutDayRepository dayRepo;
  late WorkoutDayExerciseRepository dayExerciseRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dayRepo = DriftWorkoutDayRepository(db);
    dayExerciseRepo = DriftWorkoutDayExerciseRepository(db);
  });

  tearDown(() => db.close());

  group('WorkoutDayRepository', () {
    test('findByPlanId возвращает пустой список если нет данных', () async {
      final days = await dayRepo.findByPlanId('plan-1');
      expect(days, isEmpty);
    });

    test('upsert сохраняет день и findByPlanId его возвращает', () async {
      final day = WorkoutDay(
        id: 'day-1',
        planId: 'plan-1',
        dayIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      );
      await dayRepo.upsert(day);
      final days = await dayRepo.findByPlanId('plan-1');
      expect(days.length, 1);
      expect(days.first.dayIndex, 0);
    });

    test('deleteByPlanId удаляет все дни плана', () async {
      await dayRepo.upsert(WorkoutDay(
        id: 'day-1',
        planId: 'plan-1',
        dayIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      await dayRepo.deleteByPlanId('plan-1');
      final days = await dayRepo.findByPlanId('plan-1');
      expect(days, isEmpty);
    });

    test('findUnsynced возвращает только дни с synced=false', () async {
      await dayRepo.upsert(WorkoutDay(
        id: 'day-1',
        planId: 'plan-1',
        dayIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      await dayRepo.upsert(WorkoutDay(
        id: 'day-2',
        planId: 'plan-1',
        dayIndex: 1,
        updatedAt: DateTime(2026, 1, 1),
        synced: true,
      ));
      final unsynced = await dayRepo.findUnsynced();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'day-1');
    });
  });

  group('WorkoutDayExerciseRepository', () {
    test('upsert сохраняет упражнение дня', () async {
      final ex = WorkoutDayExercise(
        id: 'wde-1',
        dayId: 'day-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 60.0,
        orderIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      );
      await dayExerciseRepo.upsert(ex);
      final list = await dayExerciseRepo.findByDayId('day-1');
      expect(list.length, 1);
      expect(list.first.targetSets, 3);
    });

    test('findByDayId возвращает упражнения отсортированные по orderIndex', () async {
      await dayExerciseRepo.upsert(WorkoutDayExercise(
        id: 'wde-2',
        dayId: 'day-1',
        exerciseId: 'ex-2',
        targetSets: 4,
        targetReps: 8,
        targetWeight: null,
        orderIndex: 1,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      await dayExerciseRepo.upsert(WorkoutDayExercise(
        id: 'wde-1',
        dayId: 'day-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 60.0,
        orderIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      final list = await dayExerciseRepo.findByDayId('day-1');
      expect(list[0].orderIndex, 0);
      expect(list[1].orderIndex, 1);
    });

    test('deleteByDayId удаляет все упражнения дня', () async {
      await dayExerciseRepo.upsert(WorkoutDayExercise(
        id: 'wde-1',
        dayId: 'day-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetWeight: null,
        orderIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      await dayExerciseRepo.deleteByDayId('day-1');
      final list = await dayExerciseRepo.findByDayId('day-1');
      expect(list, isEmpty);
    });

    test('findUnsynced возвращает только упражнения дня с synced=false', () async {
      await dayExerciseRepo.upsert(WorkoutDayExercise(
        id: 'wde-1',
        dayId: 'day-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetWeight: null,
        orderIndex: 0,
        updatedAt: DateTime(2026, 1, 1),
        synced: false,
      ));
      await dayExerciseRepo.upsert(WorkoutDayExercise(
        id: 'wde-2',
        dayId: 'day-1',
        exerciseId: 'ex-2',
        targetSets: 4,
        targetReps: 8,
        targetWeight: null,
        orderIndex: 1,
        updatedAt: DateTime(2026, 1, 1),
        synced: true,
      ));
      final unsynced = await dayExerciseRepo.findUnsynced();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'wde-1');
    });
  });
}
