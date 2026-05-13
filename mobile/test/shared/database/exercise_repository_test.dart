import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/database/app_database.dart';
import 'package:knurl/features/exercise_library/data/exercise_repository.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExerciseRepository(db);
  });

  tearDown(() => db.close());

  test('findAll возвращает пустой список если нет данных', () async {
    final result = await repository.findAll();
    expect(result, isEmpty);
  });

  test('upsertAll сохраняет упражнения и findAll их возвращает', () async {
    await repository.upsertAll([
      ExercisesCompanion.insert(
        id: 'ex-1',
        externalId: 'ext-1',
        name: 'Bench Press',
        cachedAt: DateTime(2026, 1, 1),
      ),
    ]);
    final result = await repository.findAll();
    expect(result.length, 1);
    expect(result.first.name, 'Bench Press');
  });

  test('findById возвращает упражнение по id', () async {
    await repository.upsertAll([
      ExercisesCompanion.insert(
        id: 'ex-1',
        externalId: 'ext-1',
        name: 'Squat',
        cachedAt: DateTime(2026, 1, 1),
      ),
    ]);
    final result = await repository.findById('ex-1');
    expect(result?.name, 'Squat');
  });

  test('findById возвращает null для несуществующего id', () async {
    final result = await repository.findById('nonexistent');
    expect(result, isNull);
  });

  test('deleteAll удаляет все упражнения', () async {
    await repository.upsertAll([
      ExercisesCompanion.insert(
        id: 'ex-1',
        externalId: 'ext-1',
        name: 'Deadlift',
        cachedAt: DateTime(2026, 1, 1),
      ),
    ]);
    await repository.deleteAll();
    final result = await repository.findAll();
    expect(result, isEmpty);
  });

  test('upsertAll обновляет существующую запись', () async {
    await repository.upsertAll([
      ExercisesCompanion.insert(
        id: 'ex-1',
        externalId: 'ext-1',
        name: 'Old Name',
        cachedAt: DateTime(2026, 1, 1),
      ),
    ]);
    await repository.upsertAll([
      ExercisesCompanion.insert(
        id: 'ex-1',
        externalId: 'ext-1',
        name: 'New Name',
        cachedAt: DateTime(2026, 1, 2),
      ),
    ]);
    final result = await repository.findAll();
    expect(result.length, 1);
    expect(result.first.name, 'New Name');
  });
}
