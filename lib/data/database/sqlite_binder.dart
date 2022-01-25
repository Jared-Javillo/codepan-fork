import 'dart:async';

import 'package:codepan/data/database/models/condition.dart';
import 'package:codepan/data/database/models/field.dart';
import 'package:codepan/data/database/models/table.dart' as tb;
import 'package:codepan/data/database/schema.dart';
import 'package:codepan/data/database/sqlite_adapter.dart';
import 'package:codepan/data/database/sqlite_exception.dart';
import 'package:codepan/data/database/sqlite_query.dart';
import 'package:codepan/data/database/sqlite_statement.dart';
import 'package:codepan/data/models/entities/transaction.dart';
import 'package:codepan/extensions/duration.dart';
import 'package:codepan/utils/codepan_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

enum UpdatePriority {
  unique,
  uniqueGroup,
}

const tag = 'DATABASE BINDER';
const primaryKey = SQLiteStatement.id;

typedef BinderBody = Future<dynamic> Function(
  SQLiteBinder binder,
);

class SQLiteBinder {
  late Map<String, int> _map;
  late DateTime _time;
  late Batch _batch;
  final SQLiteAdapter db;
  bool _showLog = false;
  bool _chain = false;

  SQLiteBinder(this.db) : _map = {};

  factory SQLiteBinder.chain(SQLiteAdapter db) {
    if (db.inTransaction) {
      return db.binder!..chain();
    }
    return SQLiteBinder(db);
  }

  /// [body] - Enclosed in try catch to automatically remove the binder or
  /// any pending transaction when an error occurred to avoid database lock.
  Future<T> transact<T>({
    required BinderBody body,
    bool showLog = false,
    bool autoFinish = true,
  }) async {
    if (!db.inTransaction) {
      this._batch = db.batch();
      this._showLog = showLog;
      if (_showLog) {
        _time = DateTime.now();
        debugPrint('$tag: BEGIN TRANSACTION');
      }
      db.setBinder(this);
    }
    try {
      if (autoFinish) {
        await body.call(this);
        return await finish() as T;
      } else {
        return await body.call(this) as T;
      }
    } catch (error) {
      db.removeBinder();
      rethrow;
    }
  }

  Future<bool> apply() async {
    if (db.inTransaction) {
      try {
        await _batch.commit(noResult: true);
        return true;
      } catch (error, stacktrace) {
        printError(error, stacktrace);
        rethrow;
      }
    }
    return false;
  }

  Future<bool> finish({
    bool clearMap = true,
  }) async {
    if (db.inTransaction) {
      if (!_chain) {
        bool result = false;
        if (clearMap) {
          _map.clear();
        }
        try {
          await _batch.commit(noResult: true);
          if (_showLog) {
            final duration = DateTime.now().difference(_time);
            final formatted = duration.format(isReadable: true);
            debugPrint('$tag: TRANSACTION SUCCESSFUL');
            debugPrint('$tag: FINISHED AT $formatted');
          }
          result = true;
        } catch (error, stacktrace) {
          printError(error, stacktrace);
          rethrow;
        } finally {
          db.removeBinder();
        }
        return result;
      } else {
        chain(false);
        return true;
      }
    }
    return false;
  }

  void chain([bool chain = true]) {
    _chain = chain;
  }

  Future<int> _mapId(
    SQLiteStatement stmt,
    String table,
    dynamic unique,
  ) async {
    if (unique != null) {
      final key = _getKeyFromUnique(stmt, table, unique);
      if (key != null) {
        final existingId = _map[key] ??
            await _queryIdFromUnique(
              stmt,
              table,
              unique,
            );
        if (existingId != null) {
          return _map[key] = existingId;
        }
      }
    }
    return _getNextId(table);
  }

  String? _getKeyFromUnique(
    SQLiteStatement stmt,
    String table,
    dynamic unique,
  ) {
    final map = stmt.map!;
    if (unique is String) {
      final value = map[unique];
      return '$table.$unique($value)';
    } else if (unique is List<String>) {
      final buffer = StringBuffer('$table');
      if (unique.isNotEmpty) {
        for (final field in unique) {
          final value = map[field];
          if (value != null) {
            buffer.write('.$field($value)');
          } else {
            return null;
          }
        }
        return buffer.toString();
      }
    }
    return null;
  }

  Future<int?> _queryIdFromUnique(
    SQLiteStatement stmt,
    String table,
    dynamic unique,
  ) async {
    final map = stmt.map!;
    final query = SQLiteQuery(
      select: [
        primaryKey,
      ],
      from: table,
    );
    if (unique is String) {
      final value = map[unique];
      if (value != null) {
        query.addCondition(
          Condition.equals(unique, value),
        );
      }
    } else if (unique is List<String>) {
      for (final field in unique) {
        final value = map[field];
        if (value != null) {
          query.addCondition(
            Condition.equals(field, value),
          );
        } else {
          return null;
        }
      }
    }
    return query.hasConditions ? await db.getValue(query.build()) : null;
  }

