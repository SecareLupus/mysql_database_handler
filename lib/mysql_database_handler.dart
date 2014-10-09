import 'dart:async';
import 'dart:mirrors';
import 'package:magnetfruit_database_handler/database_handler.dart';
import 'package:sqljocky/sqljocky.dart';

/// A database handler used by the `avocadorm` to talk to a MySQL database.
class MySqlDatabaseHandler extends DatabaseHandler {

  /// Handler of queries for the database.
  ConnectionPool pool;

  /**
   * Creates the [DatabaseHandler] for the MySQL database.
   */
  MySqlDatabaseHandler(String host, int port, String database, String user, String password) {
    this.pool = new ConnectionPool(host: host, port: port, db: database, user: user, password: password);
  }

  /**
   * Creates a new table row in the database.
   *
   * Creates a new table row with the specified [data]. The [columns] list has the normal columns only, and
   * excludes the primary key column. Returns a [Future] containing the primary key value of the new table row. The
   * primary key is expected to be null or non-existant in the table.
   */
  Future<Object> create(String table, String pkColumn, List<String> columns, Map data) {
    columns = new List.from(columns);
    columns.insert(0, pkColumn);

    var cols = columns.map((c) => '`${c}`'),
        values = columns.map((c) => _objToString(data[c]));

    var script = 'INSERT INTO `${table}` (${cols.join(', ')})';
    script += '\nVALUES (${values.join(', ')});';

    return this.pool.query(script).then((result) {
      return new Future.value(result.insertId);
    });
  }

  /**
   * Counts how many table rows are in the database.
   *
   * If [filters] list is null or empty, counts the total amount of table rows in the specified table. Otherwise,
   * counts how many table rows match the specified list of filter. Returns a [Future] containing the count.
   */
  Future<int> count(String table, [List<Filter> filters]) {
    var script = 'SELECT COUNT(*) FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

    script += ';';

    return this.pool.query(script).then((results) {
      return results.first.then((row) {
        return row.first;
      });
    });
  }

  /**
   * Reads table rows in the database.
   *
   * Reads the specified [columns] from the specified [table], in respect of optional [filters] list and [limit].
   * Returns a [Future] containing a list of [Map] with the required values. Reading by primary key value should
   * use this method with [limit] = 1, and take the first item.
   */
  Future<List<Map>> read(String table, List<String> columns, [List<Filter> filters, int limit]) {
    var cols = columns.map((c) => '`${c}`');

    var script = 'SELECT ${cols.join(', ')} FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

    if (limit != null) {
      script += '\nLIMIT ${limit}';
    }

    script += ';';

    return this.pool.query(script).then((results) {
      return results.toList().then((rows) {
        return rows.map((r) => _constructMapFromDatabase(r, results.fields)).toList();
      });
    });
  }

  /**
   * Updates a table row in the database.
   *
   * Updates a table row with the specified [data]. The [columns] list has the normal columns only, and
   * excludes the primary key column. Returns a [Future] containing the primary key value of the new table row. The
   * primary key is expected to be existant in the table.
   */
  Future<Object> update(String table, String pkColumn, List<String> columns, Map data) {
    columns = new List.from(columns);
    columns.insert(0, pkColumn);

    var cols = columns.map((c) => '`${c}`'),
        values = columns.map((c) =>  _objToString(data[c]));

    var script = 'INSERT INTO `${table}` (${cols.join(', ')})';
    script += '\nVALUES (${values.join(', ')})';
    script += '\nON DUPLICATE KEY UPDATE';
    script += '\n${cols.map((c) => '${c} = VALUES(${c})').join(', ')};';

    return this.pool.query(script).then((result) {
      return new Future.value(result.insertId);
    });
  }

  /**
   * Deletes a table row from the database.
   *
   * Deletes the table rows matching the [filters] list. If [filters] is null or empty, this will delete all table
   * rows from the specified [table].
   */
  Future delete(String table, [List<Filter> filters]) {
    var script = 'DELETE FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

    return this.pool.query(script).then((result) {
      return new Future.value(null);
    });
  }

  // Converts a list of SQLJocky [Field] to a [Map].
  Map _constructMapFromDatabase(Row input, List<Field> fields) {
    var output = new Map<String, Object>();

    InstanceMirror instanceMirror = reflect(input);
    fields.forEach((field) {
      output[field.name] = instanceMirror.getField(new Symbol(field.name)).reflectee;
    });

    return output;
  }

  // Converts the [value] to a string representation understood by MySQL.
  static String _objToString(Object value) {
    if (value is String) {
      return '\'${value}\'';
    }

    if (value == null) {
      return 'NULL';
    }

    return value.toString();
  }

  // Converts the list of [Filter] to a string representation understood by MySQL.
  static String _constructFilter(List<Filter> filters) {
    return filters.map((f) => '`${f.name}` = ${_objToString(f.value)}').join(' AND ');
  }

}
