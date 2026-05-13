// mobile/lib/shared/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/exercises_table.dart';
import 'tables/workout_plans_table.dart';
import 'tables/workout_days_table.dart';
import 'tables/workout_day_exercises_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/set_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Exercises,
  WorkoutPlans,
  WorkoutDays,
  WorkoutDayExercises,
  WorkoutSessions,
  SetLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // if (from < 2) { await m.addColumn(workoutPlans, workoutPlans.notes); }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'knurl.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