  Future<int> _getNextId(String table) async {
    final currentId = _map[table] ?? await _queryLastId(table);
    return _map[table] = currentId + 1;
  }

  Future<int> _queryLastId(String table) async {
    final query = SQLiteQuery(
      select: [
        primaryKey,
      ],
      from: table,
      orderBy: [
        Field.order(
          field: primaryKey,
          order: Order.descending,
        )
      ],
      limit: 1,
    );
    return await db.getValue(query.build()) ?? 0;
  }

  void addStatement(final String sql) {
    if (_showLog) {
      print(sql);
    }
    _batch.execute(sql);
  }

  Future<T> insertForId<T extends TransactionData>({
    required TransactionData data,
    UpdatePriority priority = UpdatePriority.unique,
  }) async {
    return data.copyWith(
      id: await insertData(
        data: data,
        priority: priority,
      ),
    ) as T;
  }

  Future<int?> insertData({
    required TransactionData? data,
    UpdatePriority priority = UpdatePriority.unique,
    bool ignoreId = false,
  }) {
    if (data != null) {
      dynamic unique;
      switch (priority) {
        case UpdatePriority.unique:
          unique = data.unique ?? data.uniqueGroup;
          break;
        case UpdatePriority.uniqueGroup:
          unique = data.uniqueGroup ?? data.unique;
          break;
      }
      return insert(
        data.table,
        data.toStatement(),
        unique: unique,
        ignoreId: ignoreId,
      );
    }
    return Future.value(null);
  }

  /// table - Can only be a type of String, Table or TableSchema.
  Future<int?> insert(
    dynamic table,
    SQLiteStatement stmt, {
    dynamic unique,
    bool ignoreId = false,
  }) async {
    final map = stmt.map!;
    final name = _getTableName(table);
    final _unique = map[primaryKey] != null ? primaryKey : unique;
    addStatement(stmt.insert(name, unique: _unique));
    return ignoreId ? null : await _mapId(stmt, name, unique);
  }

  void updateData({
    required TransactionData data,
  }) {
    updateRecord(data.table, data.toStatement(), data.id);
  }

  /// table - Can only be a type of String, Table or TableSchema.
  void updateRecord(
    dynamic table,
    SQLiteStatement stmt,
    dynamic id,
  ) {
    final name = _getTableName(table);
    final sql = stmt.update(name, id);
    addStatement(sql);
  }

  @deprecated
  void updateWithConditions(
    String table,
    SQLiteStatement stmt,
  ) {
    final sql = stmt.updateWithConditions(table);
    addStatement(sql);
  }

  /// table - Can only be a type of String, Table or TableSchema.
  void update({
    required dynamic table,
    required SQLiteStatement stmt,
  }) {
    final name = _getTableName(table);
    final sql = stmt.updateFromStatement(name);
    addStatement(sql);
  }

  /// table - Can only be a List of String, Table or TableSchema.
  void resetBool({
    required List<dynamic> tables,
    required String column,
    bool value = false,
  }) {
    final stmt = SQLiteStatement.from(
      fieldsAndValues: {
        column: value,
      },
      conditions: {
        column: !value,
      },
    );
    for (final table in tables) {
      update(table: table, stmt: stmt);
    }
  }

  String _getTableName(dynamic table) {
    if (table is String) {
      return table;
    } else if (table is tb.Table) {
      return table.name;
    } else if (table is TableSchema) {
      return table.tableName;
    } else {
      throw SQLiteException(SQLiteException.invalidTableType);
    }
  }

  void truncate(String table) {
    final stmt = SQLiteStatement();
    addStatement(stmt.delete(table));
    addStatement(stmt.resetTable(table));
  }

  void delete(String table, dynamic id) {
    final sql = SQLiteStatement().delete(table, id);
    addStatement(sql);
  }

  void deleteWithConditions(String table, SQLiteStatement stmt) {
    final sql = stmt.deleteWithConditions(table);
    addStatement(sql);
  }

  void createTable(String table, SQLiteStatement stmt) {
    final sql = stmt.createTable(table);
    addStatement(sql);
  }

  void createIndex(String idx, String table, SQLiteStatement stmt) {
    final sql = stmt.createIndex(idx, table);
    addStatement(sql);
  }

  void createTimeTrigger(String trg, String table, SQLiteStatement stmt) {
    final sql = stmt.createTimeTrigger(trg, table);
    addStatement(sql);
  }

  void dropTable(String table) {
    final stmt = SQLiteStatement();
    final sql = stmt.dropTable(table);
    addStatement(sql);
  }

  void dropIndex(String idx) {
    final stmt = SQLiteStatement();
    final sql = stmt.dropIndex(idx);
    addStatement(sql);
  }

  void renameTable(String oldName, String newName) {
    final stmt = SQLiteStatement();
    final sql = stmt.renameTable(oldName, newName);
    addStatement(sql);
  }

  void addColumn(String table, Field field) {
    final stmt = SQLiteStatement();
    final sql = stmt.addColumn(table, field);
    addStatement(sql);
  }
}
