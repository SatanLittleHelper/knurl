// mobile/lib/shared/database/tables/workout_days_table.dart
import 'package:drift/drift.dart';

class WorkoutDays extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  IntColumn get dayIndex => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
