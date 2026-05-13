// mobile/test/shared/database/set_log_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/database/app_database.dart';
import 'package:knurl/features/workout/data/set_log_repository.dart';

void main() {
  late AppDatabase db;
  late SetLogRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSetLogRepository(db);
  });

  tearDown(() => db.close());

  test('findBySessionId возвращает пустой список если нет данных', () async {
    final logs = await repository.findBySessionId('session-1');
    expect(logs, isEmpty);
  });

  test('upsert сохраняет лог и findBySessionId его возвращает', () async {
    final log = SetLog(
      id: 'log-1',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 1,
      weight: 80.0,
      reps: 8,
      loggedAt: DateTime(2026, 1, 1, 10, 5),
      updatedAt: DateTime(2026, 1, 1, 10, 5),
      synced: false,
    );
    await repository.upsert(log);
    final logs = await repository.findBySessionId('session-1');
    expect(logs.length, 1);
    expect(logs.first.weight, 80.0);
  });

  test('findBySessionId возвращает логи отсортированные по setNumber', () async {
    await repository.upsert(SetLog(
      id: 'log-2',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 2,
      weight: 82.5,
      reps: 6,
      loggedAt: DateTime(2026, 1, 1, 10, 10),
      updatedAt: DateTime(2026, 1, 1, 10, 10),
      synced: false,
    ));
    await repository.upsert(SetLog(
      id: 'log-1',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 1,
      weight: 80.0,
      reps: 8,
      loggedAt: DateTime(2026, 1, 1, 10, 5),
      updatedAt: DateTime(2026, 1, 1, 10, 5),
      synced: false,
    ));
    final logs = await repository.findBySessionId('session-1');
    expect(logs[0].setNumber, 1);
    expect(logs[1].setNumber, 2);
  });

  test('delete удаляет лог', () async {
    await repository.upsert(SetLog(
      id: 'log-1',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 1,
      weight: null,
      reps: 10,
      loggedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.delete('log-1');
    final logs = await repository.findBySessionId('session-1');
    expect(logs, isEmpty);
  });

  test('findUnsynced возвращает только логи с synced=false', () async {
    await repository.upsert(SetLog(
      id: 'log-1',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 1,
      weight: 70.0,
      reps: 10,
      loggedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      synced: false,
    ));
    await repository.upsert(SetLog(
      id: 'log-2',
      sessionId: 'session-1',
      exerciseId: 'ex-1',
      setNumber: 2,
      weight: 70.0,
      reps: 9,
      loggedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      synced: true,
    ));
    final unsynced = await repository.findUnsynced();
    expect(unsynced.length, 1);
    expect(unsynced.first.id, 'log-1');
  });
}
