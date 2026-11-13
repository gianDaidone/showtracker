import 'package:drift/drift.dart';

/// Executor dispatches, not SQLite logical row operations. Reset after opening
/// the schema/seeding fixtures so migrations and unrelated listeners stay out.
class QueryCounter extends QueryInterceptor {
  int selects = 0;
  int inserts = 0;
  int batchDispatches = 0;
  int batchStatements = 0;
  final List<int> selectParameterCounts = [];
  final List<String> selectSql = [];

  void reset() {
    selects = 0;
    inserts = 0;
    batchDispatches = 0;
    batchStatements = 0;
    selectParameterCounts.clear();
    selectSql.clear();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
    selectParameterCounts.add(args.length);
    selectSql.add(statement);
    return executor.runSelect(statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    inserts++;
    return executor.runInsert(statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    batchDispatches++;
    batchStatements += statements.arguments.length;
    return executor.runBatched(statements);
  }
}
