// mobile/test/shared/database/workout_session_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/database/app_database.dart';
import 'package:knurl/features/workout/data/workout_session_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutSessionRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftWorkoutSessionRepository(db);
  });

  tearDown(() => db.close());

  test('watchAll эмитит пустой список если нет данных', () async {
    final sessions = await repository.watchAll().first;
    expect(sessions, isEmpty);
  });

  test('upsert сохраняет сессию и watchAll её возвращает', () async {
    final session = WorkoutSession(
      id: 'session-1',
      planId: null,
      startedAt: DateTime(2026, 1, 1, 10, 0),
      finishedAt: null,
      updatedAt: DateTime(2026, 1, 1, 10, 0),
      synced: false,
    );
    await repository.upsert(session);
    final sessions = await repository.watchAll().first;
    expect(sessions.length, 1);
  });

  test('findById возвращает сессию по id', () async {
    final session = WorkoutSession(
      id: 'session-1',
      planId: 'plan-1',
      startedAt: DateTime(2026, 1, 1, 10, 0),
      finishedAt: null,
      updatedAt: DateTime(2026, 1, 1, 10, 0),
      synced: false,
    );
    await repository.upsert(session);
    final found = await repository.findById('session-1');
    expect(found?.planId, 'plan-1');
  });

  test('findById возвращает null для несуществующего id', () async {
    final found = await repository.findById('nonexistent');
    expect(found, isNull);
  });

  test('delete удаляет сессию', () async {
    await repository.upsert(WorkoutSession(
      id: 'session-1',
      planId: null,
      startedAt: DateTime(2026, 1, 1),
      finishedAt: null,
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.delete('session-1');
    final found = await repository.findById('session-1');
    expect(found, isNull);
  });

  test('findUnsynced возвращает только сессии с synced=false', () async {
    await repository.upsert(WorkoutSession(
      id: 'session-1',
      planId: null,
      startedAt: DateTime(2026, 1, 1),
      finishedAt: null,
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.upsert(WorkoutSession(
      id: 'session-2',
      planId: null,
      startedAt: DateTime(2026, 1, 2),
      finishedAt: DateTime(2026, 1, 2, 11, 0),
      updatedAt: DateTime(2026, 1, 2),
      synced: true,
    ));
    final unsynced = await repository.findUnsynced();
    expect(unsynced.length, 1);
    expect(unsynced.first.id, 'session-1');
  });
}
