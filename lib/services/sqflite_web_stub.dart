// Stub for sqflite on web platform
class Batch {
  void insert(String table, Map<String, dynamic> values, {dynamic conflictAlgorithm}) {}
  Future<void> commit({bool noResult = false}) async {}
}

enum ConflictAlgorithm {
  replace,
  rollback,
  abort,
  fail,
  ignore,
}

class Database {
  Future<void> execute(String sql) async {}
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async => [];
  Future<int> insert(String table, Map<String, dynamic> values, {String? conflictAlgorithm = 'replace'}) async => 0;
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async => 0;
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async => 0;
  Batch batch() => Batch();
  void dispose() {}
}

Future<Database> openDatabase(String path, {int version = 1, Function? onCreate}) async {
  return Database();
}

Future<String> getDatabasesPath() async => '';

