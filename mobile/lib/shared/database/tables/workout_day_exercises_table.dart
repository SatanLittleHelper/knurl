// mobile/lib/shared/database/tables/workout_day_exercises_table.dart
import 'package:drift/drift.dart';

class WorkoutDayExercises extends Table {
  TextColumn get id => text()();
  TextColumn get dayId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get targetSets => integer()();
  IntColumn get targetReps => integer()();
  RealColumn get targetWeight => real().nullable()();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
