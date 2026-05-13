// mobile/lib/shared/database/tables/exercises_table.dart
import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get externalId => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
